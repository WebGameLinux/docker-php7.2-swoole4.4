# @description php image base on the debian 9.x
#
#                       Some Information
# ------------------------------------------------------------------------------------
# @link https://hub.docker.com/_/debian/      alpine image
# @link https://hub.docker.com/_/php/         php image
# @link https://github.com/docker-library/php php dockerfiles
# @see https://github.com/docker-library/php/tree/master/7.2/stretch/cli/Dockerfile
# ------------------------------------------------------------------------------------
# @build-example docker build . -f Dockerfile -t weblinuxgame/travel
# php:7.2
FROM php:7.2

LABEL maintainer="weblinuxgame <weblinuxgame@126.com>"

# --build-arg timezone=Asia/Shanghai
ARG timezone
# app env: prod pre test dev
ARG app_env=test
# default use www-data user
ARG work_user=www-data
# installer
ARG installer=apt-get
# packages
ARG install_packages=" gcc g++ curl wget git zip unzip less vim procps lsof tcpdump htop openssl net-tools iputils-ping  "
# libs
ARG install_libs=" libz-dev libssl-dev libnghttp2-dev libpcre3-dev libjpeg-dev libpng-dev libfreetype6-dev libmagickwand-dev "
# php exts
ARG install_php_exts=" pcntl bcmath gd pdo_mysql mbstring sockets zip sysvmsg sysvsem sysvshm "
# clean dir
ARG remove_package_dir_command="rm -rf /var/lib/apt/lists/*"
# run command
ARG command_run="/var/www/travel/bin/laravels"
# work dir
ARG work_dir="$PWD"

# default APP_ENV = test
ENV APP_ENV=${app_env:-"test"} \
    TIMEZONE=${timezone:-"Asia/Shanghai"} \
    PHPREDIS_VERSION=5.1.0 \
    SWOOLE_VERSION=4.4.18 \
    IMAGICK_VERSION=3.4.4 \
    COMPOSER_UPDATE="" \
    APOLLO_AGENT=1  \
    WORK_DIR=${work_dir} \
    WORK_USER=${work_user:-"www-data"} \
    COMPOSER_ALLOW_SUPERUSER=1 \
    INSTALLER=${installer:-"apt-get"} \
    COMMAND_RUN=${command_run:-"/var/www/travel/bin/laravels"} \
    REMOVE_COMMAND=${remove_package_dir_command:-"rm -rf /var/lib/apt/lists/*"} \
    PACKAGES=${install_packages:-" gcc g++ curl wget git zip unzip less vim procps lsof tcpdump htop openssl net-tools iputils-ping "} \
    MY_LIBS=${install_libs:-" libz-dev libssl-dev libnghttp2-dev libpcre3-dev libjpeg-dev libpng-dev libfreetype6-dev libmagickwand-dev"} \
    PHP_EXT=${install_php_exts:-" pcntl bcmath gd pdo_mysql mbstring sockets zip sysvmsg sysvsem sysvshm "}

# source switch
ADD sources.list /etc/apt/sources.list
# endtrypoint
COPY endtrypoint.sh /usr/bin/endtrypoint.sh

# Libs -y --no-install-recommends
RUN  echo "nameserver 114.114.114.114 \nnameserver 8.8.8.8" >> /etc/resolv.conf \
    && ${INSTALLER} update --fix-missing \
    && ${INSTALLER} install -y ${PACKAGES} ${MY_LIBS} \
    # Install PHP extensions
    && docker-php-ext-install ${PHP_EXT} \
    # Clean apt cache
    && ${REMOVE_COMMAND}

# Install composer
RUN curl -sS https://getcomposer.org/installer | php \
    && mv composer.phar /usr/local/bin/composer \
    && composer self-update --clean-backups \
    # Install Composer registry china
    && composer global require slince/composer-registry-manager \
    && composer repo:use aliyun \
    # Install mongod extension
    && pecl install mongodb \
    && docker-php-ext-enable mongodb \
    # Install phclcon extension
    && pecl install phalcon \
    && docker-php-ext-enable psr \
    && docker-php-ext-enable phalcon \
    # Install imagick extension
    && pecl install imagick-beta \
    && rm -rf /tmp/imagick.tar.tgz \
    && docker-php-ext-enable imagick \
    # Install redis extension
    && wget http://pecl.php.net/get/redis-${PHPREDIS_VERSION}.tgz -O /tmp/redis.tar.tgz \
    && pecl install /tmp/redis.tar.tgz \
    && rm -rf /tmp/redis.tar.tgz \
    && docker-php-ext-enable redis \
    # clean pecl cache
    && rm -rf /tmp/pear/temp  \
    # Install swoole extension
    && wget https://github.com/swoole/swoole-src/archive/v${SWOOLE_VERSION}.tar.gz -O swoole.tar.gz \
    && mkdir -p swoole \
    && tar -xf swoole.tar.gz -C swoole --strip-components=1 \
    && rm swoole.tar.gz \
    && ( \
    cd swoole \
    && phpize \
    && ./configure --enable-mysqlnd --enable-sockets --enable-openssl --enable-http2 \
    && make -j$(nproc) \
    && make install \
    ) \
    && rm -r swoole \
    && docker-php-ext-enable swoole \
    # Clear dev deps
    && ${INSTALLER} clean \
    && ${INSTALLER} purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false \
    # Timezone
    && cp /usr/share/zoneinfo/${TIMEZONE} /etc/localtime \
    && echo "${TIMEZONE}" > /etc/timezone \
    && echo "[Date]\ndate.timezone=${TIMEZONE}" > /usr/local/etc/php/conf.d/timezone.ini

WORKDIR /var/www

# export volumes
VOLUME /var/www/app

# 启动脚本
ENTRYPOINT /usr/bin/endtrypoint.sh

