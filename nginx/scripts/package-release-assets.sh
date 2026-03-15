#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

ARTIFACT_ROOT="${1:?usage: package-release-assets.sh <artifact_root> <output_dir>}"
OUTPUT_DIR="${2:?usage: package-release-assets.sh <artifact_root> <output_dir>}"

mkdir -p "${OUTPUT_DIR}"

shopt -s nullglob
artifact_dirs=("${ARTIFACT_ROOT}"/nginx-build-*)
shopt -u nullglob

(( ${#artifact_dirs[@]} > 0 )) || fail "No nginx-build-* artifact directories found in ${ARTIFACT_ROOT}"

for artifact_dir in "${artifact_dirs[@]}"; do
  distro="$(basename "${artifact_dir}")"
  distro="${distro#nginx-build-}"
  modules_dir="${artifact_dir}/modules"
  manifest_path="${artifact_dir}/build-manifest.env"
  luajit_archive="${artifact_dir}/luajit2-${distro}.tar.xz"
  modules_archive="${OUTPUT_DIR}/nginx-modules-${distro}.tar.xz"

  [[ -d "${modules_dir}" ]] || fail "Missing modules directory: ${modules_dir}"
  [[ -f "${manifest_path}" ]] || fail "Missing manifest: ${manifest_path}"
  [[ -f "${luajit_archive}" ]] || fail "Missing LuaJIT archive: ${luajit_archive}"

  log "Packing nginx modules for ${distro}"
  tar -C "${modules_dir}" -cJf "${modules_archive}" .

  cp "${luajit_archive}" "${OUTPUT_DIR}/"
  cp "${manifest_path}" "${OUTPUT_DIR}/build-manifest-${distro}.env"
done
