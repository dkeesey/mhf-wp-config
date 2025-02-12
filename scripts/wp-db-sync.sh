#!/bin/bash

# WordPress Database Sync Script

# Set path to MySQL binaries
MYSQL_BIN="/Users/DK-SuperPuppy/Library/Application Support/Local/lightning-services/mysql-8.0.16+6/bin/darwin/bin"
MYSQL_PATH="$MYSQL_BIN/mysql"
MYSQLDUMP_PATH="$MYSQL_BIN/mysqldump"

# Database connection parameters
DB_NAME="local"
DB_USER="root"
DB_PASS="root"
DB_PORT="10019"
DB_SOCKET="/Users/DK-SuperPuppy/Library/Application Support/Local/run/MIK2JKL-s/mysql/mysqld.sock"

# MySQL connection options
MYSQL_OPTS=(--socket="$DB_SOCKET" -u"$DB_USER" -p"$DB_PASS")
MYSQLDUMP_OPTS=(--no-tablespaces --skip-lock-tables)

# Set MySQL options for wp-cli
export MYSQL_DEFAULTS_FILE="$MYCNF"
export WP_CLI_MYSQL_ARGS="--defaults-file=$MYCNF"

# Cleanup function
cleanup() {
    rm -f "$MYCNF"
}
trap cleanup EXIT

# This script uses WP-CLI to sync databases between local and production environments

# Configuration
LOCAL_URL="masumihayashifoundationorg.local"
PROD_URL="masumihayashifoundation.org"
LOCAL_WP_PATH="/Volumes/PRO-G40/Workspace-G40/wp-masumihayashifoundation.org/app/public"
BACKUP_DIR="db-backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Validate WordPress installation
if [ ! -f "${LOCAL_WP_PATH}/wp-config.php" ]; then
    echo "Error: WordPress installation not found at ${LOCAL_WP_PATH}"
    echo "Please check the LOCAL_WP_PATH in the script configuration."
    exit 1
fi

# Default mode
MODE="pull"
DRY_RUN=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        pull)
            MODE="pull"
            shift
            ;;
        push)
            MODE="push"
            shift
            ;;
        -d|--dry-run)
            DRY_RUN="--dry-run"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Create backup directory
mkdir -p "${LOCAL_WP_PATH}/${BACKUP_DIR}"

# Change to WordPress directory
cd "${LOCAL_WP_PATH}" || exit 1

# Function to handle database operations
db_operation() {
    local direction=$1
    local temp_file="${BACKUP_DIR}/temp_${TIMESTAMP}.sql"
    local backup_file="${BACKUP_DIR}/backup_${TIMESTAMP}.sql"
    
    # Create backup directory if it doesn't exist
    mkdir -p "${BACKUP_DIR}"
    
    # Create backup of local database
    echo "Creating backup of local database..."
    if [ -z "$DRY_RUN" ]; then
        "$MYSQLDUMP_PATH" "${MYSQLDUMP_OPTS[@]}" "${MYSQL_OPTS[@]}" "$DB_NAME" > "$backup_file"
        if [ $? -ne 0 ]; then
            echo "Error: Failed to create backup"
            return 1
        fi
        echo "Backup created at $backup_file"
    else
        echo "[DRY RUN] Would backup local database"
        return 0
    fi

    if [ "$direction" = "push" ]; then
        read -p "WARNING: This will overwrite the production database. Continue? (y/N) " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Operation cancelled"
            return 1
        fi
        
        # Export local database
        echo "Exporting local database..."
        if [ -z "$DRY_RUN" ]; then
            $MYSQLDUMP_CMD $DB_NAME > "$temp_file"
            if [ $? -ne 0 ]; then
                echo "Error: Failed to export local database"
                return 1
            fi
            
            # TODO: Push to production (implement SSH transfer and import)
            echo "Push to production not yet implemented"
            return 1
        else
            echo "[DRY RUN] Would export local database"
            echo "[DRY RUN] Would push to production"
        fi
    else
        # Pull from production
        echo "Pulling from production..."
        if [ -z "$DRY_RUN" ]; then
            echo "Exporting production database..."
            # Use SSH to run mysqldump on production with direct credentials
            ssh wp_jqukgi@masumihayashifoundation "mysqldump -h mysql.masumihayashifoundation.org -u z2d9giq -p'dean70?!' masumihayashifoundation__2 --no-tablespaces --skip-lock-tables" > "$temp_file" 2>/dev/null
            if [ $? -ne 0 ]; then
                echo "Error: Failed to export production database"
                return 1
            fi

            echo "Importing production database..."
            # Import using direct MySQL command
            "$MYSQL_PATH" "${MYSQL_OPTS[@]}" "$DB_NAME" < "$temp_file" 2>/dev/null
            if [ $? -ne 0 ]; then
                echo "Error: Failed to import production database"
                rm -f "$temp_file"
                return 1
            fi

            echo "Updating URLs..."
            # Use direct MySQL command for search-replace
            cat > "${BACKUP_DIR}/update_urls.sql" << EOF
UPDATE wp_options SET option_value = replace(option_value, 'https://masumihayashifoundation.org', 'https://masumihayashifoundationorg.local') WHERE option_name = 'home' OR option_name = 'siteurl';
UPDATE wp_posts SET guid = replace(guid, 'https://masumihayashifoundation.org', 'https://masumihayashifoundationorg.local');
UPDATE wp_posts SET post_content = replace(post_content, 'https://masumihayashifoundation.org', 'https://masumihayashifoundationorg.local');
UPDATE wp_postmeta SET meta_value = replace(meta_value, 'https://masumihayashifoundation.org', 'https://masumihayashifoundationorg.local');
EOF

            "$MYSQL_PATH" "${MYSQL_OPTS[@]}" "$DB_NAME" < "${BACKUP_DIR}/update_urls.sql" 2>/dev/null
            if [ $? -ne 0 ]; then
                echo "Error: Failed to update URLs"
                rm -f "$temp_file" "${BACKUP_DIR}/update_urls.sql"
                return 1
            fi

            # Cleanup
            rm -f "$temp_file" "${BACKUP_DIR}/update_urls.sql"
            echo "Successfully pulled and imported production database"
        else
            echo "[DRY RUN] Would pull from production"
            echo "[DRY RUN] Would update URLs from production to local"
        fi
    fi

    return 0
}

# Perform the sync based on mode
echo "Starting WordPress database sync..."
if [ "$MODE" = "pull" ]; then
    echo "Pulling database from production to local..."
    db_operation "pull" "@prod" "@local" "$PROD_URL" "$LOCAL_URL"
else
    echo "Pushing database to production..."
    db_operation "push" "@local" "@prod" "$LOCAL_URL" "$PROD_URL"
fi

echo "Database sync completed!"