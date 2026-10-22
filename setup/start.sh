#!/bin/sh

if [ ! -f /etc/phpmyadmin/config.secret.inc.php ]; then
    cat > /etc/phpmyadmin/config.secret.inc.php <<EOT
<?php
\$cfg['blowfish_secret'] = '$(tr -dc 'a-zA-Z0-9~!@#$%^&*_()+}{?></";.,[]=-' < /dev/urandom | fold -w 32 | head -n 1)';
EOT
fi

if [ ! -f /etc/phpmyadmin/config.user.inc.php ]; then
    touch /etc/phpmyadmin/config.user.inc.php
fi

ln -s /dev/stdout /var/log/fpm-php.www.log
ln -s /dev/stdout /var/log/php-fpm.log
ln -s /dev/stdout /var/log/nginx/access.log
ln -s /dev/stdout /var/log/nginx/error.log

if [ "$TZ" != "" ]
then
  sed -i "s!Europe/London!$TZ!" /etc/php84/php.ini
fi

php-fpm84 --allow-to-run-as-root

exec "$@"
