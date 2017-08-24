FROM wordpress:php7.1-fpm

RUN apt-get update && apt-get install -y \
        libicu-dev \
        libmcrypt-dev \
        libmagickwand-dev \
        libsodium-dev \
        --no-install-recommends && rm -r /var/lib/apt/lists/* \

    && pecl install redis-3.1.3 imagick-3.4.3 libsodium-1.0.6 \
    && docker-php-ext-enable redis imagick libsodium \
    && docker-php-ext-install -j$(nproc) exif gettext intl mcrypt sockets zip

RUN { \
    echo 'opcache.enable=1'; \
    echo 'opcache.memory_consumption=192'; \
    echo 'opcache.max_wasted_percentage=5'; \
    echo 'opcache.interned_strings_buffer=16'; \
    echo 'opcache.max_accelerated_files=4000'; \
    echo 'opcache.revalidate_freq=5'; \
    echo 'opcache.save_comments=1'; \
    echo 'opcache.load_comments=1'; \
    echo 'opcache.enable_file_override=0'; \
    echo 'opcache.fast_shutdown=1'; \
    echo 'opcache.enable_cli=1'; \
	} > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN { \
    echo 'upload_max_filesize = 64M'; \
    echo 'post_max_size = 64M'; \
    echo 'max_execution_time = 300'; \
    echo 'memory_limit = 256M'; \
	} > /usr/local/etc/php/php.ini

RUN sed -i -e "s/pm.max_children = 5/pm.max_children = 70/g" /usr/local/etc/php-fpm.d/www.conf && \
      sed -i -e "s/pm.start_servers = 2/pm.start_servers = 15/g" /usr/local/etc/php-fpm.d/www.conf && \
      sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 15/g" /usr/local/etc/php-fpm.d/www.conf && \
      sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 35/g" /usr/local/etc/php-fpm.d/www.conf && \
      sed -i -e "s/;pm.max_requests = 500/pm.max_requests = 500/g" /usr/local/etc/php-fpm.d/www.conf
