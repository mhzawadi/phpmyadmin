FROM alpine:3.21.0
LABEL org.opencontainers.image.authors="matt@horwood.biz"

# Install required deb packages
RUN apk update && \
    apk add gnupg unit-php82 php82-common php82-iconv php82-json php82-gd \
    php82-curl php82-xml php82-mysqli php82-imap php82-pdo php82-pdo_mysql \
    php82-soap php82-posix php82-gettext php82-ldap \
    php82-ctype php82-dom php82-session php82-mbstring curl \
    && mkdir -p /var/www/html/ \
    && mkdir -p /run/nginx \
    && rm -f /var/cache/apk/*; \
    [ -f /usr/bin/php ] && rm -f /usr/bin/php; \
    ln -s /usr/bin/php82 /usr/bin/php;

# Calculate download URL
ENV VERSION=5.2.1
ENV URL=https://files.phpmyadmin.net/phpMyAdmin/${VERSION}/phpMyAdmin-${VERSION}-all-languages.tar.xz
LABEL version=$VERSION

# Download tarball, verify it using gpg and extract
ADD $URL /tmp/
ADD $URL.asc /tmp/

# Copy configuration
COPY setup /config

RUN set -ex; \
    mkdir /usr/src; \
    mkdir /etc/phpmyadmin/; \
    mkdir /sessions; \
    ls -l /config; \
    export GNUPGHOME="$(mktemp -d)"; \
    export GPGKEY="3D06A59ECE730EB71B511C17CE752F178259BD92"; \
    gpg --batch --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPGKEY" \
        || gpg --batch --keyserver ipv4.pool.sks-keyservers.net --recv-keys "$GPGKEY" \
        || gpg --batch --keyserver keys.gnupg.net --recv-keys "$GPGKEY" \
        || gpg --batch --keyserver pgp.mit.edu --recv-keys "$GPGKEY" \
        || gpg --batch --keyserver keyserver.pgp.com --recv-keys "$GPGKEY"; \
    gpg --batch --verify /tmp/phpMyAdmin-${VERSION}-all-languages.tar.xz.asc /tmp/phpMyAdmin-${VERSION}-all-languages.tar.xz; \
    tar -xf /tmp/phpMyAdmin-${VERSION}-all-languages.tar.xz -C /usr/src; \
    gpgconf --kill all; \
    rm -r "$GNUPGHOME" /tmp/phpMyAdmin-${VERSION}-all-languages.tar.xz /tmp/phpMyAdmin-${VERSION}-all-languages.tar.xz.asc; \
    mv /usr/src/phpMyAdmin-$VERSION-all-languages /usr/src/phpmyadmin; \
    rm -rf /usr/src/phpmyadmin/setup/ /usr/src/phpmyadmin/examples/ /usr/src/phpmyadmin/test/ /usr/src/phpmyadmin/po/ /usr/src/phpmyadmin/composer.json /usr/src/phpmyadmin/RELEASE-DATE-$VERSION; \
    sed -i "s@'configFile' => ROOT_PATH . 'config.inc.php',@'configFile' => '/etc/phpmyadmin/config.inc.php',@" /usr/src/phpmyadmin/libraries/vendor_config.php; \
    cp -R /usr/src/phpmyadmin/* /var/www/html/; \
    cp /config/config.inc.php /etc/phpmyadmin/config.inc.php && \
    cp /config/php.ini /etc/php82/php.ini && \
    chown -R unit:unit /var/www/html /sessions; \
    cp /config/healthcheck.php /var/www/html/;

EXPOSE 80
ENTRYPOINT ["/config/start.sh"]
CMD ["unitd", "--no-daemon", "--control", "unix:/var/run/control.unit.sock"]

## Health Check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD curl -f http://127.0.0.1/healthcheck.php || exit 1
