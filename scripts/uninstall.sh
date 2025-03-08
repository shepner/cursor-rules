#!/bin/bash
set -euo pipefail

# Load configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/config.sh"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --config=*)
            custom_config="${1#*=}"
            if [ -f "$custom_config" ]; then
                source "$custom_config"
            else
                error "Configuration file not found: $custom_config"
                exit 1
            fi
            ;;
        --keep-config)
            KEEP_CONFIG=1
            ;;
        --keep-backups)
            KEEP_BACKUPS=1
            ;;
        --force)
            FORCE=1
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo
            echo "Options:"
            echo "  --config=FILE     Use custom configuration file"
            echo "  --keep-config     Don't remove configuration file"
            echo "  --keep-backups    Don't remove backup files"
            echo "  --force           Skip confirmation prompts"
            echo "  --help            Show this help message"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

# Confirm uninstallation unless --force is used
if [ "${FORCE:-0}" != "1" ]; then
    read -p "Are you sure you want to uninstall Cursor Rules? (y/N) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Unload and remove LaunchAgent
if launchctl list "${CONFIG[LAUNCH_AGENT_NAME]}" &> /dev/null; then
    info "Unloading LaunchAgent..."
    launchctl unload "${CONFIG[LAUNCH_AGENT_PLIST]}"
fi

if [ -f "${CONFIG[LAUNCH_AGENT_PLIST]}" ]; then
    info "Removing LaunchAgent plist..."
    rm "${CONFIG[LAUNCH_AGENT_PLIST]}"
fi

# Remove log files
info "Cleaning up log files..."
rm -f "${CONFIG[LOGS_DIR]}/cursor-rules-sync.log"
rm -f "${CONFIG[LOGS_DIR]}/cursor-rules-sync.error.log"

# Remove environment variables from shell config
if [ -f "${CONFIG[SHELL_RC_FILE]}" ]; then
    info "Removing environment variables from ${CONFIG[SHELL_RC_FILE]}..."
    TMP_FILE=$(mktemp)
    sed '/# Cursor Rules Configuration/,+2d' "${CONFIG[SHELL_RC_FILE]}" > "$TMP_FILE"
    mv "$TMP_FILE" "${CONFIG[SHELL_RC_FILE]}"
fi

# Remove configuration file unless --keep-config is specified
if [ "${KEEP_CONFIG:-0}" != "1" ] && [ -f "$CONFIG_FILE" ]; then
    info "Removing configuration file..."
    rm "$CONFIG_FILE"
fi

# Remove backup files unless --keep-backups is specified
if [ "${KEEP_BACKUPS:-0}" != "1" ] && [ -d "${CONFIG[BACKUP_DIR]}" ]; then
    info "Removing backup files..."
    rm -rf "${CONFIG[BACKUP_DIR]}"
fi

# Optionally remove repository
if [ "${FORCE:-0}" != "1" ]; then
    read -p "Do you want to remove the local repository? (y/N) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        REMOVE_REPO=1
    fi
fi

if [ "${REMOVE_REPO:-0}" = "1" ] || [ "${FORCE:-0}" = "1" ]; then
    if [ -d "${CONFIG[REPO_DIR]}" ]; then
        info "Removing repository..."
        rm -rf "${CONFIG[REPO_DIR]}"
    fi
fi

success "Uninstallation completed successfully!"
echo "Note: You may want to restart your terminal to ensure environment variables are cleared."

# Provide restore instructions
if [ "${KEEP_BACKUPS:-0}" = "1" ]; then
    echo
    echo "Backup files are preserved in: ${CONFIG[BACKUP_DIR]}"
    echo "To restore a backup, use:"
    echo "  ${CONFIG[REPO_DIR]}/scripts/restore.sh --backup-dir=BACKUP_DIR"
fi 