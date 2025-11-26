FROM wordpress:latest

# Install WP-CLI
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp

# Install unzip for .wpress imports
RUN apt-get update && apt-get install -y unzip less mariadb-client && rm -rf /var/lib/apt/lists/*

# Copy WordPress configuration
COPY wp-config.php /var/www/html/wp-config.php

# Set proper permissions
RUN chown -R www-data:www-data /var/www/html
