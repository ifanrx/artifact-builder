#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

WORKDIR="${1:?usage: verify-nginx-package.sh <workdir> <nginx_version> <distro> <output_dir>}"
NGINX_VERSION="${2:?usage: verify-nginx-package.sh <workdir> <nginx_version> <distro> <output_dir>}"
DISTRO="${3:?usage: verify-nginx-package.sh <workdir> <nginx_version> <distro> <output_dir>}"
OUTPUT_DIR="${4:?usage: verify-nginx-package.sh <workdir> <nginx_version> <distro> <output_dir>}"

require_command curl
require_command dpkg-deb
require_command python3

[[ "${NGINX_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || fail "Invalid nginx version"
architecture="$(dpkg --print-architecture)"
package_version="${NGINX_PACKAGE_VERSION:-${NGINX_VERSION}-1~${DISTRO}}"
package_dir="${WORKDIR}/official-nginx"
package_url="https://nginx.org/packages"
minor_version="${NGINX_VERSION#*.}"
minor_version="${minor_version%%.*}"
if (( minor_version % 2 )); then
  package_url+="/mainline"
fi
package_url+="/ubuntu/pool/nginx/n/nginx/nginx_${package_version}_${architecture}.deb"

mkdir -p "${package_dir}" "${OUTPUT_DIR}"
log "Downloading official nginx.org package ${package_version} (${architecture})"
curl --retry 3 -fsSL "${package_url}" -o "${package_dir}/nginx.deb"
dpkg-deb -x "${package_dir}/nginx.deb" "${package_dir}/root"
official_nginx="${package_dir}/root/usr/sbin/nginx"
nginx_dir="${WORKDIR}/src/nginx-${NGINX_VERSION}"

make -C "${nginx_dir}" -j"$(nproc)"
"${official_nginx}" -V > "${OUTPUT_DIR}/official-nginx-build.txt" 2>&1
"${nginx_dir}/objs/nginx" -V > "${OUTPUT_DIR}/module-nginx-build.txt" 2>&1
python3 "${REPO_ROOT}/tests/compare-configure.py" \
  "${OUTPUT_DIR}/official-nginx-build.txt" "${OUTPUT_DIR}/module-nginx-build.txt"

log "Testing modules with the official nginx.org executable"
bash "${REPO_ROOT}/tests/verify-runtime.sh" "${official_nginx}" "${OUTPUT_DIR}/modules"
