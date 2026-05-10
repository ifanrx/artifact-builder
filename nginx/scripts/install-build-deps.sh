#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

sudo_cmd=()
if [[ "${EUID}" -ne 0 ]]; then
  require_command sudo
  sudo_cmd=(sudo)
fi

export DEBIAN_FRONTEND=noninteractive

log "Installing build dependencies"
"${sudo_cmd[@]}" apt-get update

pcre_dev_package="libpcre3-dev"
pcre_dev_candidate="$(apt-cache policy "${pcre_dev_package}" | awk '/Candidate:/ { print $2; exit }')"
install_pcre_from_source="false"

dependencies=(
  build-essential \
  ca-certificates \
  cmake \
  curl \
  git \
  libbrotli-dev \
  libssl-dev \
  perl \
  pkg-config \
  xz-utils \
  zlib1g-dev
)

if [[ -z "${pcre_dev_candidate}" || "${pcre_dev_candidate}" == "(none)" ]]; then
  install_pcre_from_source="true"
else
  dependencies+=("${pcre_dev_package}")
fi

"${sudo_cmd[@]}" apt-get install -y "${dependencies[@]}"

if [[ "${install_pcre_from_source}" == "true" ]]; then
  pcre_version="${PCRE_VERSION:-8.45}"
  pcre_prefix="${PCRE_PREFIX:-/opt/pcre1}"
  pcre_url="https://sourceforge.net/projects/pcre/files/pcre/${pcre_version}/pcre-${pcre_version}.tar.gz/download"
  pcre_workdir="$(mktemp -d)"

  log "Building PCRE ${pcre_version} from source into ${pcre_prefix}"
  curl -fsSL "${pcre_url}" -o "${pcre_workdir}/pcre.tar.gz"
  tar -xzf "${pcre_workdir}/pcre.tar.gz" -C "${pcre_workdir}"
  (
    cd "${pcre_workdir}/pcre-${pcre_version}"
    ./configure --prefix="${pcre_prefix}" --enable-utf --enable-unicode-properties
    make -j"$(nproc)"
    "${sudo_cmd[@]}" make install
  )
  rm -rf "${pcre_workdir}"
fi
