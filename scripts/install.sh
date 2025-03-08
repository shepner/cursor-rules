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
        --no-backup)
            NO_BACKUP=1
            ;;
        --force)
            FORCE=1
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo
            echo "Options:"
            echo "  --config=FILE    Use custom configuration file"
            echo "  --no-backup      Skip creating backups"
            echo "  --force          Override system compatibility check"
            echo "  --help           Show this help message"
            exit 0
            ;;
        *)
            error "Unknown option: $1"
            exit 1
            ;;
    esac
    shift
done

# Check system compatibility
if [ "${FORCE:-0}" != "1" ]; then
    info "Checking system compatibility..."
    if ! check_system; then
        error "System compatibility check failed. Use --force to override."
        exit 1
    fi
fi

# Validate configuration
info "Validating configuration..."
if ! validate_config; then
    error "Configuration validation failed"
    exit 1
fi

# Create necessary directories
info "Creating directories..."
for dir in "${CONFIG[BASE_DIR]}" "${CONFIG[LAUNCH_AGENTS_DIR]}" "${CONFIG[LOGS_DIR]}"; do
    mkdir -p "$dir"
done

# Backup existing files if needed
if [ "${NO_BACKUP:-0}" != "1" ]; then
    info "Creating backups..."
    for file in "${CONFIG[SHELL_RC_FILE]}" "${CONFIG[LAUNCH_AGENT_PLIST]}"; do
        backup_file "$file"
    done
fi

# Clone or update repository
if [ ! -d "${CONFIG[REPO_DIR]}" ]; then
    info "Cloning repository..."
    git clone "${CONFIG[REPO_URL]}" "${CONFIG[REPO_DIR]}"
else
    info "Repository exists, updating..."
    cd "${CONFIG[REPO_DIR]}"
    git pull origin "${CONFIG[REPO_BRANCH]}"
fi

# Make scripts executable
info "Setting up scripts..."
chmod +x "${CONFIG[REPO_DIR]}/scripts/"*.sh

# Set up environment variables
info "Setting up environment variables..."
ENV_CONFIG="\n# Cursor Rules Configuration"
ENV_CONFIG+="\nexport CURSOR_RULES_REPO=\"${CONFIG[GITHUB_USER]}/${CONFIG[REPO_NAME]}\""
ENV_CONFIG+="\nexport CURSOR_RULES_BRANCH=\"${CONFIG[REPO_BRANCH]}\""

# Add to shell config if not already present
if ! grep -q "CURSOR_RULES_REPO" "${CONFIG[SHELL_RC_FILE]}"; then
    info "Adding environment variables to ${CONFIG[SHELL_RC_FILE]}..."
    echo -e "$ENV_CONFIG" >> "${CONFIG[SHELL_RC_FILE]}"
    source "${CONFIG[SHELL_RC_FILE]}"
fi

# Generate LaunchAgent plist
info "Generating LaunchAgent plist..."
cat > "${CONFIG[LAUNCH_AGENT_PLIST]}" << EOL
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${CONFIG[LAUNCH_AGENT_NAME]}</string>
    
    <key>ProgramArguments</key>
    <array>
        <string>${CONFIG[REPO_DIR]}/scripts/sync-rules.sh</string>
    </array>
    
    <key>StartInterval</key>
    <integer>${CONFIG[SYNC_INTERVAL]}</integer>
    
    <key>StandardOutPath</key>
    <string>${CONFIG[LOGS_DIR]}/cursor-rules-sync.log</string>
    
    <key>StandardErrorPath</key>
    <string>${CONFIG[LOGS_DIR]}/cursor-rules-sync.error.log</string>
    
    <key>EnvironmentVariables</key>
    <dict>
        <key>PATH</key>
        <string>/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin</string>
    </dict>
    
    <key>RunAtLoad</key>
    <true/>
    
    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>${CONFIG[DAILY_SYNC_HOUR]}</integer>
        <key>Minute</key>
        <integer>${CONFIG[DAILY_SYNC_MINUTE]}</integer>
    </dict>
</dict>
</plist>
EOL

# Unload existing LaunchAgent if it exists
if launchctl list "${CONFIG[LAUNCH_AGENT_NAME]}" &> /dev/null; then
    info "Unloading existing LaunchAgent..."
    launchctl unload "${CONFIG[LAUNCH_AGENT_PLIST]}"
fi

# Load LaunchAgent
info "Loading LaunchAgent..."
launchctl load "${CONFIG[LAUNCH_AGENT_PLIST]}"

# Verify installation
if launchctl list "${CONFIG[LAUNCH_AGENT_NAME]}" &> /dev/null; then
    success "Installation completed successfully!"
    echo
    echo "Configuration has been saved to: $CONFIG_FILE"
    echo "Logs will be available at:"
    echo "  ${CONFIG[LOGS_DIR]}/cursor-rules-sync.log"
    echo "  ${CONFIG[LOGS_DIR]}/cursor-rules-sync.error.log"
    echo
    echo "To customize settings, edit: $CONFIG_FILE"
    echo "To uninstall, run: ${CONFIG[REPO_DIR]}/scripts/uninstall.sh"
else
    error "LaunchAgent failed to load. Please check the configuration."
    exit 1
fi 