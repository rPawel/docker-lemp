#!/bin/bash
iniSet() {
    file=$1
    var=$2
    val=$3
    if [ -n "${val}" ]; then
        echo "Setting $var to $val in $file"
        sed -i "s/^\($var\s*=\s*\).*$/\1$val/" $file
    fi
}

PERSISTENT_CONFIG_FOLDER="/root/.persistent-config"
PERSISTENT_IGNORED_CONFIG_FOLDER=$PERSISTENT_CONFIG_FOLDER/.ignore
VOLATILE_CONFIG_FOLDER="/"

if [ ! -d /var/www/app ]; then
    mkdir -p /var/www/app/public
    chown -R user:www-data /var/www/app
fi
if [ ! -d /var/www/cron ]; then
    mkdir -p /var/www/cron
    chown -R user:www-data /var/www/cron
    chmod 750 /var/www/cron
fi
rm -rf /home; ln -s /var/www/app /home
mkdir -p /var/log/php /var/log/nginx
chmod 775 /var/log/php /var/log/nginx
find /var/log/php /var/log/nginx -type f -exec chmod 644 {} \;
chown -R user:www-data /var/log/php /var/log/nginx

cp -ar ${PERSISTENT_CONFIG_FOLDER}/* ${VOLATILE_CONFIG_FOLDER}

iniSet /etc/php/7.0/mods-available/xdebug.ini "xdebug\.remote_host" $CTNR_HOST_IP
iniSet /etc/php/7.0/mods-available/xdebug.ini "xdebug\.remote_port" $CTNR_HOST_XDEBUG_PORT

if [ "$CTNR_APP_ENV" = "dev" ]; then
    echo "== CONTAINER IS STARTING IN DEV MODE =="
    phpenmod xdebug
    iniSet /etc/php/7.0/fpm/php.ini display_errors On
    iniSet /etc/php/7.0/fpm/php.ini display_startup_errors On
    iniSet /etc/php/7.0/cli/php.ini display_errors On
    iniSet /etc/php/7.0/cli/php.ini display_startup_errors On
else
    echo "== CONTAINER IS STARTING IN PROD MODE =="
    phpdismod xdebug
    iniSet /etc/php/7.0/fpm/php.ini display_errors Off
    iniSet /etc/php/7.0/fpm/php.ini display_startup_errors Off
    iniSet /etc/php/7.0/cli/php.ini display_errors Off
    iniSet /etc/php/7.0/cli/php.ini display_startup_errors Off
fi

# start container
exec /usr/bin/supervisord -c /etc/supervisord.conf
