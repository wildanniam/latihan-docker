# syntax=docker/dockerfile:1

# Stage 1: Dependencies
FROM composer:lts AS deps

WORKDIR /app

RUN --mount=type=bind,source=composer.json,target=composer.json \
    --mount=type=bind,source=composer.lock,target=composer.lock \
    --mount=type=cache,target=/tmp/cache \
    composer install --no-dev --no-interaction

# Stage 2: Production
FROM php:8.2-apache AS final

# Install necessary PHP extensions
RUN docker-php-ext-install pdo pdo_mysql

# Use production php.ini
RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Copy only the vendor directory from deps stage
COPY --from=deps /app/vendor/ /var/www/html/vendor

# Copy application source code
COPY ./src /var/www/html

# Set non-root user
USER www-data
