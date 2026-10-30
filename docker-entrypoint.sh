
#!/bin/bash
set -e

cd /var/www/html

# Ensure Laravel writable directories exist
mkdir -p storage/framework/cache \
         storage/framework/sessions \
         storage/framework/views \
         storage/logs \
         bootstrap/cache

# Apply permissions
chown -R www-data:www-data storage bootstrap/cache

# Cache Laravel configuration and routes
php artisan config:cache
php artisan route:cache
php artisan view:cache

# Run database migrations
php artisan migrate --force

# Start Apache
exec apache2-foreground
