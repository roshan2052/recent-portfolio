
# Stage 1: Build frontend assets
FROM node:22-alpine AS frontend

WORKDIR /app

COPY . .

RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi \
    && npm run build


# Stage 2: Laravel PHP application
FROM php:8.4-apache

RUN apt-get update && apt-get install -y \
    git unzip zip curl libzip-dev libpng-dev \
    libjpeg-dev libfreetype6-dev libicu-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install pdo_mysql bcmath gd intl zip opcache \
    && a2enmod rewrite headers \
    && rm -rf /var/lib/apt/lists/*

COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /var/www/html

COPY composer.json composer.lock ./

RUN composer install --no-dev --no-interaction \
    --prefer-dist --optimize-autoloader --no-scripts

COPY . .

# Copy compiled Vite assets
COPY --from=frontend /app/public/build ./public/build

RUN composer dump-autoload --no-dev --optimize \
    && mkdir -p storage/framework/cache \
       storage/framework/sessions \
       storage/framework/views \
       storage/logs bootstrap/cache \
    && chown -R www-data:www-data storage bootstrap/cache

ENV PORT=10000

RUN sed -i 's/Listen 80/Listen 10000/' /etc/apache2/ports.conf \
    && sed -i 's/:80>/:10000>/' \
       /etc/apache2/sites-available/000-default.conf \
    && sed -i 's#DocumentRoot /var/www/html#DocumentRoot /var/www/html/public#' \
       /etc/apache2/sites-available/000-default.conf

EXPOSE 10000

COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

CMD ["docker-entrypoint.sh"]
