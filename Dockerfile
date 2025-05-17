# syntax=docker/dockerfile:1

# Stage 1: Install dependencies (tanpa dev)
FROM composer:lts AS deps
WORKDIR /app

# Mount composer.json dan composer.lock untuk install dependencies
RUN --mount=type=bind,source=composer.json,target=composer.json \
    --mount=type=bind,source=composer.lock,target=composer.lock \
    --mount=type=cache,target=/tmp/cache \
    composer install --no-dev --no-interaction

# Stage 2: Run tests (dengan dev dependencies)
FROM composer:lts AS test
WORKDIR /app

# Salin semua file yang diperlukan
COPY . .

# Install semua dependencies (termasuk dev)
RUN composer install --no-interaction

# Jalankan test jika ada file phpunit.xml atau phpunit.xml.dist
CMD ["vendor/bin/phpunit", "--configuration=phpunit.xml"]

# Stage 3: Production image
FROM php:8.2-apache AS final

# Install PHP extensions yang diperlukan
RUN docker-php-ext-install pdo pdo_mysql

# Gunakan php.ini production
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Copy hasil vendor dari deps stage
COPY --from=deps /app/vendor/ /var/www/html/vendor

# Copy source code ke Apache directory
COPY ./src /var/www/html

# Jalankan sebagai www-data (non-root)
USER www-data
