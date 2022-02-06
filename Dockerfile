FROM rpawel/ubuntu:focal

RUN apt -q -y update \
 && add-apt-repository ppa:ondrej/php -y \
 && apt -q -y update \
 && apt dist-upgrade -y --no-install-recommends \
 && DEBIAN_FRONTEND=noninteractive apt install -y -q --no-install-recommends \
 nginx php8.1-fpm php8.1 php8.1-cli php8.1-dev php8.1-common php8.1-apcu \
 php8.1-gd php8.1-mysql php8.1-pgsql php8.1-curl php8.1-intl php8.1-xsl php8.1-ssh2 php8.1-mbstring \
 php8.1-zip php8.1-memcached php8.1-memcache php8.1-redis php8.1-xdebug php8.1-imap php8.1-bcmath php8.1-mcrypt \
 imagemagick graphicsmagick graphicsmagick-libmagick-dev-compat php8.1-imagick trimage \
 libmcrypt-dev libmcrypt4 \
 exim4 locales \
 && phpdismod xdebug \
 && rm -rf /etc/php/*/fpm/pool.d/* /etc/nginx/conf.d/default.conf

# Config
ADD ./config /etc/
RUN useradd -d /var/www/app --no-create-home --shell /bin/bash -g www-data -G adm user \
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
