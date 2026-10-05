#!/usr/bin/env bash
set -euo pipefail

NGINX="$(realpath "${1:?usage: verify-runtime.sh <nginx_binary> <modules_dir>}")"
MODULES_DIR="$(realpath "${2:?usage: verify-runtime.sh <nginx_binary> <modules_dir>}")"
test_dir="$(mktemp -d)"
nginx_pid=""

cleanup() {
  if [[ -n "${nginx_pid}" ]]; then
    kill "${nginx_pid}" 2>/dev/null || true
    wait "${nginx_pid}" 2>/dev/null || true
  fi
  rm -rf "${test_dir}"
}
trap cleanup EXIT

{
  # The Lua module requires NDK symbols when nginx loads its shared object.
  printf 'load_module "%s/ndk_http_module.so";\n' "${MODULES_DIR}"
  for module in "${MODULES_DIR}"/*.so; do
    [[ "${module##*/}" == ndk_http_module.so ]] && continue
    printf 'load_module "%s";\n' "${module}"
  done
  printf 'pid "%s/nginx.pid";\n' "${test_dir}"
  printf 'error_log "%s/error.log" notice;\n' "${test_dir}"
  printf 'user root;\ndaemon off;\nmaster_process off;\nevents {}\nhttp {\n'
  for kind in client_body proxy fastcgi uwsgi scgi; do
    printf '%s_temp_path "%s/%s_temp";\n' "${kind}" "${test_dir}" "${kind}"
  done
  printf 'access_log off;\nserver {\nlisten unix:%s/http.sock;\n' "${test_dir}"
  printf '%s\n' 'location ~ ^/native/([0-9]+)$ { return 200 "native:$1"; }'
  printf '%s\n' 'location /lua { content_by_lua_block {'
  printf 'local socket_path = "unix:%s/http.sock"\n' "${test_dir}"
  printf '%s\n' \
    'assert(package.loaded["resty.core"], "resty.core did not load")' \
    'assert(jit.status(), "LuaJIT JIT compiler is disabled")' \
    'local ffi = require "ffi"' \
    'ffi.cdef "int abs(int);"' \
    'assert(ffi.C.abs(-42) == 42)' \
    'local cache = assert(require("resty.lrucache").new(4))' \
    'cache:set("answer", 42); assert(cache:get("answer") == 42)' \
    'for i = 1, 3 do' \
    '  local m, err = ngx.re.match("Hello 42", [[^(?<word>hello)\s+(\d+)$]], "ijo")' \
    '  assert(m and m.word == "Hello" and m[2] == "42", err)' \
    'end' \
    'local replaced, count, err = ngx.re.gsub("one two", [[\w+]], "<$0>", "jo")' \
    'assert(replaced == "<one> <two>" and count == 2, err)' \
    'local unicode, unicode_err = ngx.re.match("你好", [[^\p{L}+$]], "ujo")' \
    'assert(unicode and unicode[0] == "你好", unicode_err)' \
    'local invalid, regex_err = ngx.re.match("x", "(")' \
    'assert(not invalid and regex_err, "invalid regex must return an error")' \
    'jit.flush(); jit.opt.start("hotloop=1")' \
    'local total = 0; for i = 1, 10000 do total = total + i end' \
    'assert(total == 50005000 and require("jit.util").traceinfo(1))' \
    'ngx.sleep(0.001)' \
    'local socket = ngx.socket.tcp(); socket:settimeout(2000)' \
    'assert(socket:connect(socket_path))' \
    'assert(socket:send("GET /native/456 HTTP/1.0\r\nHost: localhost\r\n\r\n"))' \
    'local response = assert(socket:receive("*a")); socket:close()' \
    'assert(response:find("200 OK", 1, true) and response:sub(-10) == "native:456")' \
    'ngx.say("LuaJIT, FFI, resty.core, LRU, PCRE2 and cosockets: OK")'
  printf '} }\n} }\n'
} > "${test_dir}/nginx.conf"

"${NGINX}" -e stderr -p "${test_dir}/" -c "${test_dir}/nginx.conf" -t
"${NGINX}" -e stderr -p "${test_dir}/" -c "${test_dir}/nginx.conf" &
nginx_pid=$!
for ((attempt = 0; attempt < 50; attempt++)); do
  [[ -S "${test_dir}/http.sock" ]] && break
  kill -0 "${nginx_pid}" 2>/dev/null || break
  sleep 0.1
done

if ! native_response="$(curl --silent --show-error --fail --max-time 10 --unix-socket "${test_dir}/http.sock" http://localhost/native/123)" \
  || [[ "${native_response}" != native:123 ]]; then
  sed -n '1,100p' "${test_dir}/error.log" >&2
  exit 1
fi
if ! lua_response="$(curl --silent --show-error --fail --max-time 10 --unix-socket "${test_dir}/http.sock" http://localhost/lua)" \
  || [[ "${lua_response}" != 'LuaJIT, FFI, resty.core, LRU, PCRE2 and cosockets: OK' ]]; then
  sed -n '1,100p' "${test_dir}/error.log" >&2
  exit 1
fi
printf '%s\n' "${native_response}" "${lua_response}"
