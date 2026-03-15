#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

ARTIFACT_ROOT="${1:?usage: publish-s3.sh <artifact_root> <nginx_version> <s3_prefix>}"
NGINX_VERSION="${2:?usage: publish-s3.sh <artifact_root> <nginx_version> <s3_prefix>}"
S3_PREFIX="$(normalize_s3_prefix "${3:?usage: publish-s3.sh <artifact_root> <nginx_version> <s3_prefix>}")"
S3_ENDPOINT_URL="${S3_ENDPOINT_URL:?Missing required environment variable: S3_ENDPOINT_URL}"
S3_REGION="${S3_REGION:-us-east-1}"
S3_ADDRESSING_STYLE="${S3_ADDRESSING_STYLE:-}"

require_command aws

aws_base_args=(--endpoint-url "${S3_ENDPOINT_URL}" --region "${S3_REGION}")

if [[ -n "${S3_ADDRESSING_STYLE}" ]]; then
  aws configure set default.s3.addressing_style "${S3_ADDRESSING_STYLE}"
fi

upload_and_verify() {
  local local_path="$1"
  local s3_uri="$2"
  local bucket
  local key

  readarray -t s3_parts < <(parse_s3_uri "${s3_uri}")
  bucket="${s3_parts[0]}"
  key="${s3_parts[1]}"

  log "Uploading ${local_path} -> ${s3_uri}"
  aws "${aws_base_args[@]}" s3 cp "${local_path}" "${s3_uri}"
  aws "${aws_base_args[@]}" s3api head-object --bucket "${bucket}" --key "${key}" >/dev/null
}

shopt -s nullglob
artifact_dirs=("${ARTIFACT_ROOT}"/nginx-build-*)
shopt -u nullglob

(( ${#artifact_dirs[@]} > 0 )) || fail "No nginx-build-* artifact directories found in ${ARTIFACT_ROOT}"

for artifact_dir in "${artifact_dirs[@]}"; do
  distro="$(basename "${artifact_dir}")"
  distro="${distro#nginx-build-}"
  modules_dir="${artifact_dir}/modules"
  manifest_path="${artifact_dir}/build-manifest.env"
  luajit_archive="${artifact_dir}/luajit2-${distro}.tar.xz"

  [[ -d "${modules_dir}" ]] || fail "Missing modules directory: ${modules_dir}"
  [[ -f "${luajit_archive}" ]] || fail "Missing LuaJIT archive: ${luajit_archive}"
  [[ -f "${manifest_path}" ]] || fail "Missing manifest: ${manifest_path}"

  shopt -s nullglob
  module_files=("${modules_dir}"/*.so)
  shopt -u nullglob

  (( ${#module_files[@]} > 0 )) || fail "No module files found in ${modules_dir}"

  for module_path in "${module_files[@]}"; do
    upload_and_verify "${module_path}" "${S3_PREFIX}/nginx/${NGINX_VERSION}/${distro}/$(basename "${module_path}")"
  done

  upload_and_verify "${luajit_archive}" "${S3_PREFIX}/luajit/${NGINX_VERSION}/${distro}/$(basename "${luajit_archive}")"
  upload_and_verify "${manifest_path}" "${S3_PREFIX}/nginx/${NGINX_VERSION}/${distro}/build-manifest.env"
done
