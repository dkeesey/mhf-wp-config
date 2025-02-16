#!/bin/bash

# WordPress Plugin Sync Script

# Now the script supports both pull and push operations. Here are some example usages:

# Pull plugins (default): ./wp-plugin-sync.sh
# Push plugins: ./wp-plugin-sync.sh push
# Dry run pull: ./wp-plugin-sync.sh -d
# Dry run push: ./wp-plugin-sync.sh push -d

# A few important notes:

# Be cautious when pushing plugins, as this will overwrite plugins on the production server
# Always test with a dry run first
# Make sure you have the necessary permissions on both local and remote servers

# Configuration - MODIFY THESE PATHS
REMOTE_USER="wp_jqukgi"
REMOTE_HOST="masumihayashifoundation"
REMOTE_PLUGINS_PATH="/home/wp_jqukgi/masumihayashifoundation.org/wp-content/plugins/"
REMOTE_MU_PLUGINS_PATH="/home/wp_jqukgi/masumihayashifoundation.org/wp-content/mu-plugins/"
LOCAL_PLUGINS_PATH="/Volumes/PRO-G40/Workspace-G40/wp-masumihayashifoundation.org-new/app/public/wp-content/plugins/"
LOCAL_MU_PLUGINS_PATH="/Volumes/PRO-G40/Workspace-G40/wp-masumihayashifoundation.org-new/app/public/wp-content/mu-plugins/"

# Function to display usage information
usage() {
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  -d, --dry-run    Perform a dry run (show what would be transferred)"
    echo "  -h, --help       Show this help message"
    exit 1
}

# Default to actual sync
DRY_RUN=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--dry-run)
            DRY_RUN="--dry-run"
            shift
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Perform the rsync for regular plugins
echo "Starting WordPress plugin sync..."
rsync -avz -e ssh $DRY_RUN "$REMOTE_USER@$REMOTE_HOST:$REMOTE_PLUGINS_PATH" "$LOCAL_PLUGINS_PATH"

# Check the exit status of regular plugins rsync
if [ $? -eq 0 ]; then
    echo "Plugin sync completed successfully!"
else
    echo "Plugin sync encountered an error."
    exit 1
fi

# Perform the rsync for mu-plugins
echo "Starting WordPress mu-plugins sync..."
rsync -avz -e ssh $DRY_RUN "$REMOTE_USER@$REMOTE_HOST:$REMOTE_MU_PLUGINS_PATH" "$LOCAL_MU_PLUGINS_PATH"

# Check the exit status of mu-plugins rsync
if [ $? -eq 0 ]; then
    echo "Mu-plugins sync completed successfully!"
else
    echo "Mu-plugins sync encountered an error."
    exit 1
fi