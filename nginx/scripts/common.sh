#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SOURCES_LOCK="${REPO_ROOT}/sources.lock"

log() {
  printf '[%s] %s\n' "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$*"
}

fail() {
  log "ERROR: $*"
  exit 1
}

require_command() {
  local command_name="$1"
  command -v "${command_name}" >/dev/null 2>&1 || fail "Missing required command: ${command_name}"
}

require_env() {
  local name="$1"
  [[ -n "${!name:-}" ]] || fail "Missing required environment variable: ${name}"
}

normalize_s3_prefix() {
  local value="$1"
  value="${value%/}"
  printf '%s\n' "${value}"
}

parse_s3_uri() {
  local uri="$1"
  local without_scheme="${uri#s3://}"
  local bucket="${without_scheme%%/*}"
  local key=""

  if [[ "${without_scheme}" == */* ]]; then
    key="${without_scheme#*/}"
  fi

  printf '%s\n%s\n' "${bucket}" "${key}"
}

resolved_ref() {
  local repo_dir="$1"
  git -C "${repo_dir}" rev-parse HEAD
}

sanitize_name() {
  local value="$1"
  printf '%s\n' "${value}" | tr '[:lower:]-/' '[:upper:]__'
}
