FROM debian:buster-slim AS composer
RUN apt -y update && apt -y upgrade; \
    apt -y install unzip php php-gd php-imap php-intl php-curl php-xml php-zip composer=1.8.4-1+deb10u1
COPY . /build/
WORKDIR /build
RUN composer install --no-dev
RUN mv custom newcustom; \
    mkdir custom;



FROM php:fpm AS web
LABEL Name=lwcrm
LABEL Version=testing
EXPOSE 9000

# Environment variables. 
ENV \
    DATABASE_COLLATION=utf8_general_ci \
    DATABASE_DROP_TABLES=0 \
    DATABASE_HOST_INSTANCE=SQLEXPRESS \
    DATABASE_HOST=localhost \
    DATABASE_NAME=suitecrm \
    DATABASE_PASSWORD=changeme \
    DATABASE_PORT=3306 \
    DATABASE_TYPE=mysql \
    DATABASE_USE_SSL=false \
    DATABASE_USER_IS_PRIVILEGED=false \
    DATABASE_USER=dbuser \
    DEFAULT_CURRENCY_ISO4217=EUR \
    DEFAULT_CURRENCY_NAME=Euro \
    DEFAULT_CURRENCY_SIGNIFICANT_DIGITS=2\
    DEFAULT_CURRENCY_SYMBOL=€ \
    DEFAULT_DATE_FORMAT="d.m.y" \
    DEFAULT_DECIMAL_SEPERATOR="," \
    DEFAULT_LANGUAGE=en_US \ 
    DEFAULT_NUMBER_GROUPING_SEPARATOR=" " \
    DEFAULT_TIME_FORMAT="H:i" \
    EXPORT_CHARSET=UTF-8 \
    EXPORT_DELIMITER=',' \
    LOCALE_NAME_FORMAT="s f l" \
    SETUP_CREATE_DATABASE=0 \
    SETUP_DEMO_DATA=false \
    SUITECRM_ADMIN_PASSWORD=changeme753 \
    SUITECRM_ADMIN_USER=admin123 \
    SUITECRM_HOSTNAME=localhost \
    SUITECRM_INSTALL_DIR=/var/www/html \
    SUITECRM_SITE_NAME=SuiteCRM \
    SUITECRM_SITE_URL=example.com 

RUN apt update && apt -y upgrade; \
    apt -y install \
        cron \
        libzip-dev \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libc-client-dev \
        libkrb5-dev \
        rsync \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-configure imap --with-kerberos --with-imap-ssl \
    && docker-php-ext-install imap \
    && docker-php-ext-install -j$(nproc) mysqli \
    && docker-php-ext-install -j$(nproc) zip \
    && docker-php-ext-install -j$(nproc) bcmath \
    && apt-get -y autoremove \
    && apt-get -y clean \
    && mkdir -p /var/log/suitecrm \
    && ln -sf /dev/stdout /var/log/suitecrm/suitecrm.log \
    && mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"
RUN mkdir /app || echo "directory exists" 
COPY --from=composer --chown=www-data:www-data /build /app
RUN mv /app/docker-entrypoint.sh /docker-entrypoint.sh \
    && chmod 777 /docker-entrypoint.sh;
ENTRYPOINT ["/docker-entrypoint.sh"]
WORKDIR ${SUITECRM_INSTALL_DIR}
CMD ["php-fpm"]
