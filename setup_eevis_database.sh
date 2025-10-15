#!/bin/bash

# Script to create EEVIS database with the same schema as IRVIS
# This script will prompt for MySQL root password

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EEVIS Database Setup Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Prompt for MySQL root password
echo -e "${YELLOW}Please enter MySQL root password:${NC}"
read -s MYSQL_ROOT_PASSWORD
echo ""

# Test MySQL connection
echo -e "${BLUE}Testing MySQL connection...${NC}"
if ! mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SELECT 1;" > /dev/null 2>&1; then
    echo -e "${RED}Error: Failed to connect to MySQL. Please check your password.${NC}"
    exit 1
fi
echo -e "${GREEN}✓ MySQL connection successful${NC}"
echo ""

# Check if irvis database exists
echo -e "${BLUE}Checking for irvis database...${NC}"
if ! mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "USE irvis;" > /dev/null 2>&1; then
    echo -e "${RED}Error: irvis database not found!${NC}"
    echo -e "${YELLOW}Available databases:${NC}"
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "SHOW DATABASES;"
    exit 1
fi
echo -e "${GREEN}✓ irvis database found${NC}"
echo ""

# Dump the irvis schema (structure only, no data)
echo -e "${BLUE}Extracting irvis schema...${NC}"
mysqldump -u root -p"$MYSQL_ROOT_PASSWORD" --no-data --skip-triggers irvis > irvis_schema.sql
echo -e "${GREEN}✓ Schema extracted to irvis_schema.sql${NC}"
echo ""

# Create the setup SQL file
echo -e "${BLUE}Creating eevis database setup script...${NC}"

cat > setup_database.sql << 'EOF'
-- EEVIS Database Setup Script
-- Auto-generated from irvis schema

-- Create the database
CREATE DATABASE IF NOT EXISTS eevis CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Temporarily adjust password validation policy
SET GLOBAL validate_password.policy=LOW;
SET GLOBAL validate_password.length=4;

-- Create the user with password
CREATE USER IF NOT EXISTS 'eevis'@'localhost' IDENTIFIED BY '1h0ck3y$';

-- Grant all privileges on the eevis database to the eevis user
GRANT ALL PRIVILEGES ON eevis.* TO 'eevis'@'localhost';

-- Also allow connections from any host (optional)
CREATE USER IF NOT EXISTS 'eevis'@'%' IDENTIFIED BY '1h0ck3y$';
GRANT ALL PRIVILEGES ON eevis.* TO 'eevis'@'%';

-- Apply changes
FLUSH PRIVILEGES;

-- Use the eevis database
USE eevis;

EOF

# Append the irvis schema (replacing database references)
echo -e "${BLUE}Converting irvis schema to eevis...${NC}"
sed 's/`irvis`/`eevis`/g; s/USE `irvis`/USE `eevis`/g' irvis_schema.sql | \
    grep -v "^--" | \
    grep -v "^/\*" | \
    sed '/^$/d' >> setup_database.sql

echo -e "${GREEN}✓ Setup script created${NC}"
echo ""

# Execute the setup script
echo -e "${BLUE}Creating eevis database and user...${NC}"
mysql -u root -p"$MYSQL_ROOT_PASSWORD" < setup_database.sql

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database and user created successfully${NC}"
    echo ""
    
    # Show created tables
    echo -e "${BLUE}Tables in eevis database:${NC}"
    mysql -u root -p"$MYSQL_ROOT_PASSWORD" -e "USE eevis; SHOW TABLES;"
    echo ""
    
    # Test eevis user connection
    echo -e "${BLUE}Testing eevis user connection...${NC}"
    if mysql -u eevis -p'1h0ck3y$' -e "USE eevis; SELECT 'Connection successful' AS status;" 2>/dev/null; then
        echo -e "${GREEN}✓ eevis user can connect successfully${NC}"
    else
        echo -e "${YELLOW}⚠ Warning: Could not verify eevis user connection${NC}"
    fi
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Setup Complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo -e "${BLUE}Database:${NC} eevis"
    echo -e "${BLUE}Username:${NC} eevis"
    echo -e "${BLUE}Password:${NC} 1h0ck3y$"
    echo ""
    echo -e "${YELLOW}Files created:${NC}"
    echo -e "  - setup_database.sql (setup script)"
    echo -e "  - irvis_schema.sql (irvis schema backup)"
    echo ""
else
    echo -e "${RED}Error: Failed to create database${NC}"
    exit 1
fi
