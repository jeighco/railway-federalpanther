#!/bin/bash
set -e

# Map Railway MySQL service variables to WordPress expected variables
# Railway MySQL service exposes: MYSQL_HOST, MYSQL_DATABASE, MYSQL_USER, MYSQL_PASSWORD

# Set the database host - use internal Railway hostname
# Priority: WORDPRESS_DB_HOST > MYSQL_HOST > hardcoded internal hostname
if [ -z "$WORDPRESS_DB_HOST" ]; then
    if [ -n "$MYSQL_HOST" ]; then
        export WORDPRESS_DB_HOST="$MYSQL_HOST"
    elif [ -n "$MYSQLHOST" ]; then
        # Railway also provides MYSQLHOST
        export WORDPRESS_DB_HOST="$MYSQLHOST"
    fi
fi

# Map database name
if [ -z "$WORDPRESS_DB_NAME" ]; then
    if [ -n "$MYSQL_DATABASE" ]; then
        export WORDPRESS_DB_NAME="$MYSQL_DATABASE"
    elif [ -n "$MYSQLDATABASE" ]; then
        export WORDPRESS_DB_NAME="$MYSQLDATABASE"
    fi
fi

# Map database user
if [ -z "$WORDPRESS_DB_USER" ]; then
    if [ -n "$MYSQL_USER" ]; then
        export WORDPRESS_DB_USER="$MYSQL_USER"
    elif [ -n "$MYSQLUSER" ]; then
        export WORDPRESS_DB_USER="$MYSQLUSER"
    fi
fi

# Map database password
if [ -z "$WORDPRESS_DB_PASSWORD" ]; then
    if [ -n "$MYSQL_PASSWORD" ]; then
        export WORDPRESS_DB_PASSWORD="$MYSQL_PASSWORD"
    elif [ -n "$MYSQLPASSWORD" ]; then
        export WORDPRESS_DB_PASSWORD="$MYSQLPASSWORD"
    elif [ -n "$MYSQL_ROOT_PASSWORD" ]; then
        export WORDPRESS_DB_PASSWORD="$MYSQL_ROOT_PASSWORD"
    fi
fi

# Set table prefix if not set
if [ -z "$WORDPRESS_TABLE_PREFIX" ]; then
    export WORDPRESS_TABLE_PREFIX="wp_"
fi

# Debug output (remove in production)
echo "========================================="
echo "WordPress Database Configuration:"
echo "WORDPRESS_DB_HOST: $WORDPRESS_DB_HOST"
echo "WORDPRESS_DB_NAME: $WORDPRESS_DB_NAME"
echo "WORDPRESS_DB_USER: $WORDPRESS_DB_USER"
echo "WORDPRESS_DB_PASSWORD: [hidden]"
echo "========================================="

# Call the original WordPress entrypoint
exec docker-entrypoint.sh "$@"
