#!/bin/bash

echo "DONTOUCH Installer"
echo "=================="
echo ""

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Get the project root directory (parent of mac/)
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Check if hooks.json already exists
if [ -f ~/.cursor/hooks.json ]; then
    echo "⚠️  Existing hooks.json found at ~/.cursor/hooks.json"
    echo ""
    read -p "Overwrite existing hooks? (Y/n): " -n 1 -r
    echo ""
    
    if [[ ! $REPLY =~ ^[Yy]$ ]] && [[ ! -z $REPLY ]]; then
        echo "Installation cancelled"
        exit 0
    fi
    
    # Backup existing file
    BACKUP_FILE=~/.cursor/hooks.json.backup.$(date +%Y%m%d_%H%M%S)
    cp ~/.cursor/hooks.json "$BACKUP_FILE"
    echo "✓ Backed up existing hooks.json to: $BACKUP_FILE"
fi

# Ensure the .cursor directory exists
mkdir -p ~/.cursor

# Create a temporary file for the modified hooks.json
TEMP_FILE=$(mktemp)

# Read the hooks.json and replace FOLDER placeholder with absolute path to mac folder
# Replace "FOLDER/" with "$SCRIPT_DIR/"
cat "$PROJECT_ROOT/hooks.json" | \
  sed "s|\"FOLDER/|\"$SCRIPT_DIR/|g" > "$TEMP_FILE"

# Copy the modified file to ~/.cursor/hooks.json
cp "$TEMP_FILE" ~/.cursor/hooks.json

# Clean up
rm "$TEMP_FILE"

echo "✓ Installation complete!"
echo "✓ hooks.json has been copied to ~/.cursor/hooks.json"
echo "✓ All command paths have been updated to absolute paths in mac folder"
echo ""
echo "Please restart Cursor for changes to take effect."

