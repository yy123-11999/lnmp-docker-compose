FROM php:8.2-fpm-alpine

RUN docker-php-ext-install mysqli pdo pdo_mysql opcache

RUN apk add --no-cache $PHPIZE_DEPS \
    && pecl install redis \
    && docker-php-ext-enable redis

WORKDIR /var/www/html
