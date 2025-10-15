#!/bin/bash

# Script to build eevis_flutter web version and copy to local visual directory

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

FLUTTER_PROJECT_DIR="$HOME/eevis_flutter"
TARGET_DIR="./visual"

echo -e "${BLUE}Building eevis_flutter web version...${NC}"

# Check if Flutter project exists
if [ ! -d "$FLUTTER_PROJECT_DIR" ]; then
    echo -e "${RED}Error: Flutter project directory not found at $FLUTTER_PROJECT_DIR${NC}"
    exit 1
fi

# Navigate to Flutter project
cd "$FLUTTER_PROJECT_DIR"

# Build Flutter web
echo -e "${BLUE}Running flutter build web with base-href /eevis/visual/...${NC}"
flutter build web --base-href /eevis/visual/

# Check if build was successful
if [ ! -d "$FLUTTER_PROJECT_DIR/build/web" ]; then
    echo -e "${RED}Error: Build failed - build/web directory not found${NC}"
    exit 1
fi

# Navigate back to eevis-go directory
cd -

# Create visual directory if it doesn't exist
if [ ! -d "$TARGET_DIR" ]; then
    echo -e "${BLUE}Creating $TARGET_DIR directory...${NC}"
    mkdir -p "$TARGET_DIR"
fi

# Remove old build if exists
if [ -d "$TARGET_DIR" ] && [ "$(ls -A $TARGET_DIR)" ]; then
    echo -e "${BLUE}Removing old build from $TARGET_DIR...${NC}"
    rm -rf "$TARGET_DIR"/*
fi

# Copy build to visual directory
echo -e "${BLUE}Copying build to $TARGET_DIR...${NC}"
cp -r "$FLUTTER_PROJECT_DIR/build/web/"* "$TARGET_DIR/"

# Patch index.html for better browser compatibility
echo -e "${BLUE}Patching index.html for browser compatibility...${NC}"
INDEX_FILE="$TARGET_DIR/index.html"

if [ -f "$INDEX_FILE" ]; then
    # Add cache control and browser compatibility meta tags
    sed -i '/<meta charset="UTF-8">/a\  <meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">\n  <meta http-equiv="Pragma" content="no-cache">\n  <meta http-equiv="Expires" content="0">\n  <meta name="viewport" content="width=device-width, initial-scale=1.0">' "$INDEX_FILE"
    
    echo -e "${GREEN}✓ Index.html patched for better browser compatibility${NC}"
else
    echo -e "${RED}Warning: index.html not found at $INDEX_FILE${NC}"
fi

echo -e "${GREEN}✓ Build complete! Flutter web app copied to $TARGET_DIR${NC}"
