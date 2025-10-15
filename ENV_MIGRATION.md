# Environment Configuration Migration - Summary

## What Changed

The EEVIS application has been updated to use environment variables for all configuration instead of hardcoded values.

## Key Improvements

### 🔒 Security
- ✅ No passwords or secrets in source code
- ✅ `.env` file excluded from git
- ✅ Separate configuration for different environments
- ✅ TLS/HTTPS support with certificate configuration

### ⚙️ Configuration
- ✅ All settings in `.env` file
- ✅ `.env.example` template provided
- ✅ Fallback to sensible defaults
- ✅ Environment-specific modes (development/production)

## Files Modified

### New Files
- `.env.example` - Configuration template
- `.env` - Actual configuration (not in git)
- `CONFIGURATION.md` - Complete configuration guide

### Modified Files
- `main.go` - Now loads configuration from environment
- `add_user.sh` - Reads DB credentials from `.env`
- `add_user_cli.sh` - Reads DB credentials from `.env`
- `.gitignore` - Excludes `.env` and sensitive files
- `README.md` - Updated with configuration instructions

## Environment Variables

### Database (Required)
```env
DB_USER=eevis
DB_PASSWORD=your_secure_password
DB_HOST=localhost
DB_PORT=3306
DB_NAME=eevis
```

### Application
```env
APP_PORT=8080
SESSION_SECRET=generate_with_openssl_rand_base64_32
APP_ENV=development
```

### TLS/HTTPS
```env
USE_TLS=false
TLS_CERT_FILE=/path/to/cert.pem
TLS_KEY_FILE=/path/to/key.pem
```

## Quick Start

1. **Setup configuration:**
   ```bash
   cp .env.example .env
   nano .env  # Edit with your values
   ```

2. **Generate session secret:**
   ```bash
   openssl rand -base64 32
   # Add output to .env as SESSION_SECRET
   ```

3. **Run application:**
   ```bash
   go run main.go
   ```

## TLS/HTTPS Setup

### For Development (Self-Signed)
```bash
# Generate certificates
openssl genrsa -out server.key 2048
openssl req -new -x509 -key server.key -out server.crt -days 365

# Update .env
USE_TLS=true
TLS_CERT_FILE=./server.crt
TLS_KEY_FILE=./server.key
APP_PORT=8443
```

### For Production
```bash
# Use Let's Encrypt (recommended)
sudo certbot certonly --standalone -d your-domain.com

# Update .env
USE_TLS=true
TLS_CERT_FILE=/etc/letsencrypt/live/your-domain.com/fullchain.pem
TLS_KEY_FILE=/etc/letsencrypt/live/your-domain.com/privkey.pem
APP_PORT=443
```

## Migration from Old Configuration

### Before
```go
// Hardcoded in main.go
dsn := "eevis:1h0ck3y$@tcp(localhost:3306)/eevis?parseTime=true"
store := cookie.NewStore([]byte("secret-key-change-this-in-production"))
port := ":8080"
```

### After
```go
// Loaded from .env
config := LoadConfig()
dsn := fmt.Sprintf("%s:%s@tcp(%s:%s)/%s?parseTime=true",
    config.DBUser, config.DBPassword, config.DBHost, config.DBPort, config.DBName)
store := cookie.NewStore([]byte(config.SessionSecret))
serverAddr := ":" + config.AppPort
```

## Benefits

1. **Security**
   - Credentials not in source code
   - Easy to rotate secrets
   - Different secrets per environment

2. **Flexibility**
   - Change configuration without recompiling
   - Environment-specific settings
   - Easy deployment to different environments

3. **Best Practices**
   - Follows 12-factor app methodology
   - Industry-standard approach
   - Compatible with Docker/Kubernetes

4. **TLS Support**
   - Easy HTTPS enablement
   - Certificate path configuration
   - Production-ready security

## Testing

### Test with HTTP
```bash
# .env
USE_TLS=false
APP_PORT=8080

# Run
go run main.go

# Access
curl http://localhost:8080/health
```

### Test with HTTPS
```bash
# .env
USE_TLS=true
TLS_CERT_FILE=./server.crt
TLS_KEY_FILE=./server.key
APP_PORT=8443

# Run
go run main.go

# Access
curl -k https://localhost:8443/health
```

## Troubleshooting

### .env file not found
```bash
cp .env.example .env
```

### Database connection failed
- Check `DB_PASSWORD` in `.env`
- Verify MySQL is running
- Test connection: `mysql -u eevis -p`

### TLS error
- Verify certificate files exist
- Check file paths in `.env`
- Ensure certificates are valid

### Scripts can't connect
- Scripts now read from `.env`
- Ensure `.env` exists in project root
- Check `DB_PASSWORD` is set

## Documentation

- `CONFIGURATION.md` - Complete configuration guide
- `README.md` - Updated with configuration section
- `.env.example` - All available options with descriptions

## Next Steps

1. ✅ Copy `.env.example` to `.env`
2. ✅ Set `DB_PASSWORD` to your MySQL password
3. ✅ Generate and set `SESSION_SECRET`
4. ✅ Configure TLS if needed
5. ✅ Test the application
6. ✅ Deploy to production with production `.env`
