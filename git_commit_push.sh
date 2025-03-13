#!/bin/bash

# Add all changes
git add .

# Commit with timestamp
git commit -m "Auto-commit: $(date '+%Y-%m-%d %H:%M:%S')"

# Push changes
git push 