# First stage: build with composer
FROM debian:buster-slim AS composer
RUN apt -y update && apt -y upgrade; \
    apt -y install --no-install-recommends \
    unzip \
    php \
    php-gd \ 
    php-imap \
    php-intl \
    php-curl \
    php-xml \
    php-zip \
    composer=1.8.4-1+deb10u1;
COPY . /build/
WORKDIR /build
RUN composer install --no-dev; \
    mv custom newcustom; \
    mkdir custom;


# Second stage: Install with php-fpm
FROM php:fpm AS web
LABEL Name=lwcrm
LABEL Version=testing
EXPOSE 9000

# Environment variables. 
ENV \
    SUITECRM_DATABASE_COLLATION=utf8_general_ci \
    SUITECRM_DATABASE_DROP_TABLES=0 \
    SUITECRM_DATABASE_HOST_INSTANCE=SQLEXPRESS \
    SUITECRM_DATABASE_HOST=localhost \
    SUITECRM_DATABASE_NAME=suitecrm \
    SUITECRM_DATABASE_PASSWORD=changeme \
    SUITECRM_DATABASE_PORT=3306 \
    SUITECRM_DATABASE_TYPE=mysql \
    SUITECRM_DATABASE_USE_SSL=false \
    SUITECRM_DATABASE_USER_IS_PRIVILEGED=false \
    SUITECRM_DATABASE_USER=dbuser \
    SUITECRM_DEFAULT_CURRENCY_ISO4217=EUR \
    SUITECRM_DEFAULT_CURRENCY_NAME=Euro \
    SUITECRM_DEFAULT_CURRENCY_SIGNIFICANT_DIGITS=2\
    SUITECRM_DEFAULT_CURRENCY_SYMBOL=€ \
    SUITECRM_DEFAULT_DATE_FORMAT="d.m.y" \
    SUITECRM_DEFAULT_DECIMAL_SEPERATOR="," \
    SUITECRM_DEFAULT_LANGUAGE=en_US \ 
    SUITECRM_DEFAULT_NUMBER_GROUPING_SEPARATOR=" " \
    SUITECRM_DEFAULT_TIME_FORMAT="H:i" \
    SUITECRM_DEFAULT_EXPORT_CHARSET=UTF-8 \
    SUITECRM_EXPORT_DELIMITER=',' \
    SUITECRM_DEFAULT_LOCALE_NAME_FORMAT="s f l" \
    SUITECRM_SETUP_CREATE_DATABASE=0 \
    SUITECRM_SETUP_DEMO_DATA=false \
    SUITECRM_ADMIN_PASSWORD=changeme753 \
    SUITECRM_ADMIN_USER=admin123 \
    SUITECRM_HOSTNAME=localhost \
    SUITECRM_INSTALL_DIR=/var/www/html \
    SUITECRM_SITE_NAME=SuiteCRM \
    SUITECRM_SITE_URL=example.com \
    SUITECRM_CONFIG_LOC=${SUITECRM_INSTALL_DIR}/docker-configs

# Install necessary php modules
RUN apt update && apt -y upgrade; \
    apt -y install \
    cron \
    libzip-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libc-client-dev \
    libkrb5-dev \
    rsync; \
    docker-php-ext-configure gd --with-freetype --with-jpeg; \
    docker-php-ext-install -j$(nproc) gd; \
    docker-php-ext-configure imap --with-kerberos --with-imap-ssl; \
    docker-php-ext-install imap; \
    docker-php-ext-install -j$(nproc) mysqli; \
    docker-php-ext-install -j$(nproc) zip; \
    docker-php-ext-install -j$(nproc) bcmath; \
    apt-get -y autoremove; \
    apt-get -y clean; \
    rm -rf /var/lib/apt/lists/*; \
    mkdir -p /var/log/suitecrm; \
    ln -sf /dev/stdout /var/log/suitecrm/suitecrm.log; \
    mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"; \
    mkdir /app || echo "Directory /app exists" ;

# Use uid and gid of www-data used in nginx image
RUN usermod -aG 101 www-data 

# Get composer built app
COPY --from=composer --chown=www-data:www-data /build ${SUITECRM_INSTALL_DIR}

# Move entrypoint to container root
RUN mv /app/docker-entrypoint.sh /docker-entrypoint.sh \
    && chmod 777 /docker-entrypoint.sh;

ENTRYPOINT ["/docker-entrypoint.sh"]

WORKDIR ${SUITECRM_INSTALL_DIR}
CMD ["php-fpm"]
