FROM wordpress:latest

# Install WP-CLI and tools
RUN curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar && \
    chmod +x wp-cli.phar && \
    mv wp-cli.phar /usr/local/bin/wp && \
    apt-get update && apt-get install -y unzip less mariadb-client && rm -rf /var/lib/apt/lists/*

# Create custom entrypoint to fix wp-config after WordPress copies it
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["apache2-foreground"]
