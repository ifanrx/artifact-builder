#!/usr/bin/env bash
set -euo pipefail

export LUAJIT_LIB=/opt/luajit2/lib
export LUAJIT_INC=/opt/luajit2/include/luajit-2.1

pkg-config --exists libpcre2-8 || {
  printf '%s\n' 'Missing system PCRE2 development package (libpcre2-dev)' >&2
  exit 1
}

package_features=()
# nginx deliberately exits with status 1 after printing help.
configure_help="$(./configure --help || [[ $? -eq 1 ]])"
for feature in --with-control-api --with-http_json_module; do
  if grep -Fq -- "${feature}" <<< "${configure_help}"; then
    package_features+=("${feature}")
  fi
done

./configure \
  --prefix=/etc/nginx \
  --sbin-path=/usr/sbin/nginx \
  --modules-path=/usr/lib/nginx/modules \
  --conf-path=/etc/nginx/nginx.conf \
  --error-log-path=/var/log/nginx/error.log \
  --http-log-path=/var/log/nginx/access.log \
  --pid-path=/run/nginx.pid \
  --lock-path=/run/nginx.lock \
  --http-client-body-temp-path=/var/cache/nginx/client_temp \
  --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
  --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
  --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
  --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
  --user=nginx \
  --group=nginx \
  --with-compat \
  --with-file-aio \
  --with-threads \
  --with-http_addition_module \
  --with-http_auth_request_module \
  --with-http_dav_module \
  --with-http_flv_module \
  --with-http_gunzip_module \
  --with-http_gzip_static_module \
  --with-http_mp4_module \
  --with-http_random_index_module \
  --with-http_realip_module \
  --with-http_secure_link_module \
  --with-http_slice_module \
  --with-http_ssl_module \
  --with-http_stub_status_module \
  --with-http_sub_module \
  --with-http_v2_module \
  --with-http_v3_module \
  --with-mail \
  --with-mail_ssl_module \
  --with-stream \
  --with-stream_realip_module \
  --with-stream_ssl_module \
  --with-stream_ssl_preread_module \
  "${package_features[@]}" \
  --with-cc-opt="-g -O2 -Werror=implicit-function-declaration -fno-omit-frame-pointer -mno-omit-leaf-frame-pointer -flto=auto -ffat-lto-objects -fstack-protector-strong -fstack-clash-protection -Wformat -Werror=format-security -fcf-protection -fPIC -Wno-discarded-qualifiers" \
  --with-ld-opt="-Wl,-Bsymbolic-functions -flto=auto -ffat-lto-objects -Wl,-z,relro -Wl,-z,now -Wl,--as-needed -pie -Wl,-rpath,/opt/luajit2/lib" \
  --add-dynamic-module=../headers-more-nginx-module \
  --add-dynamic-module=../lua-nginx-module \
  --add-dynamic-module=../ngx_devel_kit \
  --add-dynamic-module=../ngx_http_substitutions_filter_module \
  --add-dynamic-module=../ngx_brotli \
  --add-dynamic-module=../ngx-fancyindex \
  --add-dynamic-module=../nginx-acme
