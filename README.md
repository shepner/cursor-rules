# Cursor Rules Repository

This repository contains my personal collection of Cursor rules for use across different projects.

## Structure

- `00-meta/`: Meta rules for managing and organizing other rules
- `10-code/`: Rules for code organization and standards
- `20-dependencies/`: Rules for dependency management

## Usage

1. Clone this repository
2. Set environment variables:
   ```bash
   export CURSOR_RULES_REPO="your-username/cursor-rules"
   export CURSOR_RULES_BRANCH="main"
   ```
3. The rules will automatically sync with your projects

## Automatic Synchronization

This repository automatically:
- Syncs every 30 minutes
- Performs a full sync daily at 4 AM
- Syncs immediately when files change
- Retries failed operations up to 3 times

You can monitor sync operations in:
```bash
~/Library/Logs/cursor-rules-sync.log
~/Library/Logs/cursor-rules-sync.error.log
```

## License

Copyright (c) 2024. All rights reserved. 