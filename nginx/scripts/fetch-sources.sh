#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

require_command curl
require_command git
require_command tar

WORKDIR="${1:?usage: fetch-sources.sh <workdir> <nginx_version>}"
NGINX_VERSION="${2:?usage: fetch-sources.sh <workdir> <nginx_version>}"

src_root="${WORKDIR}/src"
mkdir -p "${src_root}"

nginx_archive="${src_root}/nginx-${NGINX_VERSION}.tar.gz"
nginx_source_dir="${src_root}/nginx-${NGINX_VERSION}"

if [[ ! -d "${nginx_source_dir}" ]]; then
  log "Downloading nginx ${NGINX_VERSION}"
  curl -fsSL "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz" -o "${nginx_archive}"
  tar -xzf "${nginx_archive}" -C "${src_root}"
fi

while read -r name type url ref; do
  [[ -z "${name}" || "${name}" == \#* ]] && continue
  [[ "${type}" == "git" ]] || fail "Unsupported source type: ${type}"

  dest="${src_root}/${name}"
  rm -rf "${dest}"

  if [[ "${ref}" == "HEAD" ]]; then
    log "Cloning ${name} from default branch"
    git clone --depth 1 "${url}" "${dest}"
  else
    log "Cloning ${name} at ${ref}"
    git clone --depth 1 --branch "${ref}" "${url}" "${dest}"
  fi

  if [[ "${name}" == "ngx_brotli" ]]; then
    git -C "${dest}" submodule update --init --recursive
  fi
done < "${SOURCES_LOCK}"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    printf 'nginx_source_dir=%s\n' "${nginx_source_dir}"
    printf 'source_root=%s\n' "${src_root}"
  } >> "${GITHUB_OUTPUT}"
fi
