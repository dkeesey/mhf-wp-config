#!/bin/bash

# WordPress Theme Sync Script

# The script is essentially identical to the plugin sync script, but with paths and messages specific to themes.
# Usage examples:

# Pull themes (default): ./wp-theme-sync.sh
# Push themes: ./wp-theme-sync.sh push

# Dry run pull: ./wp-theme-sync.sh -d
# Dry run push: ./wp-theme-sync.sh push -d

# Key considerations:

# This script will sync entire theme directories
# Be cautious when pushing, as it will overwrite themes on the production server
# Always test with a dry run first
# Ensure you have necessary permissions

# Configuration - MODIFY THESE PATHS
REMOTE_USER="wp_jqukgi"
REMOTE_HOST="masumihayashifoundation"
REMOTE_THEMES_PATH="/home/wp_jqukgi/masumihayashifoundation.org/wp-content/themes/"
LOCAL_THEMES_PATH="/Volumes/PRO-G40/Workspace-G40/wp-masumihayashifoundation.org-new/app/public/wp-content/themes/"

# Function to display usage information
usage() {
    echo "WordPress Theme Sync Script"
    echo "Usage: $0 [options]"
    echo "Options:"
    echo "  pull               Sync themes from production to local (default)"
    echo "  push               Sync themes from local to production"
    echo "  -d, --dry-run      Perform a dry run (show what would be transferred)"
    echo "  -h, --help         Show this help message"
    exit 1
}

# Default mode
MODE="pull"
# Default to actual sync
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
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown option: $1"
            usage
            ;;
    esac
done

# Perform the rsync based on mode
echo "Starting WordPress theme sync..."
if [ "$MODE" == "pull" ]; then
    echo "Pulling themes from production to local..."
    rsync -avz -e ssh $DRY_RUN "$REMOTE_USER@$REMOTE_HOST:$REMOTE_THEMES_PATH" "$LOCAL_THEMES_PATH"
else
    echo "Pushing themes from local to production..."
    rsync -avz -e ssh $DRY_RUN "$LOCAL_THEMES_PATH" "$REMOTE_USER@$REMOTE_HOST:$REMOTE_THEMES_PATH"
fi

# Check the exit status of rsync
if [ $? -eq 0 ]; then
    echo "Theme sync completed successfully!"
else
    echo "Theme sync encountered an error."
    exit 1
fi