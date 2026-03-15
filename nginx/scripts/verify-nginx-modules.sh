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

shopt -s nullglob
module_files=("${MODULES_DIR}"/*.so)
shopt -u nullglob

(( ${#module_files[@]} > 0 )) || fail "No module files found in ${MODULES_DIR}"

for module_path in "${module_files[@]}"; do
  log "Verifying $(basename "${module_path}")"

  if readelf -d "${module_path}" | grep -Eq 'NEEDED.*libluajit-5\.1\.so\.2'; then
    readelf -d "${module_path}" | grep -Eq '(RPATH|RUNPATH).*/opt/luajit2/lib' \
      || fail "$(basename "${module_path}") is missing RPATH/RUNPATH for /opt/luajit2/lib"

    ldd "${module_path}" | grep -F "libluajit-5.1.so.2 => ${EXPECTED_LUAJIT_LIB}" >/dev/null \
      || fail "$(basename "${module_path}") does not resolve libluajit-5.1.so.2 from ${EXPECTED_LUAJIT_LIB}"
  fi
done
