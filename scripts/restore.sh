#!/bin/bash
set -euo pipefail

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --backup-dir=*)
            BACKUP_DIR="${1#*=}"
            ;;
        --config=*)
            custom_config="${1#*=}"
            if [ -f "$custom_config" ]; then
                source "$custom_config"
            else
                error "Configuration file not found: $custom_config"
                exit 1
            fi
            ;;
        --force)
            FORCE=1
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo
            echo "Options:"
            echo "  --backup-dir=DIR   Specify backup directory to restore from"
            echo "  --config=FILE      Use custom configuration file"
            echo "  --force            Skip confirmation prompts"
            echo "  --help             Show this help message"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

# Check if backup directory is specified
if [ -z "${BACKUP_DIR:-}" ]; then
    # List available backups
    echo "Available backups:"
    echo "-----------------"
    if [ -d "${CONFIG[BACKUP_DIR]}" ]; then
        ls -1t "${CONFIG[BACKUP_DIR]}"
        echo
        echo "Please specify a backup directory using --backup-dir=DIR"
    else
        error "No backups found in ${CONFIG[BACKUP_DIR]}"
        exit 1
    fi
    exit 0
fi

# Verify backup directory exists
if [ ! -d "$BACKUP_DIR" ]; then
    error "Backup directory not found: $BACKUP_DIR"
    exit 1
fi

# List files in backup
echo "Files in backup:"
ls -1 "$BACKUP_DIR"
echo

# Confirm restore unless --force is used
if [ "${FORCE:-0}" != "1" ]; then
    read -p "Are you sure you want to restore these files? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Unload LaunchAgent if it exists
if launchctl list "${CONFIG[LAUNCH_AGENT_NAME]}" &> /dev/null; then
    info "Unloading LaunchAgent..."
    launchctl unload "${CONFIG[LAUNCH_AGENT_PLIST]}"
fi

# Restore files
info "Restoring files..."
for file in "$BACKUP_DIR"/*; do
    if [ -f "$file" ]; then
        basename=$(basename "$file")
        case "$basename" in
            *.plist)
                target="${CONFIG[LAUNCH_AGENT_PLIST]}"
                ;;
            .zshrc)
                target="${CONFIG[SHELL_RC_FILE]}"
                ;;
            *)
                warn "Unknown file type: $basename"
                continue
                ;;
        esac
        
        info "Restoring $basename..."
        cp "$file" "$target"
    fi
done

# Reload LaunchAgent
info "Reloading LaunchAgent..."
if [ -f "${CONFIG[LAUNCH_AGENT_PLIST]}" ]; then
    launchctl load "${CONFIG[LAUNCH_AGENT_PLIST]}"
fi

# Source shell configuration
if [ -f "${CONFIG[SHELL_RC_FILE]}" ]; then
    info "Reloading shell configuration..."
    source "${CONFIG[SHELL_RC_FILE]}"
fi

success "Restore completed successfully!"
echo "You may want to restart your terminal for all changes to take effect." 