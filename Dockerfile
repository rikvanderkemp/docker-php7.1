FROM alpine:3.6

MAINTAINER Rik van der Kemp <rik@h1.nl>

ADD https://php.codecasts.rocks/php-alpine.rsa.pub /etc/apk/keys/php-alpine.rsa.pub

RUN echo "@php http://php.codecasts.rocks/v3.6/php-7.1" >> /etc/apk/repositories

RUN apk update

RUN apk add --update  \
    wget \
    libpng \
    libpng-dev \
    libjpeg-turbo-dev \
    libwebp-dev \
    zlib-dev \
    libxpm-dev \
    nginx \
    supervisor \
    curl \
    sed \
    tar \
    libxml2-dev \
    freetype-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    libmcrypt-dev

RUN apk add --update \
        "php7@php" \
        "php7-common@php" \
        "php7-fpm@php" \
        "php7-bcmath@php" \
        "php7-bz2@php" \
        "php7-calendar@php" \
        "php7-ctype@php" \
        "php7-curl@php" \
        "php7-dba@php" \
        "php7-dom@php" \
        "php7-embed@php" \
        "php7-enchant@php" \
        "php7-exif@php" \
        "php7-ftp@php" \
        "php7-gd@php" \
        "php7-gettext@php" \
        "php7-gmp@php" \
        "php7-iconv@php" \
        "php7-imap@php" \
        "php7-intl@php" \
        "php7-json@php" \
        "php7-ldap@php" \
        "php7-litespeed@php" \
        "php7-mbstring@php" \
        "php7-mcrypt@php" \
        "php7-mysqli@php" \
        "php7-mysqlnd@php" \
        "php7-odbc@php" \
        "php7-opcache@php" \
        "php7-openssl@php" \
        "php7-pcntl@php" \
        "php7-pdo@php" \
        "php7-pdo_dblib@php" \
        "php7-pdo_mysql@php" \
        "php7-pdo_pgsql@php" \
        "php7-pdo_sqlite@php" \
        "php7-pear@php" \
        "php7-pgsql@php" \
        "php7-phar@php" \
        "php7-phpdbg@php" \
        "php7-posix@php" \
        "php7-pspell@php" \
        "php7-session@php" \
        "php7-shmop@php" \
        "php7-snmp@php" \
        "php7-soap@php" \
        "php7-sockets@php" \
        "php7-sqlite3@php" \
        "php7-sysvmsg@php" \
        "php7-sysvsem@php" \
        "php7-sysvshm@php" \
        "php7-tidy@php" \
        "php7-wddx@php" \
        "php7-xml@php" \
        "php7-xmlreader@php" \
        "php7-xmlrpc@php" \
        "php7-xsl@php" \
        "php7-zip@php" \
        "php7-zlib@php" \
        "php7-xdebug@php"




RUN mkdir -p /run/nginx
RUN rm /etc/nginx/conf.d/default.conf

COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY supervisord/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Setup NGINX
RUN sed -i "/listen = .*/c\listen = [::]:9000" /etc/php7/php-fpm.d/www.conf \
     && sed -i "/;access.log = .*/c\access.log = /proc/self/fd/2" /etc/php7/php-fpm.d/www.conf \
        && sed -i "/;clear_env = .*/c\clear_env = no" /etc/php7/php-fpm.d/www.conf \
        && sed -i "/;catch_workers_output = .*/c\catch_workers_output = yes" /etc/php7/php-fpm.d/www.conf \
        && sed -i "/pid = .*/c\;pid = /run/php/php7.0-fpm.pid" /etc/php7/php-fpm.conf \
        && sed -i "/;daemonize = .*/c\daemonize = no" /etc/php7/php-fpm.conf \
        && sed -i "/error_log = .*/c\error_log = /proc/self/fd/2" /etc/php7/php-fpm.conf


# Setting up XDebug
RUN sed -i "/;zend_extension=xdebug.so/c\zend_extension=xdebug.so" /etc/php7/conf.d/00_xdebug.ini \
    && echo "xdebug.idekey = PHPSTORM" >> /etc/php7/conf.d/00_xdebug.ini \
    && echo "xdebug.default_enable = 0" >> /etc/php7/conf.d/00_xdebug.ini \
    && echo "xdebug.remote_enable = 1" >> /etc/php7/conf.d/00_xdebug.ini  \
    && echo "xdebug.remote_autostart = 0" >> /etc/php7/conf.d/00_xdebug.ini \
    && echo "xdebug.remote_connect_back = 1" >> /etc/php7/conf.d/00_xdebug.ini \
    && echo "xdebug.remote_host = localhost" >> /etc/php7/conf.d/00_xdebug.ini \
    && echo "xdebug.profiler_enable = 0" >> /etc/php7/conf.d/00_xdebug.ini

# Performance tweaks
RUN sed -i "/;realpath_cache_size = .*/c\realpath_cache_size=4096K" /etc/php7/php.ini \
    && sed -i "/;realpath_cache_ttl = .*/c\realpath_cache_ttl=600" /etc/php7/php.ini \
    && sed -i "/; sys_temp_dir = .*/c\sys_temp_dir=/var/www/var/cache" /etc/php7/php.ini \
    && sed -i "/;opcache.max_accelerated_files=2000/c\opcache.max_accelerated_files=20000" /etc/php7/php.ini


# Blackfire
RUN version=$(php7 -r "echo PHP_MAJOR_VERSION.PHP_MINOR_VERSION;") \
    && curl -A "Docker" -o /tmp/blackfire-probe.tar.gz -D - -L -s https://blackfire.io/api/v1/releases/probe/php/alpine/amd64/$version \
    && tar zxpf /tmp/blackfire-probe.tar.gz -C /tmp \
    && mv /tmp/blackfire-*.so $(php7 -r "echo ini_get('extension_dir');")/blackfire.so \
    && printf "extension=blackfire.so\nblackfire.agent_socket=tcp://blackfire:8707\n" > /etc/php7/conf.d/blackfire.ini

EXPOSE 80

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
