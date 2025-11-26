#!/bin/bash
set -e

echo "========================================="
echo "Railway WordPress Startup"
echo "========================================="

# Debug: Show all available environment variables (without values for sensitive ones)
echo "Available MySQL-related variables:"
env | grep -i mysql | sed 's/=.*/=***/' || echo "No MYSQL variables found"
echo ""
env | grep -i wordpress | sed 's/PASSWORD=.*/PASSWORD=***/' || echo "No WORDPRESS variables found"
echo "========================================="

# Parse MYSQL_URL if available (Railway provides this)
# Format: mysql://user:password@host:port/database
if [ -n "$MYSQL_URL" ] && [ -z "$WORDPRESS_DB_HOST" ]; then
    echo "Parsing MYSQL_URL..."
    # Extract components from URL
    MYSQL_URL_STRIPPED="${MYSQL_URL#mysql://}"

    # Get user:password@host:port/database
    USERPASS="${MYSQL_URL_STRIPPED%%@*}"
    HOSTPORTDB="${MYSQL_URL_STRIPPED#*@}"

    # Extract user and password
    DB_USER="${USERPASS%%:*}"
    DB_PASS="${USERPASS#*:}"

    # Extract host:port and database
    HOSTPORT="${HOSTPORTDB%%/*}"
    DB_NAME="${HOSTPORTDB#*/}"

    # Extract host and port
    DB_HOST="${HOSTPORT%%:*}"
    DB_PORT="${HOSTPORT#*:}"

    export WORDPRESS_DB_HOST="${DB_HOST}:${DB_PORT}"
    export WORDPRESS_DB_NAME="$DB_NAME"
    export WORDPRESS_DB_USER="$DB_USER"
    export WORDPRESS_DB_PASSWORD="$DB_PASS"

    echo "Parsed from MYSQL_URL successfully"
fi

# Fallback: Map Railway MySQL service variables to WordPress expected variables
# Railway MySQL service can expose variables in different formats

# Set the database host
if [ -z "$WORDPRESS_DB_HOST" ]; then
    if [ -n "$MYSQLHOST" ]; then
        if [ -n "$MYSQLPORT" ]; then
            export WORDPRESS_DB_HOST="${MYSQLHOST}:${MYSQLPORT}"
        else
            export WORDPRESS_DB_HOST="$MYSQLHOST"
        fi
    elif [ -n "$MYSQL_HOST" ]; then
        if [ -n "$MYSQL_PORT" ]; then
            export WORDPRESS_DB_HOST="${MYSQL_HOST}:${MYSQL_PORT}"
        else
            export WORDPRESS_DB_HOST="$MYSQL_HOST"
        fi
    fi
fi

# Map database name
if [ -z "$WORDPRESS_DB_NAME" ]; then
    if [ -n "$MYSQLDATABASE" ]; then
        export WORDPRESS_DB_NAME="$MYSQLDATABASE"
    elif [ -n "$MYSQL_DATABASE" ]; then
        export WORDPRESS_DB_NAME="$MYSQL_DATABASE"
    fi
fi

# Map database user
if [ -z "$WORDPRESS_DB_USER" ]; then
    if [ -n "$MYSQLUSER" ]; then
        export WORDPRESS_DB_USER="$MYSQLUSER"
    elif [ -n "$MYSQL_USER" ]; then
        export WORDPRESS_DB_USER="$MYSQL_USER"
    fi
fi

# Map database password
if [ -z "$WORDPRESS_DB_PASSWORD" ]; then
    if [ -n "$MYSQLPASSWORD" ]; then
        export WORDPRESS_DB_PASSWORD="$MYSQLPASSWORD"
    elif [ -n "$MYSQL_PASSWORD" ]; then
        export WORDPRESS_DB_PASSWORD="$MYSQL_PASSWORD"
    elif [ -n "$MYSQL_ROOT_PASSWORD" ]; then
        export WORDPRESS_DB_PASSWORD="$MYSQL_ROOT_PASSWORD"
    fi
fi

# Set table prefix if not set
if [ -z "$WORDPRESS_TABLE_PREFIX" ]; then
    export WORDPRESS_TABLE_PREFIX="wp_"
fi

# Enable debug mode to see errors
export WORDPRESS_DEBUG="1"
export WORDPRESS_DEBUG_LOG="1"
export WORDPRESS_DEBUG_DISPLAY="1"

echo "========================================="
echo "Final WordPress Database Configuration:"
echo "WORDPRESS_DB_HOST: ${WORDPRESS_DB_HOST:-NOT SET}"
echo "WORDPRESS_DB_NAME: ${WORDPRESS_DB_NAME:-NOT SET}"
echo "WORDPRESS_DB_USER: ${WORDPRESS_DB_USER:-NOT SET}"
echo "WORDPRESS_DB_PASSWORD: ${WORDPRESS_DB_PASSWORD:+[SET]}"
echo "WORDPRESS_TABLE_PREFIX: ${WORDPRESS_TABLE_PREFIX:-wp_}"
echo "========================================="

# Verify required variables are set
MISSING=""
[ -z "$WORDPRESS_DB_HOST" ] && MISSING="$MISSING WORDPRESS_DB_HOST"
[ -z "$WORDPRESS_DB_NAME" ] && MISSING="$MISSING WORDPRESS_DB_NAME"
[ -z "$WORDPRESS_DB_USER" ] && MISSING="$MISSING WORDPRESS_DB_USER"
[ -z "$WORDPRESS_DB_PASSWORD" ] && MISSING="$MISSING WORDPRESS_DB_PASSWORD"

if [ -n "$MISSING" ]; then
    echo "ERROR: Missing required variables:$MISSING"
    echo ""
    echo "Please set these in Railway dashboard:"
    echo "  - Link WordPress service to MySQL service, OR"
    echo "  - Set MYSQL_URL variable, OR"
    echo "  - Set individual WORDPRESS_DB_* variables"
    echo ""
    echo "Available Railway MySQL variables to reference:"
    echo '  WORDPRESS_DB_HOST = ${{MySQL-XcHa.MYSQLHOST}}:${{MySQL-XcHa.MYSQLPORT}}'
    echo '  WORDPRESS_DB_NAME = ${{MySQL-XcHa.MYSQLDATABASE}}'
    echo '  WORDPRESS_DB_USER = ${{MySQL-XcHa.MYSQLUSER}}'
    echo '  WORDPRESS_DB_PASSWORD = ${{MySQL-XcHa.MYSQLPASSWORD}}'
fi

# Test database connection before starting WordPress
echo ""
echo "Testing database connection..."
if command -v mysqladmin &> /dev/null; then
    if mysqladmin ping -h "${WORDPRESS_DB_HOST%%:*}" -P "${WORDPRESS_DB_HOST##*:}" -u "$WORDPRESS_DB_USER" -p"$WORDPRESS_DB_PASSWORD" --silent 2>/dev/null; then
        echo "Database connection successful!"
    else
        echo "WARNING: Could not connect to database. WordPress may fail to start."
    fi
else
    echo "mysqladmin not available, skipping connection test"
fi

echo ""
echo "Starting WordPress..."
echo "========================================="

# Call the original WordPress entrypoint
exec docker-entrypoint.sh "$@"
