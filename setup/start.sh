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

ln -s /dev/stdout /var/log/unit.log
ln -s /dev/stdout /var/log/unit/access.log

if [ "$1" = "unitd" ] || [ "$1" = "unitd-debug" ]; then
    if /usr/bin/find "/var/lib/unit/" -mindepth 1 -print -quit 2>/dev/null | /bin/grep -q .; then
        echo "$0: /var/lib/unit/ is not empty, skipping initial configuration..."
    else
        echo "$0: Launching Unit daemon to perform initial configuration..."
        /usr/sbin/$1 --control unix:/var/run/control.unit.sock

        for i in $(/usr/bin/seq $WAITLOOPS); do
            if [ ! -S /var/run/control.unit.sock ]; then
                echo "$0: Waiting for control socket to be created..."
                /bin/sleep $SLEEPSEC
            else
                break
            fi
        done
        # even when the control socket exists, it does not mean unit has finished initialisation
        # this curl call will get a reply once unit is fully launched
        /usr/bin/curl -s -X GET --unix-socket /var/run/control.unit.sock http://localhost/

        curl -X PUT --data-binary @/config/unit.json --unix-socket \
         /var/run/control.unit.sock http://localhost/config/

        echo "$0: Stopping Unit daemon after initial configuration..."
        kill -TERM $(/bin/cat /var/run/unit.pid)

        for i in $(/usr/bin/seq $WAITLOOPS); do
            if [ -S /var/run/control.unit.sock ]; then
                echo "$0: Waiting for control socket to be removed..."
                /bin/sleep $SLEEPSEC
            else
                break
            fi
        done
        if [ -S /var/run/control.unit.sock ]; then
            kill -KILL $(/bin/cat /var/run/unit.pid)
            rm -f /var/run/control.unit.sock
        fi

        echo
        echo "$0: Unit initial configuration complete; ready for start up..."
        echo
    fi
fi

exec "$@"
