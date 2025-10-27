#!/bin/bash

# Hook: afterFileEdit
# This hook runs after the agent edits a file
# Input: JSON with file_path, edits, and other metadata
# Output: None required (this is an observational hook)

# Read the JSON input from stdin
input=$(cat)

# Extract file_path from JSON
file_path=$(echo "$input" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/')

# Check if file exists and read its first 2 lines (for shebang)
if [ -f "$file_path" ]; then
    first_two_lines=$(head -n 2 "$file_path")
    
    # Check if first 2 lines contain "dontouch" or common typos (case insensitive)
    # Matches: DONTOUCH, DONTTOUCH, DON'TOUCH, DON'TTOUCH
    if echo "$first_two_lines" | grep -qiE "don'?t?touch"; then
        # Get workspace root
        workspace_root=$(echo "$input" | grep -o '"workspace_roots"[[:space:]]*:[[:space:]]*\[[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/')
        
        # Create hash of the file path (Linux uses md5sum)
        file_hash=$(echo -n "$file_path" | md5sum | cut -d' ' -f1)
        backup_file="$workspace_root/.dontouch/$file_hash"
        
        # Check if backup exists
        if [ -f "$backup_file" ]; then
            # Extract just the filename for display
            filename=$(basename "$file_path")
            
            # Show dialog asking if user wants to revert (using zenity for Linux)
            if command -v zenity &> /dev/null; then
                zenity --question \
                    --title="DONTOUCH Protection" \
                    --text="Cursor just changed a DONTOUCH file:\n\n$filename\n\nRevert changes?" \
                    --default-cancel \
                    --ok-label="Yes" \
                    --cancel-label="No" \
                    2>/dev/null
                
                if [ $? -eq 0 ]; then
                    # User clicked Yes - revert
                    cp "$backup_file" "$file_path"
                    echo "{\"action\":\"reverted\",\"file\":\"$filename\"}"
                else
                    # User clicked No - update backup
                    cp "$file_path" "$backup_file"
                    echo "{\"action\":\"approved\",\"file\":\"$filename\"}"
                fi
            else
                # Fallback if zenity not available - use basic dialog
                read -p "Cursor changed DONTOUCH file: $filename. Revert? (y/N): " -n 1 -r
                echo ""
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    cp "$backup_file" "$file_path"
                    echo "{\"action\":\"reverted\",\"file\":\"$filename\"}"
                else
                    cp "$file_path" "$backup_file"
                    echo "{\"action\":\"approved\",\"file\":\"$filename\"}"
                fi
            fi
        else
            # No backup available
            filename=$(basename "$file_path")
            if command -v zenity &> /dev/null; then
                zenity --warning \
                    --title="DONTOUCH Protection" \
                    --text="Cursor just changed a DONTOUCH file:\n\n$filename\n\nWe do not have a copy to revert." \
                    --timeout=5 \
                    2>/dev/null
            fi
            echo "{\"action\":\"no_backup\",\"file\":\"$filename\"}"
        fi
        exit 0
    fi
fi

# Not a DONTOUCH file, no action needed
exit 0

