#!/bin/bash
set -euo pipefail

# Default configuration
# Repository settings
REPO_NAME="cursor-rules"
GITHUB_USER="shepner"
REPO_BRANCH="main"

# Directory paths
BASE_DIR="$HOME/src"
LAUNCH_AGENTS_DIR="$HOME/Library/LaunchAgents"
LOGS_DIR="$HOME/Library/Logs"
BACKUP_DIR="$HOME/.cursor-rules-backup"

# LaunchAgent settings
SYNC_INTERVAL="1800"  # 30 minutes in seconds
DAILY_SYNC_HOUR="4"
DAILY_SYNC_MINUTE="0"

# Shell configuration
SHELL_RC_FILE="$HOME/.zshrc"
SHELL_PROFILE="$HOME/.zprofile"

# Load custom configuration if exists
CONFIG_FILE="$HOME/.cursor-rules-config"
if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
fi

# Derived configurations
REPO_URL="https://github.com/${GITHUB_USER}/${REPO_NAME}.git"
REPO_DIR="${BASE_DIR}/${REPO_NAME}"
LAUNCH_AGENT_NAME="com.${GITHUB_USER}.${REPO_NAME}-sync"
LAUNCH_AGENT_PLIST="${LAUNCH_AGENTS_DIR}/${LAUNCH_AGENT_NAME}.plist"

# Utility functions
info() { echo -e "\033[0;34m[INFO]\033[0m $1"; }
success() { echo -e "\033[0;32m[SUCCESS]\033[0m $1"; }
warn() { echo -e "\033[0;33m[WARNING]\033[0m $1"; }
error() { echo -e "\033[0;31m[ERROR]\033[0m $1" >&2; }

# Check if command exists
check_command() {
    if ! command -v "$1" &> /dev/null; then
        error "$1 is required but not installed."
        return 1
    fi
    return 0
}

# Create backup of a file
backup_file() {
    local file="$1"
    local backup_dir="${BACKUP_DIR}/$(date +%Y%m%d_%H%M%S)"
    
    if [ -f "$file" ]; then
        mkdir -p "$backup_dir"
        cp "$file" "$backup_dir/"
        info "Backed up $file to $backup_dir"
    fi
}

# Restore backup of a file
restore_file() {
    local file="$1"
    local backup_dir="$2"
    
    if [ -f "$backup_dir/$(basename "$file")" ]; then
        cp "$backup_dir/$(basename "$file")" "$file"
        success "Restored $file from backup"
    else
        error "No backup found for $file in $backup_dir"
        return 1
    fi
}

# Check system compatibility
check_system() {
    # Check OS
    if [[ "$(uname)" != "Darwin" ]]; then
        error "This script is designed for macOS only"
        return 1
    fi
    
    # Check required commands
    local required_commands=("git" "launchctl" "sed" "rsync")
    for cmd in "${required_commands[@]}"; do
        if ! check_command "$cmd"; then
            return 1
        fi
    done
    
    return 0
}

# Export configuration
export_config() {
    # Create configuration directory if it doesn't exist
    mkdir -p "$(dirname "$CONFIG_FILE")"
    
    # Export current configuration
    {
        echo "# Cursor Rules Configuration"
        echo "# Generated on $(date)"
        echo
        # Export all variables that don't start with _ or aren't internal bash variables
        compgen -v | grep -v '^_' | grep -v '^BASH' | while read -r var; do
            if [ -n "${!var+x}" ]; then
                echo "$var=\"${!var}\""
            fi
        done
    } > "$CONFIG_FILE"
    
    success "Configuration exported to $CONFIG_FILE"
}

# Print current configuration
print_config() {
    echo "Current Configuration:"
    echo "---------------------"
    echo "REPO_NAME = $REPO_NAME"
    echo "GITHUB_USER = $GITHUB_USER"
    echo "REPO_BRANCH = $REPO_BRANCH"
    echo "BASE_DIR = $BASE_DIR"
    echo "LAUNCH_AGENTS_DIR = $LAUNCH_AGENTS_DIR"
    echo "LOGS_DIR = $LOGS_DIR"
    echo "BACKUP_DIR = $BACKUP_DIR"
    echo "SYNC_INTERVAL = $SYNC_INTERVAL"
    echo "DAILY_SYNC_HOUR = $DAILY_SYNC_HOUR"
    echo "DAILY_SYNC_MINUTE = $DAILY_SYNC_MINUTE"
    echo "SHELL_RC_FILE = $SHELL_RC_FILE"
    echo "SHELL_PROFILE = $SHELL_PROFILE"
    echo "REPO_URL = $REPO_URL"
    echo "REPO_DIR = $REPO_DIR"
    echo "LAUNCH_AGENT_NAME = $LAUNCH_AGENT_NAME"
    echo "LAUNCH_AGENT_PLIST = $LAUNCH_AGENT_PLIST"
}

# Validate configuration
validate_config() {
    # Check required directories
    for dir in "$BASE_DIR" "$LAUNCH_AGENTS_DIR" "$LOGS_DIR"; do
        if [ ! -d "$dir" ]; then
            if [ ! -w "$(dirname "$dir")" ]; then
                error "Directory $dir is not writable"
                return 1
            fi
        fi
    done
    
    # Validate numeric values
    if ! [[ "$SYNC_INTERVAL" =~ ^[0-9]+$ ]]; then
        error "SYNC_INTERVAL must be a number"
        return 1
    fi
    
    if ! [[ "$DAILY_SYNC_HOUR" =~ ^[0-9]+$ ]]; then
        error "DAILY_SYNC_HOUR must be a number"
        return 1
    fi
    
    if [ "$DAILY_SYNC_HOUR" -lt 0 ] || [ "$DAILY_SYNC_HOUR" -gt 23 ]; then
        error "DAILY_SYNC_HOUR must be between 0 and 23"
        return 1
    fi
    
    if ! [[ "$DAILY_SYNC_MINUTE" =~ ^[0-9]+$ ]]; then
        error "DAILY_SYNC_MINUTE must be a number"
        return 1
    fi
    
    if [ "$DAILY_SYNC_MINUTE" -lt 0 ] || [ "$DAILY_SYNC_MINUTE" -gt 59 ]; then
        error "DAILY_SYNC_MINUTE must be between 0 and 59"
        return 1
    fi
    
    return 0
}

# If this script is run directly, print configuration
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    print_config
fi 