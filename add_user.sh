#!/bin/bash

# Script to add a user to the eevis database users table

set -e  # Exit on error

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Load environment variables from .env file
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
else
    echo -e "${RED}Error: .env file not found!${NC}"
    echo -e "${YELLOW}Please create a .env file based on .env.example${NC}"
    exit 1
fi

# Database credentials from environment
DB_USER="${DB_USER:-eevis}"
DB_PASS="${DB_PASSWORD:-}"
DB_NAME="${DB_NAME:-eevis}"

if [ -z "$DB_PASS" ]; then
    echo -e "${RED}Error: DB_PASSWORD not set in .env file${NC}"
    exit 1
fi

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}EEVIS User Creation Script${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""

# Function to hash password (using bcrypt-like simulation with openssl)
hash_password() {
    local password="$1"
    # Using SHA-256 for now - in production, use proper bcrypt
    echo -n "$password" | openssl dgst -sha256 | awk '{print $2}'
}

# Prompt for user information
echo -e "${YELLOW}Enter username:${NC}"
read -r USERNAME

# Check if username already exists
EXISTING_USER=$(mysql -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -se "SELECT COUNT(*) FROM users WHERE username='$USERNAME';" 2>/dev/null)

if [ "$EXISTING_USER" -gt 0 ]; then
    echo -e "${RED}Error: Username '$USERNAME' already exists!${NC}"
    exit 1
fi

echo -e "${YELLOW}Enter email:${NC}"
read -r EMAIL

# Check if email already exists
EXISTING_EMAIL=$(mysql -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" -se "SELECT COUNT(*) FROM users WHERE email='$EMAIL';" 2>/dev/null)

if [ "$EXISTING_EMAIL" -gt 0 ]; then
    echo -e "${RED}Error: Email '$EMAIL' already exists!${NC}"
    exit 1
fi

echo -e "${YELLOW}Enter password:${NC}"
read -s PASSWORD
echo ""

echo -e "${YELLOW}Confirm password:${NC}"
read -s PASSWORD_CONFIRM
echo ""

if [ "$PASSWORD" != "$PASSWORD_CONFIRM" ]; then
    echo -e "${RED}Error: Passwords do not match!${NC}"
    exit 1
fi

echo -e "${YELLOW}Is this user an admin? (y/N):${NC}"
read -r IS_ADMIN_INPUT

if [[ "$IS_ADMIN_INPUT" =~ ^[Yy]$ ]]; then
    IS_ADMIN=1
else
    IS_ADMIN=0
fi

# Hash the password
echo -e "${BLUE}Hashing password...${NC}"
HASHED_PASSWORD=$(hash_password "$PASSWORD")

# Insert the user into the database
echo -e "${BLUE}Creating user in database...${NC}"

mysql -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" <<EOF 2>/dev/null
INSERT INTO users (username, email, hashed_password, is_logged_in, is_admin)
VALUES ('$USERNAME', '$EMAIL', '$HASHED_PASSWORD', 0, $IS_ADMIN);
EOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ User created successfully!${NC}"
    echo ""
    echo -e "${BLUE}User Details:${NC}"
    
    # Retrieve and display the created user
    mysql -u "$DB_USER" -p"$DB_PASS" -D "$DB_NAME" <<EOF 2>/dev/null
SELECT id, username, email, is_admin, is_logged_in 
FROM users 
WHERE username='$USERNAME';
EOF
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}User creation complete!${NC}"
    echo -e "${GREEN}========================================${NC}"
else
    echo -e "${RED}Error: Failed to create user${NC}"
    exit 1
fi
