ARG COMPOSER_VERSION="1.9.3"
ARG DEBIAN_TAG="stable-20191224-slim"
ARG PHP_VERSION="7.4"
ARG GROUP_ID=1000
ARG USER_ID=1000

FROM composer:${COMPOSER_VERSION} AS composer

FROM debian:${DEBIAN_TAG}

ENV DEBIAN_FRONTEND noninteractive

# Install minimal system requirements
RUN true \
 && apt-get -qq update \
 && apt-get -qy install --no-install-recommends \
        ca-certificates \
        wget \
        git \
 && rm -rf /var/lib/apt/lists/* \
;

# Install minimal PHP composer dependencies
ARG PHP_VERSION
RUN true \
 && wget -qq -O /etc/apt/trusted.gpg.d/php.gpg "https://packages.sury.org/php/apt.gpg" \
 && echo "deb https://packages.sury.org/php/ $(. /etc/os-release && echo $VERSION_CODENAME) main" > /etc/apt/sources.list.d/php${PHP_VERSION}.list \
 && apt-get -qq update \
 && apt-get -qy install --no-install-recommends \
        php${PHP_VERSION}-bcmath \
        php${PHP_VERSION}-cli \
        php${PHP_VERSION}-curl \
        php${PHP_VERSION}-mbstring \
        php${PHP_VERSION}-xml \
        php${PHP_VERSION}-zip \
 && rm -rf /var/lib/apt/lists/* \
;

# App specific dependencies
RUN true \
 && apt-get -qq update \
 && apt-get -qy install --no-install-recommends \
        "php${PHP_VERSION}-fpm" \
 && rm -rf /var/lib/apt/lists/* \
 && ln -s "/usr/sbin/php-fpm${PHP_VERSION}" /usr/sbin/php-fpm \
 && ln -s "/etc/init.d/php${PHP_VERSION}-fpm" /etc/init.d/php-fpm \
 && mkdir /run/php/ \
;
COPY "www.conf" "/etc/php/${PHP_VERSION}/fpm/pool.d/www.conf"


# Install dev tools
RUN true \
 && apt-get -qq update \
 && apt-get -qy install --no-install-recommends \
        "php${PHP_VERSION}-xdebug" \
        unzip \
 && phpdismod xdebug \
 && rm -rf /var/lib/apt/lists/* \
;
COPY xdebug.ini "/etc/php/${PHP_VERSION}/mods-available/xdebug.ini"

ARG XDEBUG_REMOTE_HOST
RUN sed -i "/^xdebug.remote_host/s/localhost/${XDEBUG_REMOTE_HOST}/g" "/etc/php/${PHP_VERSION}/mods-available/xdebug.ini";

# Modify www-data user to match system user
ARG GROUP_ID
ARG USER_ID
RUN true \
 && groupmod www-data --gid "${GROUP_ID}" \
 && usermod www-data --uid "${USER_ID}" --gid www-data -d /var/www -s /bin/bash \
 && mkdir -p /var/www \
 && chown -R www-data:www-data /var/www \
;

USER www-data

# Install Composer
COPY --from=composer /usr/bin/composer /usr/bin/composer
RUN true \
 && composer global require hirak/prestissimo \
 && composer global clear-cache --quiet \
;

USER root

COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

CMD ["/docker-entrypoint.sh"]

EXPOSE 9000
