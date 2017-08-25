FROM php:7.1-fpm

# install the PHP extensions we need
RUN set -ex; \
	\
	apt-get update; \
	apt-get install -y \
		libjpeg-dev \
		libpng-dev \
    libicu-dev \
    libmcrypt-dev \
    libmagickwand-dev \
    libsodium-dev \
    --no-install-recommends && rm -r /var/lib/apt/lists/* \
  ; \
  \
	pecl install redis-3.1.3 imagick-3.4.3 libsodium-1.0.6; \
	docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr; \
  docker-php-ext-enable redis imagick libsodium; \
	docker-php-ext-install -j$(nproc) exif gettext intl mcrypt sockets zip gd mysqli opcache

# set recommended PHP.ini settings
# see https://secure.php.net/manual/en/opcache.installation.php
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

ENV WORDPRESS_VERSION 4.8.1
ENV WORDPRESS_SHA1 5376cf41403ae26d51ca55c32666ef68b10e35a4

RUN set -ex; \
  \
	curl -o wordpress.tar.gz -fSL "https://wordpress.org/wordpress-${WORDPRESS_VERSION}.tar.gz"; \
	echo "$WORDPRESS_SHA1 *wordpress.tar.gz" | sha1sum -c -; \
# upstream tarballs include ./wordpress/ so this gives us /usr/src/wordpress
	tar -xzf wordpress.tar.gz -C /usr/src/; \
	rm wordpress.tar.gz; \
	chown -R www-data:www-data /usr/src/wordpress

RUN set -ex; \
  sed -i -e "s/pm.max_children = 5/pm.max_children = 70/g" /usr/local/etc/php-fpm.d/www.conf; \
  sed -i -e "s/pm.start_servers = 2/pm.start_servers = 15/g" /usr/local/etc/php-fpm.d/www.conf; \
  sed -i -e "s/pm.min_spare_servers = 1/pm.min_spare_servers = 15/g" /usr/local/etc/php-fpm.d/www.conf; \
  sed -i -e "s/pm.max_spare_servers = 3/pm.max_spare_servers = 35/g" /usr/local/etc/php-fpm.d/www.conf; \
  sed -i -e "s/;pm.max_requests = 500/pm.max_requests = 500/g" /usr/local/etc/php-fpm.d/www.conf;

COPY docker-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["php-fpm"]
