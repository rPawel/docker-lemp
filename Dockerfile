FROM rpawel/ubuntu:xenial

RUN apt-get -q -y update \
 && apt-get dist-upgrade -y --no-install-recommends \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y -q \
 nginx php-fpm php php-cli php-dev php-pear php-common php-apcu \
 php-mcrypt php-gd php-mysql php-curl php-json php-intl php-xsl php-ssh2 php-mbstring \
 php-zip php-memcached php-memcache php-xdebug php-imap \
 imagemagick graphicsmagick graphicsmagick-libmagick-dev-compat php-imagick trimage \
 exim4 git subversion locales \
 && phpenmod mcrypt && phpenmod imap && phpdismod xdebug \
 && rm -rf /etc/php/7.0/fpm/pool.d/* /etc/nginx/conf.d/default.conf

# Config
ADD ./config /etc/
RUN update-exim4.conf \
 && useradd -d /var/www/app --no-create-home --shell /bin/bash -g www-data -G adm user \
 && mkdir -p /var/log/php; chmod 775 /var/log/php; chown www-data:www-data /var/log/php/ \
 && mkdir -p /var/log/supervisor \
 && DEBIAN_FRONTEND=newt

ADD build.sh /
ADD run.sh /

RUN chmod +x /build.sh /run.sh \
 && bash /build.sh && rm -f /build.sh

# PORTS
EXPOSE 80

HEALTHCHECK --interval=30s --timeout=10s CMD curl --fail http://localhost/ || exit 1

ENTRYPOINT ["/run.sh"]
