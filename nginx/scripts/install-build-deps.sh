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
if [[ -z "${pcre_dev_candidate}" || "${pcre_dev_candidate}" == "(none)" ]]; then
  log "Adding Ubuntu noble package source for libpcre3-dev compatibility"
  printf '%s\n' 'deb http://archive.ubuntu.com/ubuntu noble main' \
    | "${sudo_cmd[@]}" tee /etc/apt/sources.list.d/noble-pcre.list >/dev/null
  {
    printf 'Package: *\n'
    printf 'Pin: release n=noble\n'
    printf 'Pin-Priority: 100\n'
    printf '\n'
    printf 'Package: libpcre3 libpcre3-dev\n'
    printf 'Pin: release n=noble\n'
    printf 'Pin-Priority: 990\n'
  } | "${sudo_cmd[@]}" tee /etc/apt/preferences.d/noble-pcre >/dev/null
  "${sudo_cmd[@]}" apt-get update
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
