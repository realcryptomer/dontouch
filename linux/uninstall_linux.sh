#!/bin/bash

echo "DONTOUCH Uninstaller (Linux)"
echo "============================"
echo ""

# Check if hooks.json exists
if [ ! -f ~/.cursor/hooks.json ]; then
    echo "✓ No hooks.json found - nothing to uninstall"
    exit 0
fi

echo "This will remove ~/.cursor/hooks.json"
echo ""
read -p "Continue? (Y/n): " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
    echo "Uninstall cancelled"
    exit 0
fi

# Backup the existing file before removing
BACKUP_FILE=~/.cursor/hooks.json.backup.$(date +%Y%m%d_%H%M%S)
cp ~/.cursor/hooks.json "$BACKUP_FILE"
echo "✓ Backed up existing hooks.json to: $BACKUP_FILE"

# Remove hooks.json
rm ~/.cursor/hooks.json
echo "✓ Removed ~/.cursor/hooks.json"

echo ""
echo "✓ Uninstall complete!"
echo "✓ Please restart Cursor for changes to take effect"
echo ""
echo "Note: .dontouch backup folders in your projects were NOT removed."
echo "You can safely delete them manually if needed."

