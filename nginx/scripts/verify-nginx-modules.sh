#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

MODULES_DIR="${1:?usage: verify-nginx-modules.sh <modules_dir>}"
EXPECTED_LUAJIT_LIB="/opt/luajit2/lib/libluajit-5.1.so.2"

require_command ldd
require_command readelf

[[ -d "${MODULES_DIR}" ]] || fail "Modules directory not found: ${MODULES_DIR}"
[[ -f "${MODULES_DIR}/ngx_http_lua_module.so" ]] || fail "Lua nginx module is missing"

shopt -s nullglob
module_files=("${MODULES_DIR}"/*.so)
shopt -u nullglob

(( ${#module_files[@]} > 0 )) || fail "No module files found in ${MODULES_DIR}"

for module_path in "${module_files[@]}"; do
  log "Verifying $(basename "${module_path}")"

  dynamic_info="$(readelf -d "${module_path}")"
  linkage="$(ldd "${module_path}")"
  if grep -Fq 'not found' <<< "${linkage}"; then
    fail "$(basename "${module_path}") has unresolved shared libraries: ${linkage}"
  fi
  if grep -Eq 'libpcre\.so|/opt/pcre' <<< "${dynamic_info}${linkage}"; then
    fail "$(basename "${module_path}") depends on PCRE1 or a private PCRE installation"
  fi
  while read -r pcre_library; do
    [[ -n "${pcre_library}" ]] || continue
    case "${pcre_library}" in
      /lib/*|/usr/lib/*) ;;
      *) fail "$(basename "${module_path}") resolves PCRE2 outside system libraries: ${pcre_library}" ;;
    esac
  done < <(awk '$1 ~ /^libpcre2-/ { print $3 }' <<< "${linkage}")

  if [[ "$(basename "${module_path}")" == ngx_http_lua_module.so ]]; then
    grep -Eq 'NEEDED.*libluajit-5\.1\.so\.2' <<< "${dynamic_info}" \
      || fail "Lua nginx module is not linked to the LuaJIT shared library"
  fi

  if grep -Eq 'NEEDED.*libluajit-5\.1\.so\.2' <<< "${dynamic_info}"; then
    grep -Eq '(RPATH|RUNPATH).*/opt/luajit2/lib' <<< "${dynamic_info}" \
      || fail "$(basename "${module_path}") is missing RPATH/RUNPATH for /opt/luajit2/lib"

    grep -F "libluajit-5.1.so.2 => ${EXPECTED_LUAJIT_LIB}" <<< "${linkage}" >/dev/null \
      || fail "$(basename "${module_path}") does not resolve libluajit-5.1.so.2 from ${EXPECTED_LUAJIT_LIB}"
  fi
done
