#!/bin/bash

# Cleanup script for .dontouch backups
# This script removes backups for files that no longer exist

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="${1:-$(pwd)}"
DONTOUCH_DIR="$WORKSPACE_ROOT/.dontouch"

if [ ! -d "$DONTOUCH_DIR" ]; then
    echo "No .dontouch directory found in $WORKSPACE_ROOT"
    exit 0
fi

echo "Checking for orphaned backups in $DONTOUCH_DIR..."

removed_count=0
kept_count=0

# We need to check each backup, but we can't easily reverse the MD5 hash
# So we'll look for all files in the workspace and check if their backups exist
# Then remove any backups that don't have corresponding source files

# Store all current file hashes
current_hashes=()
while IFS= read -r -d '' file; do
    # Skip the .dontouch directory itself
    if [[ "$file" == *"/.dontouch/"* ]]; then
        continue
    fi
    
    # Check if first 2 lines contain DONTOUCH or common typos
    if [ -f "$file" ]; then
        first_two_lines=$(head -n 2 "$file" 2>/dev/null)
        if echo "$first_two_lines" | grep -qiE "don'?t?touch"; then
            file_hash=$(echo -n "$file" | md5 -r | cut -d' ' -f1)
            current_hashes+=("$file_hash")
        fi
    fi
done < <(find "$WORKSPACE_ROOT" -type f -print0)

echo "Found ${#current_hashes[@]} current DONTOUCH files"

# Now check all backups
for backup_file in "$DONTOUCH_DIR"/*; do
    if [ -f "$backup_file" ]; then
        backup_hash=$(basename "$backup_file")
        
        # Skip the cleanup marker file
        if [ "$backup_hash" = ".last_cleanup" ]; then
            continue
        fi
        
        # Check if this hash is in our current hashes
        found=false
        for current_hash in "${current_hashes[@]}"; do
            if [ "$current_hash" = "$backup_hash" ]; then
                found=true
                break
            fi
        done
        
        if [ "$found" = false ]; then
            # Orphaned backup - check if it's older than 1 week
            if [ $(find "$backup_file" -mtime +7 2>/dev/null | wc -l) -gt 0 ]; then
                echo "Removing orphaned backup (>1 week old): $backup_hash"
                rm "$backup_file"
                ((removed_count++))
            else
                echo "Keeping recent orphaned backup (<1 week old): $backup_hash"
                ((kept_count++))
            fi
        else
            ((kept_count++))
        fi
    fi
done

echo ""
echo "Cleanup complete!"
echo "- Kept: $kept_count backups"
echo "- Removed: $removed_count orphaned backups"

