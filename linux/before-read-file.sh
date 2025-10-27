#!/bin/bash

# Hook: beforeReadFile
# This hook runs before the agent reads a file
# Input: JSON with file_path, content, and attachments
# Output: JSON with permission: "allow" | "deny"

# Read the JSON input from stdin
input=$(cat)

# Extract the file path from the input
file_path=$(echo "$input" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/')

# Get workspace root
workspace_root=$(echo "$input" | grep -o '"workspace_roots"[[:space:]]*:[[:space:]]*\[[[:space:]]*"[^"]*"' | sed 's/.*"\([^"]*\)"$/\1/')

# Periodic cleanup: Run cleanup once per day (in background to not slow down reads)
if [ -n "$workspace_root" ]; then
    dontouch_dir="$workspace_root/.dontouch"
    cleanup_marker="$dontouch_dir/.last_cleanup"
    
    # Check if cleanup is needed (older than 24 hours or never run)
    if [ ! -f "$cleanup_marker" ] || [ $(find "$cleanup_marker" -mtime +1 2>/dev/null | wc -l) -gt 0 ]; then
        # Run cleanup in background to not block the read operation
        SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        if [ -f "$SCRIPT_DIR/cleanup-backups.sh" ]; then
            (
                "$SCRIPT_DIR/cleanup-backups.sh" "$workspace_root" > /dev/null 2>&1
                touch "$cleanup_marker"
            ) &
        fi
    fi
fi

# Read the actual file if it exists to check first 2 lines (for shebang)
if [ -f "$file_path" ]; then
    first_two_lines=$(head -n 2 "$file_path")
    
    # Check if first 2 lines contain "dontouch" or common typos (case insensitive)
    # Matches: DONTOUCH, DONTTOUCH, DON'TOUCH, DON'TTOUCH
    if echo "$first_two_lines" | grep -qiE "don'?t?touch"; then
        # Create .dontouch folder in workspace root
        dontouch_dir="$workspace_root/.dontouch"
        mkdir -p "$dontouch_dir"
        
        # Create hash of the file path for unique filename (Linux uses md5sum)
        file_hash=$(echo -n "$file_path" | md5sum | cut -d' ' -f1)
        
        # Copy the file to .dontouch folder
        cp "$file_path" "$dontouch_dir/$file_hash"
    fi
fi

# Always allow the operation
echo '{"permission":"allow"}'
exit 0

