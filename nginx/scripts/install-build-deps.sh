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
if ! apt-cache show "${pcre_dev_package}" >/dev/null 2>&1; then
  pcre_dev_package="libpcre2-dev"
fi

"${sudo_cmd[@]}" apt-get install -y \
  build-essential \
  ca-certificates \
  cmake \
  curl \
  git \
  libbrotli-dev \
  "${pcre_dev_package}" \
  libssl-dev \
  perl \
  pkg-config \
  xz-utils \
  zlib1g-dev
