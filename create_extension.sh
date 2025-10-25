#!/bin/bash

# Navigate to the script's directory
cd "$(dirname "$0")"

# Read the current version from package.json
if [ -f "package.json" ]; then
    CURRENT_VERSION=$(grep -o '\"version\"\\s*:\\s*\"[^\"]*\"' package.json | grep -o '[0-9][^\"]*')
    echo "Current version: $CURRENT_VERSION"
    read -p "Enter new version (leave empty to keep $CURRENT_VERSION): " NEW_VERSION
    if [ -z "$NEW_VERSION" ]; then
        NEW_VERSION=$CURRENT_VERSION
        echo "Keeping version $NEW_VERSION"
    else
        echo "Updating to version $NEW_VERSION"
        sed -i "s/\\\"version\\\"[[:space:]]*:[[:space:]]*\\\"[^\\\"]*\\\"/\\\"version\\\": \\\"$NEW_VERSION\\\"/" package.json
    fi
else
    echo "Warning: package.json not found, version information unavailable"
fi

EXTENSION_NAME="AseVoxel-Viewer"

# Delete previous extension if it exists
if [ -f "$EXTENSION_NAME.aseprite-extension" ]; then
    echo "Deleting existing $EXTENSION_NAME.aseprite-extension..."
    rm "$EXTENSION_NAME.aseprite-extension"
fi

# Create a new zip archive with Lua files and binary libraries (include fx folder)
echo "Creating $EXTENSION_NAME.zip..."
zip -r "$EXTENSION_NAME.zip" *.lua *.json bin *.so *.dll lib core dialog render utils fx native

# Rename the .zip file to .aseprite-extension
echo "Renaming $EXTENSION_NAME.zip to $EXTENSION_NAME.aseprite-extension..."
mv "$EXTENSION_NAME.zip" "$EXTENSION_NAME.aseprite-extension"

# Make the file executable
chmod +x "$EXTENSION_NAME.aseprite-extension"

echo "$EXTENSION_NAME.aseprite-extension created successfully!"