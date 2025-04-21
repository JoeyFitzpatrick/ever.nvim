#!/bin/bash

# Path to the configuration file
CONFIG_FILE="lua/ever/_core/default_configuration.lua"
README_FILE="README.md"
DOC_FILE="doc/ever.md"

# Check if the configuration file exists
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Configuration file not found: $CONFIG_FILE"
    exit 1
fi

# Function to update a file with the configuration block
update_file() {
    local target_file="$1"
    
    # Check if the target file exists
    if [ ! -f "$target_file" ]; then
        echo "Target file not found: $target_file"
        return 1
    fi

    # Extract the configuration block from after 'return {' to the closing '}'
    # Then add 8 spaces of indentation to each line
    config_block=$(awk '/return {/{flag=1; next} /^}$/{flag=0} flag' "$CONFIG_FILE" | sed 's/^/        /')
    
    # If no config block found, exit
    if [ -z "$config_block" ]; then
        echo "No configuration block found in $CONFIG_FILE"
        return 1
    fi

    # Create a temporary file
    temp_file=$(mktemp)

    # Process the target file
    awk '
    BEGIN { in_config_block = 0; }
    /-- Default configuration/ { in_config_block = 1; print; next; }
    /-- End of default configuration/ { in_config_block = 0; print; next; }
    !in_config_block { print; }
    ' "$target_file" > "$temp_file"

    # Insert the new configuration block
    sed -i "/-- Default configuration/r /dev/stdin" "$temp_file" <<<"$config_block"

    # Replace the original file
    mv "$temp_file" "$target_file"
}

# Update both files
update_file "$README_FILE"
update_file "$DOC_FILE"

# Stage the modified files
git add "$README_FILE" "$DOC_FILE"

exit 0
