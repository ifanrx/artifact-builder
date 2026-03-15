#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

WORKDIR="${1:?usage: write-build-manifest.sh <workdir> <nginx_version> <distro> <output_file>}"
NGINX_VERSION="${2:?usage: write-build-manifest.sh <workdir> <nginx_version> <distro> <output_file>}"
DISTRO="${3:?usage: write-build-manifest.sh <workdir> <nginx_version> <distro> <output_file>}"
OUTPUT_FILE="${4:?usage: write-build-manifest.sh <workdir> <nginx_version> <distro> <output_file>}"

src_root="${WORKDIR}/src"
mkdir -p "$(dirname "${OUTPUT_FILE}")"

{
  printf 'BUILD_TIMESTAMP=%s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  printf 'DISTRO=%s\n' "${DISTRO}"
  printf 'NGINX_VERSION=%s\n' "${NGINX_VERSION}"
  printf 'NGINX_SOURCE_URL=%s\n' "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"

  while read -r name type url ref; do
    [[ -z "${name}" || "${name}" == \#* ]] && continue
    var_prefix="$(sanitize_name "${name}")"
    repo_dir="${src_root}/${name}"

    printf '%s_URL=%s\n' "${var_prefix}" "${url}"
    printf '%s_REF=%s\n' "${var_prefix}" "${ref}"
    if [[ -d "${repo_dir}/.git" ]]; then
      printf '%s_SHA=%s\n' "${var_prefix}" "$(resolved_ref "${repo_dir}")"
    fi
  done < "${SOURCES_LOCK}"
} > "${OUTPUT_FILE}"

log "Wrote build manifest to ${OUTPUT_FILE}"
