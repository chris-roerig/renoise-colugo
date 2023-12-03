#!/bin/bash

# Check if the tool name is provided as an argument
if [ -z "$1" ]; then
   echo "Error: Tool name not provided."
   echo "Usage: ./package_tool.sh ToolName"
   exit 1
fi

# Define the tool's name from the first argument
TOOL_NAME=$1

# Define the author's identifier (change 'com.author' to your identifier)
AUTHOR_IDENTIFIER="com.jugwine"

# Define source and destination directories
SRC_DIR="src"
BIN_DIR="bin"

# Get current Unix time
UNIX_TIME=$(date +%s)

# Define the output file name
# Format: com.author.ToolName.xrnx
OUTPUT_FILE="${AUTHOR_IDENTIFIER}.${UNIX_TIME}-${TOOL_NAME}"

# Navigate to the parent directory of src and bin
cd "$(dirname "$0")"

# Package the src directory into a .xrnx file and move it to the bin directory
zip -r "$BIN_DIR/$OUTPUT_FILE.zip" "$SRC_DIR" 
mv "$BIN_DIR/$OUTPUT_FILE.zip" "$BIN_DIR/$OUTPUT_FILE.xrnx"

# Confirm completion
echo "Tool packaged as $BIN_DIR/$OUTPUT_FILE.xrnx"

