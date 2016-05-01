# runnable base
FROM rpawel/ubuntu:trusty

RUN apt-get -q -y update \
 && apt-get dist-upgrade -y --no-install-recommends \
# Nginx + Google Pagespeed
 && DEBIAN_FRONTEND=noninteractive apt-get install -y -q make build-essential g++ \
 && wget -q http://nginx.org/keys/nginx_signing.key -O- | apt-key add - \
 && add-apt-repository -y "deb http://nginx.org/packages/ubuntu/ $(lsb_release -sc) nginx" \
 && NPS_VERSION=1.9.32.4 \
 && mkdir -p /usr/src/nginx && cd /usr/src/nginx && wget -q https://github.com/pagespeed/ngx_pagespeed/archive/v${NPS_VERSION}-beta.zip \
 && unzip v${NPS_VERSION}-beta.zip && cd /usr/src/nginx/ngx_pagespeed-${NPS_VERSION}-beta/ \
 && /bin/bash scripts/pagespeed_libraries_generator.sh > /usr/src/nginx/pagespeed_libraries.conf \
 && wget -q https://dl.google.com/dl/page-speed/psol/${NPS_VERSION}.tar.gz && tar -xzf ${NPS_VERSION}.tar.gz \
 && DEBIAN_FRONTEND=noninteractive apt-get -y update \
 && apt-get build-dep -y -q nginx \
 && apt-get install -y -q nginx \
 && apt-mark hold nginx \
 && cd /usr/src/nginx; apt-get source -q -y nginx \
 && cd /usr/src/nginx/nginx-*/ \
 && ./configure \
 --add-module=/usr/src/nginx/ngx_pagespeed-${NPS_VERSION}-beta \
 --prefix=/etc/nginx \
 --sbin-path=/usr/sbin/nginx \
 --conf-path=/etc/nginx/nginx.conf \
 --error-log-path=/var/log/nginx/error.log \
 --http-log-path=/var/log/nginx/access.log \
 --pid-path=/var/run/nginx.pid \
 --lock-path=/var/run/nginx.lock \
 --http-client-body-temp-path=/var/cache/nginx/client_temp \
 --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
 --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
 --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
 --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
 --user=nginx \
 --group=nginx \
 --with-http_ssl_module \
 --with-http_realip_module \
 --with-http_addition_module \
 --with-http_sub_module \
 --with-http_dav_module \
 --with-http_flv_module \
 --with-http_mp4_module \
 --with-http_gunzip_module \
 --with-http_gzip_static_module \
 --with-http_random_index_module \
 --with-http_secure_link_module \
 --with-http_stub_status_module \
 --with-mail \
 --with-mail_ssl_module \
 --with-file-aio \
 --with-http_spdy_module \
 --with-cc-opt='-g -O2 -fstack-protector --param=ssp-buffer-size=4 -Wformat -Wformat-security -Wp,-D_FORTIFY_SOURCE=2' \
 --with-ld-opt='-Wl,-Bsymbolic-functions -Wl,-z,relro -Wl,--as-needed' \
 --with-ipv6 \
 && make && make install \
 && mkdir -p /var/ngx_pagespeed_cache && chown -R www-data:www-data /var/ngx_pagespeed_cache \
 && mv /usr/src/nginx/pagespeed_libraries.conf /etc/nginx/pagespeed_libraries.conf \
 && rm -rf /usr/src/nginx \
# Install
 && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
 php5-fpm php5 php5-cli php5-dev php-pear php5-common php5-apcu \
 php5-mcrypt php5-gd php5-mysql php5-curl php5-json php5-intl php5-xsl \
 php5-memcached php5-memcache \
 imagemagick graphicsmagick graphicsmagick-libmagick-dev-compat php5-imagick trimage \
 exim4 git subversion \
 && rm -rf /etc/php5/fpm/pool.d/*

# Config
ADD ./config /etc/
RUN update-exim4.conf \
 && useradd -d /var/www/app --no-create-home --shell /bin/bash -g www-data -G adm user \
 && mkdir -p /var/log/app; chmod 775 /var/log/app/; chown user:www-data /var/log/app/ \
 && mkdir -p /var/log/php5; chmod 775 /var/log/php5; chown www-data:www-data /var/log/php5/ \
 && mkdir -p /var/log/supervisor \
 && DEBIAN_FRONTEND=newt

ADD build.sh /
ADD run.sh /

RUN chmod +x /build.sh /run.sh \
 && bash /build.sh && rm -f /build.sh

# PORTS
EXPOSE 80

ENTRYPOINT ["/run.sh"]
