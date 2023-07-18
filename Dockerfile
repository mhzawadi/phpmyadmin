FROM alpine:3
MAINTAINER Matthew Horwood <matt@horwood.biz>

# Install required deb packages
RUN apk update && \
    apk add gnupg nginx php81-fpm php81-common php81-iconv php81-json php81-gd \
    php81-curl php81-xml php81-mysqli php81-imap php81-pdo php81-pdo_mysql \
    php81-soap php81-posix php81-gettext php81-ldap \
    php81-ctype php81-dom php81-session php81-mbstring curl \
    && mkdir -p /var/www/html/ \
    && mkdir -p /run/nginx \
    && rm -f /var/cache/apk/*;

# Calculate download URL
ENV VERSION 5.2.1
ENV URL https://files.phpmyadmin.net/phpMyAdmin/${VERSION}/phpMyAdmin-${VERSION}-all-languages.tar.xz
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
    cp /config/php.ini /etc/php81/php.ini && \
    cp /config/php_fpm_site.conf /etc/php81/php-fpm.d/www.conf; \
    chown -R nobody:nginx /var/www/html /sessions; \
    cp /config/nginx_site.conf /etc/nginx/http.d/default.conf; \
    cp /config/healthcheck.php /var/www/html/;

EXPOSE 80
ENTRYPOINT ["/config/start.sh"]
CMD ["nginx", "-g", "daemon off;"]

## Health Check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD curl -f http://127.0.0.1/healthcheck.php || exit 1
