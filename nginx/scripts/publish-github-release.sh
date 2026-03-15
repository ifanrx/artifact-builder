#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

ASSET_DIR="${1:?usage: publish-github-release.sh <asset_dir> <nginx_version>}"
NGINX_VERSION="${2:?usage: publish-github-release.sh <asset_dir> <nginx_version>}"
RELEASE_TAG="nginx-v${NGINX_VERSION}"
RELEASE_TITLE="nginx ${NGINX_VERSION}"

require_command gh

shopt -s nullglob
assets=("${ASSET_DIR}"/*)
shopt -u nullglob

(( ${#assets[@]} > 0 )) || fail "No release assets found in ${ASSET_DIR}"

if ! gh release view "${RELEASE_TAG}" >/dev/null 2>&1; then
  log "Creating release ${RELEASE_TAG}"
  gh release create "${RELEASE_TAG}" \
    --title "${RELEASE_TITLE}" \
    --notes "Automated build artifacts for nginx ${NGINX_VERSION}."
fi

log "Uploading release assets for ${RELEASE_TAG}"
gh release upload "${RELEASE_TAG}" "${assets[@]}" --clobber
