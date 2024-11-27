#!/bin/bash

# Exit immediately if a command exits with a non-zero status
set -e

# Confirm the script is being run in a Git repository
if ! git rev-parse --is-inside-work-tree > /dev/null 2>&1; then
    echo "Error: This script must be run inside a Git repository."
    exit 1
fi

# Automatically clean untracked files and directories
git clean -fdx
echo "All non-tracking files and directories have been removed."