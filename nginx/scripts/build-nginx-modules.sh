#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

WORKDIR="${1:?usage: build-nginx-modules.sh <workdir> <nginx_version> <output_dir>}"
NGINX_VERSION="${2:?usage: build-nginx-modules.sh <workdir> <nginx_version> <output_dir>}"
OUTPUT_DIR="${3:?usage: build-nginx-modules.sh <workdir> <nginx_version> <output_dir>}"

nginx_dir="${WORKDIR}/src/nginx-${NGINX_VERSION}"
modules_output_dir="${OUTPUT_DIR}/modules"

[[ -d "${nginx_dir}" ]] || fail "nginx source directory not found: ${nginx_dir}"

mkdir -p "${modules_output_dir}"

log "Configuring nginx modules in ${nginx_dir}"
(
  cd "${nginx_dir}"
  bash "${REPO_ROOT}/build-nginx.sh"
  make -j"$(nproc)" modules
)

module_count=0
shopt -s nullglob
for module_file in "${nginx_dir}"/objs/*.so; do
  cp "${module_file}" "${modules_output_dir}/"
  module_count=$((module_count + 1))
done
shopt -u nullglob

(( module_count > 0 )) || fail "No nginx module .so files were produced"

log "Collected ${module_count} nginx module(s)"
