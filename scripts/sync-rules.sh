#!/bin/bash
set -euo pipefail

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Function to log messages with timestamp
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

# Change to repository directory
cd "$REPO_DIR"

# Fetch latest changes
log "Fetching latest changes from remote repository..."
git fetch origin "$REPO_BRANCH"

# Check if we need to pull
LOCAL=$(git rev-parse HEAD)
REMOTE=$(git rev-parse origin/"$REPO_BRANCH")

if [ "$LOCAL" != "$REMOTE" ]; then
    log "Updates found, pulling changes..."
    git pull origin "$REPO_BRANCH"
    log "Successfully updated to latest version"
else
    log "Already up to date"
fi

# Check for local changes
if [ -n "$(git status --porcelain)" ]; then
    log "Local changes detected:"
    git status --porcelain
    
    # Add all changes
    git add .
    
    # Commit changes
    git commit -m "Auto-sync: Local rules update $(date '+%Y-%m-%d %H:%M:%S')"
    
    # Push changes
    log "Pushing local changes to remote..."
    git push origin "$REPO_BRANCH"
    log "Successfully pushed changes"
fi

log "Sync completed successfully" 