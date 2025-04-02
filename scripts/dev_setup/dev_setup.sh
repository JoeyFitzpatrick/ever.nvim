#!/bin/bash

# Script to set up the pre-commit hook

# Define the path to the pre-commit hook
HOOK_PATH=".git/hooks/pre-commit"
# Define the path to the pre-commit hook content file
HOOK_CONTENT_FILE="scripts/dev_setup/pre_commit_hook_content.sh"

# Function to check if a command is available
check_command() {
    if ! command -v "$1" &> /dev/null; then
        echo "Error: $1 is not installed or not in the PATH."
        exit 1
    fi
}

# List of required dependencies
DEPENDENCIES=(
    "busted"
    "luacheck"
)

# Check if the .git directory exists
if [ ! -d ".git" ]; then
    echo "Error: This script must be run from the root of a Git repository."
    exit 1
fi

# Check for required dependencies
for dep in "${DEPENDENCIES[@]}"; do
    check_command "$dep"
done

# Check if the hook content file exists
if [ ! -f "$HOOK_CONTENT_FILE" ]; then
    echo "Error: Hook content file '$HOOK_CONTENT_FILE' not found."
    exit 1
fi

# Create the hooks directory if it doesn't exist
mkdir -p ".git/hooks"

# Copy the content of the hook file
cp "$HOOK_CONTENT_FILE" "$HOOK_PATH"

# Make the hook executable
chmod +x "$HOOK_PATH"

echo "Pre-commit hook has been set up successfully."
