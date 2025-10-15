# Environment Configuration Guide

This document describes how to configure the EEVIS application using environment variables.

## Quick Start

1. **Copy the example environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit `.env` with your actual values:**
   ```bash
   nano .env
   ```

3. **Run the application:**
   ```bash
   go run main.go
   ```

## Configuration Variables

### Database Configuration

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `DB_USER` | MySQL username | `eevis` | `eevis` |
| `DB_PASSWORD` | MySQL password | (none) | `1h0ck3y$` |
| `DB_HOST` | MySQL host | `localhost` | `localhost` or `192.168.1.100` |
| `DB_PORT` | MySQL port | `3306` | `3306` |
| `DB_NAME` | Database name | `eevis` | `eevis` |

### Application Configuration

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `APP_PORT` | Port for the application | `8080` | `8080` or `443` |
| `SESSION_SECRET` | Secret key for session encryption | `change-this-secret-key` | Generate with: `openssl rand -base64 32` |
| `APP_ENV` | Environment mode | `development` | `development` or `production` |

### TLS/SSL Configuration

| Variable | Description | Default | Example |
|----------|-------------|---------|---------|
| `USE_TLS` | Enable HTTPS | `false` | `true` or `false` |
| `TLS_CERT_FILE` | Path to TLS certificate | (none) | `/etc/ssl/certs/server.crt` |
| `TLS_KEY_FILE` | Path to TLS private key | (none) | `/etc/ssl/private/server.key` |

## Environment-Specific Configurations

### Development Environment

```env
# .env
DB_USER=eevis
DB_PASSWORD=1h0ck3y$
DB_HOST=localhost
DB_PORT=3306
DB_NAME=eevis

APP_PORT=8080
SESSION_SECRET=dev-secret-key-change-in-prod
USE_TLS=false
APP_ENV=development
```

### Production Environment

```env
# .env
DB_USER=eevis
DB_PASSWORD=YOUR_STRONG_PASSWORD_HERE
DB_HOST=your-db-server.com
DB_PORT=3306
DB_NAME=eevis

APP_PORT=443
SESSION_SECRET=GENERATED_RANDOM_SECRET_KEY
USE_TLS=true
TLS_CERT_FILE=/etc/ssl/certs/eevis.crt
TLS_KEY_FILE=/etc/ssl/private/eevis.key
APP_ENV=production
```

## Generating Secure Values

### Session Secret

Generate a secure random session secret:

```bash
openssl rand -base64 32
```

Copy the output and use it as `SESSION_SECRET` in your `.env` file.

### Self-Signed TLS Certificates (for testing)

Generate self-signed certificates for local TLS testing:

```bash
# Generate private key
openssl genrsa -out server.key 2048

# Generate certificate
openssl req -new -x509 -key server.key -out server.crt -days 365

# Update .env
echo "TLS_CERT_FILE=./server.crt" >> .env
echo "TLS_KEY_FILE=./server.key" >> .env
echo "USE_TLS=true" >> .env
```

### Production TLS Certificates

For production, use certificates from a Certificate Authority (CA) like:
- **Let's Encrypt** (free): Use `certbot`
- **Commercial CA**: Purchase from providers like DigiCert, Comodo, etc.

## Using with Scripts

The user management scripts (`add_user.sh` and `add_user_cli.sh`) automatically read database credentials from the `.env` file.

**Example:**
```bash
# The script will use DB_USER, DB_PASSWORD, and DB_NAME from .env
./add_user_cli.sh -u newuser -e user@example.com -p password123
```

## Security Best Practices

1. **Never commit `.env` to version control**
   - The `.env` file is already in `.gitignore`
   - Always use `.env.example` as a template

2. **Use strong passwords**
   - Minimum 12 characters
   - Mix of letters, numbers, and symbols

3. **Generate unique session secrets**
   - Never use the default value
   - Generate a new one for each environment

4. **Use TLS in production**
   - Set `USE_TLS=true`
   - Use valid certificates from a CA
   - Redirect HTTP to HTTPS

5. **Restrict database access**
   - Use separate database users for each environment
   - Grant minimal required privileges
   - Use firewall rules to limit database access

6. **Environment-specific `.env` files**
   - Different secrets for dev/staging/production
   - Never copy production `.env` to development

## Troubleshooting

### Application won't start

**Error:** `Warning: .env file not found`
- **Solution:** Copy `.env.example` to `.env`: `cp .env.example .env`

**Error:** `Failed to connect to database`
- **Solution:** Check `DB_USER`, `DB_PASSWORD`, `DB_HOST`, `DB_PORT`, and `DB_NAME` in `.env`
- Verify MySQL is running: `systemctl status mysql`

**Error:** `TLS is enabled but TLS_CERT_FILE or TLS_KEY_FILE is not set`
- **Solution:** Set `USE_TLS=false` or provide valid certificate paths

### Scripts can't connect to database

**Error:** `DB_PASSWORD not set in .env file`
- **Solution:** Add `DB_PASSWORD=your_password` to `.env`

**Error:** Access denied
- **Solution:** Verify credentials in `.env` match MySQL user

## Docker/Container Deployment

When using Docker, you can pass environment variables:

```bash
docker run -d \
  -e DB_USER=eevis \
  -e DB_PASSWORD=secret \
  -e DB_HOST=db.example.com \
  -e APP_PORT=8080 \
  -p 8080:8080 \
  eevis-go
```

Or use a `.env` file:

```bash
docker run -d --env-file .env -p 8080:8080 eevis-go
```

## Related Files

- `.env.example` - Template with all available options
- `.env` - Your actual configuration (not in git)
- `.gitignore` - Ensures `.env` is never committed
- `main.go` - Loads and uses environment variables

## Support

For issues or questions about configuration:
1. Check this guide first
2. Verify `.env` file exists and has correct values
3. Check application logs for specific error messages
