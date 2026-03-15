# artifact-builder / nginx

GitHub Actions repo for building LuaJIT and nginx dynamic modules, then publishing the outputs to private S3-compatible object storage.

## Outputs

- nginx module `.so` files: `s3://<prefix>/nginx/<version>/<jammy|noble>/`
- LuaJIT tarballs: `s3://<prefix>/luajit/<version>/<jammy|noble>/luajit2-<jammy|noble>.tar.xz`

Each build also emits a manifest with the resolved dependency SHAs used for that run.

## Source Of Truth

- [`build-luajit.sh`](./build-luajit.sh) installs LuaJIT into `/opt/luajit2`.
- [`build-nginx.sh`](./build-nginx.sh) configures nginx to build the dynamic modules against that LuaJIT prefix.
- [`sources.lock`](./sources.lock) pins upstream source repos and refs.
- [`versions/nginx-version.txt`](./versions/nginx-version.txt) records the last successfully published nginx version.

## Required GitHub Configuration

Repository variables:

- `S3_ENDPOINT_URL`
- `S3_REGION`
- `S3_ADDRESSING_STYLE` optional, for example `path`
- `S3_PREFIX`

Repository secrets:

- `S3_ACCESS_KEY_ID`
- `S3_SECRET_ACCESS_KEY`

`S3_PREFIX` must be a full `s3://...` URI prefix such as `s3://private-bucket/releases`.

The workflow uses the AWS CLI against your custom S3-compatible endpoint and does not assume AWS IAM, ARNs, or GitHub OIDC.

## Workflow

[`nginx-build-and-publish.yml`](../.github/workflows/nginx-build-and-publish.yml) supports:

- scheduled nginx release detection,
- manual rebuilds via `workflow_dispatch`,
- per-distro builds for Ubuntu 22.04 (`jammy`) and 24.04 (`noble`),
- S3 publishing,
- automatic pull requests that update `nginx/versions/nginx-version.txt` after a successful scheduled publish.
