#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

WORKDIR="${1:?usage: build-luajit-artifact.sh <workdir> <distro> <output_dir>}"
DISTRO="${2:?usage: build-luajit-artifact.sh <workdir> <distro> <output_dir>}"
OUTPUT_DIR="${3:?usage: build-luajit-artifact.sh <workdir> <distro> <output_dir>}"

luajit_dir="${WORKDIR}/src/luajit2"
archive_path="${OUTPUT_DIR}/luajit2-${DISTRO}.tar.xz"
sudo_cmd=()

if [[ "${EUID}" -ne 0 ]]; then
  require_command sudo
  sudo_cmd=(sudo)
fi

[[ -d "${luajit_dir}" ]] || fail "LuaJIT source directory not found: ${luajit_dir}"
for library in lua-resty-core lua-resty-lrucache; do
  [[ -d "${WORKDIR}/src/${library}" ]] || fail "Lua runtime library source directory not found: ${library}"
done

mkdir -p "${OUTPUT_DIR}"
"${sudo_cmd[@]}" rm -rf /opt/luajit2

log "Building LuaJIT in ${luajit_dir}"
(
  cd "${luajit_dir}"
  "${sudo_cmd[@]}" bash "${REPO_ROOT}/build-luajit.sh"
)

for library in lua-resty-core lua-resty-lrucache; do
  "${sudo_cmd[@]}" make -C "${WORKDIR}/src/${library}" install \
    LUA_LIB_DIR=/opt/luajit2/share/lua/5.1
done

bash "${SCRIPT_DIR}/verify-luajit.sh"

log "Packing ${archive_path}"
"${sudo_cmd[@]}" tar -C /opt -cJf - luajit2 > "${archive_path}"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  printf 'luajit_archive=%s\n' "${archive_path}" >> "${GITHUB_OUTPUT}"
fi
