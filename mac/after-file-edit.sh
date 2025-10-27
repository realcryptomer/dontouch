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
        
        # Create hash of the file path
        file_hash=$(echo -n "$file_path" | md5 -r | cut -d' ' -f1)
        backup_file="$workspace_root/.dontouch/$file_hash"
        
        # Check if backup exists
        if [ -f "$backup_file" ]; then
            # Extract just the filename for display
            filename=$(basename "$file_path")
            
            # Show dialog asking if user wants to revert
            response=$(osascript -e "display dialog \"Cursor just changed a DONTOUCH file:\\n\\n$filename\\n\\nRevert changes?\" with title \"DONTOUCH Protection\" buttons {\"No\", \"Yes\"} default button \"Yes\"" 2>&1)
            
            # Check if user clicked Yes
            if echo "$response" | grep -q "Yes"; then
                # Revert the file
                cp "$backup_file" "$file_path"
                echo "{\"action\":\"reverted\",\"file\":\"$filename\"}"
            else
                # User clicked No (allowed the edit) - update the backup to this new approved version
                cp "$file_path" "$backup_file"
                echo "{\"action\":\"approved\",\"file\":\"$filename\"}"
            fi
        else
            # No backup available
            filename=$(basename "$file_path")
            osascript -e "display dialog \"Cursor just changed a DONTOUCH file:\\n\\n$filename\\n\\nWe do not have a copy to revert.\" with title \"DONTOUCH Protection\" buttons {\"OK\"} default button \"OK\" giving up after 5"
            echo "{\"action\":\"no_backup\",\"file\":\"$filename\"}"
        fi
        exit 0
    fi
fi

# Not a DONTOUCH file, no action needed
exit 0


