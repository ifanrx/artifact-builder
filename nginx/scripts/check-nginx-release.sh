#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

TRACKED_VERSION_FILE="${REPO_ROOT}/versions/nginx-version.txt"
DOWNLOAD_INDEX_URL="${NGINX_DOWNLOAD_INDEX_URL:-https://nginx.org/download/}"

require_command curl
require_command grep
require_command sed
require_command sort
require_command tail

if [[ ! -f "${TRACKED_VERSION_FILE}" ]]; then
  fail "Tracked version file not found: ${TRACKED_VERSION_FILE}"
fi

tracked_version="$(tr -d '[:space:]' < "${TRACKED_VERSION_FILE}")"
override_version="${NGINX_VERSION_OVERRIDE:-}"

if [[ -n "${override_version}" ]]; then
  latest_version="${override_version}"
else
  latest_version="$(
    curl -fsSL "${DOWNLOAD_INDEX_URL}" \
      | grep -oE 'nginx-[0-9]+\.[0-9]+\.[0-9]+\.tar\.gz' \
      | sed -E 's/^nginx-|\.tar\.gz$//g' \
      | sort -V \
      | tail -n1
  )"
fi

[[ -n "${latest_version}" ]] || fail "Failed to resolve latest nginx version"

should_build="false"
if [[ "${latest_version}" != "${tracked_version}" ]]; then
  should_build="true"
fi

log "Tracked nginx version: ${tracked_version}"
log "Latest nginx version: ${latest_version}"
log "Build required: ${should_build}"

if [[ -n "${GITHUB_OUTPUT:-}" ]]; then
  {
    printf 'tracked_version=%s\n' "${tracked_version}"
    printf 'nginx_version=%s\n' "${latest_version}"
    printf 'should_build=%s\n' "${should_build}"
  } >> "${GITHUB_OUTPUT}"
else
  printf 'tracked_version=%s\n' "${tracked_version}"
  printf 'nginx_version=%s\n' "${latest_version}"
  printf 'should_build=%s\n' "${should_build}"
fi
