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

[[ -d "${luajit_dir}" ]] || fail "LuaJIT source directory not found: ${luajit_dir}"

mkdir -p "${OUTPUT_DIR}"
sudo rm -rf /opt/luajit2

log "Building LuaJIT in ${luajit_dir}"
(
  cd "${luajit_dir}"
  sudo bash "${REPO_ROOT}/build-luajit.sh"
)

log "Packing ${archive_path}"
sudo tar -C /opt -cJf - luajit2 > "${archive_path}"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  printf 'luajit_archive=%s\n' "${archive_path}" >> "${GITHUB_OUTPUT}"
fi
