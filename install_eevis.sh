#!/bin/bash

# Script to compile and install EEVIS application to /var/www/html/eevis

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

INSTALL_DIR="/var/www/html/eevis"
SOURCE_DIR="$(pwd)"
BINARY_NAME="eevis-server"

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}  EEVIS Installation Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Check if running from correct directory
if [ ! -f "main.go" ]; then
    echo -e "${RED}Error: main.go not found. Please run this script from the eevis-go directory.${NC}"
    exit 1
fi

# Check if .env file exists
if [ ! -f ".env" ]; then
    echo -e "${RED}Error: .env file not found. Please create .env file before installation.${NC}"
    exit 1
fi

# Step 1: Build the Go application
echo -e "${BLUE}Step 1: Building Go application...${NC}"
go build -o "$BINARY_NAME" main.go

if [ ! -f "$BINARY_NAME" ]; then
    echo -e "${RED}Error: Build failed - $BINARY_NAME not found${NC}"
    exit 1
fi

echo -e "${GREEN}✓ Go application built successfully${NC}"
echo ""

# Step 2: Build Flutter web app
echo -e "${BLUE}Step 2: Building Flutter web application...${NC}"
if [ -f "./build_flutter.sh" ]; then
    ./build_flutter.sh
    if [ $? -ne 0 ]; then
        echo -e "${RED}Error: Flutter build failed${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Flutter web app built successfully${NC}"
else
    echo -e "${YELLOW}Warning: build_flutter.sh not found, skipping Flutter build${NC}"
    if [ ! -d "visual" ]; then
        echo -e "${RED}Error: visual/ directory not found and cannot build Flutter app${NC}"
        exit 1
    fi
fi
echo ""

# Step 3: Create installation directory (requires sudo)
echo -e "${BLUE}Step 3: Creating installation directory...${NC}"
sudo mkdir -p "$INSTALL_DIR"
sudo chown $USER:$USER "$INSTALL_DIR"
echo -e "${GREEN}✓ Installation directory created: $INSTALL_DIR${NC}"
echo ""

# Step 4: Copy binary
echo -e "${BLUE}Step 4: Installing binary...${NC}"
cp "$BINARY_NAME" "$INSTALL_DIR/"
chmod +x "$INSTALL_DIR/$BINARY_NAME"
echo -e "${GREEN}✓ Binary installed to $INSTALL_DIR/$BINARY_NAME${NC}"
echo ""

# Step 5: Copy template files
echo -e "${BLUE}Step 5: Installing template files...${NC}"
if [ -d "eevis" ]; then
    cp -r eevis "$INSTALL_DIR/"
    echo -e "${GREEN}✓ Template files (eevis/) copied${NC}"
else
    echo -e "${YELLOW}Warning: eevis/ directory not found${NC}"
fi
echo ""

# Step 6: Copy Flutter web app
echo -e "${BLUE}Step 6: Installing Flutter web app...${NC}"
if [ -d "visual" ]; then
    cp -r visual "$INSTALL_DIR/"
    echo -e "${GREEN}✓ Flutter web app (visual/) copied${NC}"
else
    echo -e "${YELLOW}Warning: visual/ directory not found${NC}"
fi
echo ""

# Step 7: Copy .env file
echo -e "${BLUE}Step 7: Installing configuration...${NC}"
cp .env "$INSTALL_DIR/.env"
chmod 600 "$INSTALL_DIR/.env"  # Secure permissions for .env
echo -e "${GREEN}✓ Configuration file (.env) copied${NC}"
echo ""

# Step 8: Copy TLS certificates if they exist
echo -e "${BLUE}Step 8: Checking for TLS certificates...${NC}"
if [ -f "server.crt" ] && [ -f "server.key" ]; then
    cp server.crt "$INSTALL_DIR/"
    cp server.key "$INSTALL_DIR/"
    chmod 600 "$INSTALL_DIR/server.key"  # Secure permissions for private key
    echo -e "${GREEN}✓ TLS certificates copied${NC}"
else
    echo -e "${YELLOW}Note: TLS certificates not found (server.crt, server.key)${NC}"
    echo -e "${YELLOW}      If you plan to use HTTPS, add certificates to $INSTALL_DIR${NC}"
fi
echo ""

# Step 9: Create systemd service file (optional)
echo -e "${BLUE}Step 9: Creating systemd service file...${NC}"
sudo tee /etc/systemd/system/eevis.service > /dev/null << EOF
[Unit]
Description=EEVIS Server
After=network.target mysql.service
Wants=mysql.service

[Service]
Type=simple
User=$USER
WorkingDirectory=$INSTALL_DIR
ExecStart=$INSTALL_DIR/$BINARY_NAME
Restart=on-failure
RestartSec=5s

# Security settings
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=$INSTALL_DIR

# Logging
StandardOutput=journal
StandardError=journal
SyslogIdentifier=eevis

[Install]
WantedBy=multi-user.target
EOF

echo -e "${GREEN}✓ Systemd service file created: /etc/systemd/system/eevis.service${NC}"
echo ""

# Step 10: Reload systemd
echo -e "${BLUE}Step 10: Reloading systemd...${NC}"
sudo systemctl daemon-reload
echo -e "${GREEN}✓ Systemd reloaded${NC}"
echo ""

# Installation summary
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "Installation directory: ${BLUE}$INSTALL_DIR${NC}"
echo ""
echo -e "Installed files:"
echo -e "  - ${BLUE}$INSTALL_DIR/$BINARY_NAME${NC} (executable)"
echo -e "  - ${BLUE}$INSTALL_DIR/.env${NC} (configuration)"
echo -e "  - ${BLUE}$INSTALL_DIR/eevis/${NC} (templates)"
echo -e "  - ${BLUE}$INSTALL_DIR/visual/${NC} (Flutter web app)"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo ""
echo -e "1. ${BLUE}Start the service:${NC}"
echo -e "   sudo systemctl start eevis"
echo ""
echo -e "2. ${BLUE}Enable auto-start on boot:${NC}"
echo -e "   sudo systemctl enable eevis"
echo ""
echo -e "3. ${BLUE}Check service status:${NC}"
echo -e "   sudo systemctl status eevis"
echo ""
echo -e "4. ${BLUE}View logs:${NC}"
echo -e "   sudo journalctl -u eevis -f"
echo ""
echo -e "5. ${BLUE}Stop the service:${NC}"
echo -e "   sudo systemctl stop eevis"
echo ""
echo -e "${YELLOW}Manual start (for testing):${NC}"
echo -e "   cd $INSTALL_DIR && ./$BINARY_NAME"
echo ""
echo -e "${GREEN}Installation successful!${NC}"
