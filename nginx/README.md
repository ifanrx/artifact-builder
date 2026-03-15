# artifact-builder / nginx

GitHub Actions repo for building LuaJIT and nginx dynamic modules, then publishing the outputs as GitHub Release assets.

## Outputs

- release tag: `nginx-v<version>`
- module archives: `nginx-modules-jammy.tar.xz`, `nginx-modules-noble.tar.xz`
- LuaJIT tarballs: `luajit2-jammy.tar.xz`, `luajit2-noble.tar.xz`
- manifests: `build-manifest-jammy.env`, `build-manifest-noble.env`

Each build also emits a manifest with the resolved dependency SHAs used for that run.

The workflow also verifies that any module linked against LuaJIT resolves `libluajit-5.1.so.2` from `/opt/luajit2/lib` and retains an `RPATH` or `RUNPATH` for that path.

## Source Of Truth

- [`build-luajit.sh`](./build-luajit.sh) installs LuaJIT into `/opt/luajit2`.
- [`build-nginx.sh`](./build-nginx.sh) configures nginx to build the dynamic modules against that LuaJIT prefix.
- [`sources.lock`](./sources.lock) pins upstream source repos and refs.
- [`versions/nginx-version.txt`](./versions/nginx-version.txt) records the last successfully published nginx version.

## Required GitHub Configuration

No external storage secrets are required for publishing. The workflow publishes to GitHub Releases using the repository `GITHUB_TOKEN`.

## Workflow

[`nginx-build-and-publish.yml`](../.github/workflows/nginx-build-and-publish.yml) supports:

- scheduled nginx release detection,
- manual rebuilds via `workflow_dispatch`,
- per-distro builds for Ubuntu 22.04 (`jammy`) and 24.04 (`noble`),
- GitHub Release publishing,
- automatic pull requests that update `nginx/versions/nginx-version.txt` after a successful scheduled publish.
