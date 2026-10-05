# nginx artifacts

Builds LuaJIT and nginx dynamic modules for Ubuntu 22.04 (Jammy), 24.04 (Noble), and 26.04 (Resolute), published as GitHub Release assets.

Modules include Lua, NDK, Brotli, headers-more, substitutions, fancyindex, and ACME.

Releases use `nginx-v<version>` tags and contain:

- `nginx-modules-<distro>.tar.xz`
- `luajit2-<distro>.tar.xz`
- `build-manifest-<distro>.env`
