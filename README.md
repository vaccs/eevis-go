# eevis-go

EEVIS (Enterprise Equipment Visualization and Inventory System) - A Go web application with Flutter frontend and MySQL backend.

## Features

- **Authentication System** with session management
- **Admin-protected routes** for sensitive operations
- **MySQL database integration** for user management
- **Flutter web frontend** embedded in the application
- **Role-based access control** (Admin/User roles)
- Health check endpoint

## 🔐 Security & Access Control

### Protected Routes (Admin Only)
- `/report-issue` - Report issues (GET/POST)
- `/add-user` - Add new users (GET/POST)

### Authentication Middleware
- **`requireAuth()`** - Ensures user is logged in
- **`requireAdmin()`** - Ensures user is admin

### UI Behavior
- Non-admin users see disabled "Report Issue" and "Add User" buttons
- Admin users have full access with "(Admin)" badge
- Unauthorized access shows appropriate error pages (401/403)

## Getting Started

### Prerequisites

- Go 1.23 or higher
- MySQL 8.0 or higher
- Flutter (for building the frontend)

### Initial Setup

1. **Clone the repository:**
   ```bash
   cd ~/eevis-go
   ```

2. **Configure environment variables:**
   ```bash
   cp .env.example .env
   nano .env  # Edit with your actual values
   ```
   
   See [CONFIGURATION.md](CONFIGURATION.md) for detailed configuration options.

### Database Setup

1. Set up the MySQL database:
   ```bash
   ./setup_eevis_database.sh
   ```
   
   This creates:
   - Database: `eevis`
   - User: `eevis` with password `1h0ck3y$`
   - Schema matching the `irvis` database

2. Create an admin user:
   ```bash
   ./add_user_cli.sh -u admin -e admin@eevis.com -p YourPassword -a
   ```

### Building the Flutter Frontend

```bash
./build_flutter.sh
```

This builds the Flutter app from `~/eevis_flutter` and copies it to the `visual` directory.

### Running the Application

1. Navigate to the project directory:
   ```bash
   cd ~/eevis-go
   ```

2. Run the application:
   ```bash
   go run main.go
   ```

3. Access the application:
   - Main app: http://localhost:8080/eevis
   - Health check: http://localhost:8080/health

### Building the Application

```bash
go build -o eevis-go main.go
./eevis-go
```

## API Endpoints

### Public Routes
- `GET /` - Welcome message
- `GET /eevis` - Main application page
- `GET /login` - Login page
- `POST /login` - Login authentication
- `GET /logout` - Logout
- `GET /health` - Health check (JSON status)
- `GET /visual/*` - Static Flutter web files

### Protected Routes (Admin Only)
- `GET /report-issue` - Report issue form
- `POST /report-issue` - Submit issue report
- `GET /add-user` - Add user form
- `POST /add-user` - Create new user

## User Management

### Create User (Interactive)
```bash
./add_user.sh
```

### Create User (CLI)
```bash
# Regular user
./add_user_cli.sh -u username -e email@example.com -p password

# Admin user
./add_user_cli.sh -u admin -e admin@example.com -p password -a
```

## Database Schema

### Users Table
```sql
CREATE TABLE users (
  id INT NOT NULL AUTO_INCREMENT PRIMARY KEY,
  username VARCHAR(64) NOT NULL UNIQUE,
  email VARCHAR(255) NOT NULL UNIQUE,
  hashed_password VARCHAR(255) NOT NULL,
  is_logged_in TINYINT(1) NOT NULL DEFAULT 0,
  is_admin TINYINT(1) NOT NULL DEFAULT 0
);
```

## Project Structure

```
eevis-go/
├── main.go                      # Main application with auth
├── go.mod                       # Go module dependencies
├── build_flutter.sh             # Flutter build script
├── setup_eevis_database.sh      # Database setup
├── add_user.sh                  # Interactive user creation
├── add_user_cli.sh              # CLI user creation
├── DATABASE_SETUP.md            # Database documentation
├── eevis/                       # HTML templates
│   ├── home.html               # Main app page
│   ├── login.html              # Login page
│   ├── error.html              # Error pages (401/403)
│   ├── report_issue.html       # Report issue form
│   └── add_user.html           # Add user form
└── visual/                      # Flutter web build output
    └── index.html              # Flutter app entry
```

## Dependencies

```go
github.com/gin-gonic/gin                // Web framework
github.com/gin-contrib/sessions         // Session management
github.com/gin-contrib/sessions/cookie  // Cookie sessions
github.com/go-sql-driver/mysql          // MySQL driver
github.com/joho/godotenv                // Environment variable loader
```

Install dependencies:
```bash
go get github.com/gin-gonic/gin
go get github.com/gin-contrib/sessions
go get github.com/go-sql-driver/mysql
go get github.com/joho/godotenv
```

## Configuration

All sensitive configuration is stored in the `.env` file (not committed to git).

### Quick Configuration

1. Copy the example file:
   ```bash
   cp .env.example .env
   ```

2. Edit with your values:
   ```bash
   nano .env
   ```

3. Key settings:
   - `DB_PASSWORD` - Your MySQL password
   - `SESSION_SECRET` - Generate with: `openssl rand -base64 32`
   - `USE_TLS` - Set to `true` for HTTPS
   - `APP_PORT` - Default is `8080`

See [CONFIGURATION.md](CONFIGURATION.md) for complete configuration guide.

### TLS/HTTPS Support

To enable HTTPS:

1. Generate or obtain TLS certificates
2. Update `.env`:
   ```env
   USE_TLS=true
   TLS_CERT_FILE=/path/to/cert.pem
   TLS_KEY_FILE=/path/to/key.pem
   APP_PORT=443
   ```

For self-signed certificates (testing only):
```bash
openssl genrsa -out server.key 2048
openssl req -new -x509 -key server.key -out server.crt -days 365
```

## Security Notes

⚠️ **Important for Production:**

1. **Environment Variables**: All secrets are now in `.env` file
   - Never commit `.env` to version control
   - Use `.env.example` as a template
   - Generate strong random values

2. **Session Secret**: Generate a unique secret
   ```bash
   openssl rand -base64 32
   ```
   Add to `.env` as `SESSION_SECRET`

3. **Password Hashing**: Currently uses placeholder hashing. Implement bcrypt:
   ```go
   import "golang.org/x/crypto/bcrypt"
   hashedPassword, _ := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
   ```

4. **TLS/HTTPS**: Enable in production
   - Set `USE_TLS=true` in `.env`
   - Provide valid certificate paths
   - Use certificates from Let's Encrypt or a CA

5. **CSRF Protection**: Add for forms

6. **Rate Limiting**: Implement for login attempts

7. **Database Security**:
   - Use strong `DB_PASSWORD`
   - Restrict database user privileges
   - Use firewall rules to limit access

## Development

The application uses:
- **Gin** web framework for routing and middleware
- **MySQL** for data persistence
- **Sessions** for authentication state
- **Flutter** for the frontend UI

## Git Repository

Remote: `git@github.com:vaccs/eevis-go.git`

```bash
git add .
git commit -m "Your message"
git push origin master
```