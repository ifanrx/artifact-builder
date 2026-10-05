#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

LUAJIT_PREFIX="${1:-/opt/luajit2}"

[[ -x "${LUAJIT_PREFIX}/bin/luajit" ]] || fail "LuaJIT executable is missing"
[[ -f "${LUAJIT_PREFIX}/lib/libluajit-5.1.so.2" ]] || fail "LuaJIT shared library is missing"

"${LUAJIT_PREFIX}/bin/luajit" - "${LUAJIT_PREFIX}" <<'LUA'
local prefix = assert(arg[1])
local ffi = require "ffi"
local util = require "jit.util"
assert(jit.status(), "LuaJIT JIT compiler is disabled")
ffi.cdef "int abs(int);"
assert(ffi.C.abs(-42) == 42, "LuaJIT FFI call failed")
jit.flush()
jit.opt.start("hotloop=1")
local sum = 0
for i = 1, 10000 do sum = sum + i end
assert(sum == 50005000)
assert(util.traceinfo(1), "LuaJIT did not compile a trace")
assert(loadfile(prefix .. "/share/lua/5.1/resty/core.lua"))
assert(loadfile(prefix .. "/share/lua/5.1/resty/lrucache.lua"))
print(jit.version .. ": JIT execution, FFI and runtime files verified")
LUA
