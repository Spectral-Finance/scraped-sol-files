#!/bin/bash

# Define the source directory to search for .sol files
# You can change this to the specific folder you want to search in
SOURCE_DIR="./"

# Define the target directory where .sol files will be moved
TARGET_DIR="../scraped-sols"

# Create the target directory if it does not exist
mkdir -p "$TARGET_DIR"

# Find and move .sol files to the target directory
find "$SOURCE_DIR" -type f -name "*.sol" -exec mv {} "$TARGET_DIR" \;

echo "All .sol files have been moved to $TARGET_DIR"
