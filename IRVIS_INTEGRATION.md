# IRVIS-GO Methodology Integration

## Overview
This document describes the integration of the irvis-go methodology for issue reporting and user management into eevis-go.

## Changes Made

### 1. Backend Updates (main.go)

#### Added Imports
- `crypto/sha256` - For secure password hashing
- `encoding/hex` - For encoding hashed passwords
- `strings` - For string manipulation in HTTP requests
- `time` - For HTTP client timeout configuration

#### Added Helper Function
```go
func sha256sum(s string) string
```
Hashes passwords using SHA256 algorithm, matching the irvis-go implementation.

#### Updated POST /eevis/report-issue Handler
**Features:**
- Creates GitHub issues via GitHub API
- Validates form inputs (title, body, repo)
- Supports two repositories: `eevis-go` and `eevis_flutter`
- Uses GITHUB_TOKEN from environment variables
- Returns success/error messages to the template
- Logs all actions for audit trail

**Validation:**
- Checks for missing fields
- Validates repository selection
- Verifies GitHub token configuration
- Handles API errors gracefully

#### Updated POST /eevis/add-user Handler
**Features:**
- Password confirmation validation
- SHA256 password hashing
- Duplicate username/email checking
- Proper error messages
- Admin privilege assignment
- Comprehensive logging

**Validation:**
- All required fields present
- Passwords match
- Username/email uniqueness
- Database error handling

### 2. Frontend Updates

#### report_issue.html
**Redesigned to match irvis-go style:**
- Clean, centered form layout
- Repository dropdown (eevis-go, eevis_flutter)
- Title and description fields
- Success/error message display
- User information display
- Home button for navigation
- Brown color scheme matching EEVIS theme

**Fields:**
- Repository (dropdown)
- Title (text input)
- Description (textarea)

#### add_user.html
**Redesigned to match irvis-go style:**
- Professional admin interface
- Client-side password validation
- Confirm password field
- Admin checkbox for privileges
- Success/error message display
- Form notes explaining security
- Brown color scheme

**Fields:**
- Username (text, max 64 chars)
- Email (email validation, max 255 chars)
- Password (min 6 chars)
- Confirm Password (validation)
- Is Admin (checkbox)

**Client-side Validation:**
- Password match verification
- Minimum password length (6 characters)
- Real-time validation on form submit

### 3. Configuration

#### .env File
Added/verified GITHUB_TOKEN configuration:
```properties
GITHUB_TOKEN=github_pat_...
```

Required for creating GitHub issues from the application.

## Differences from IRVIS-GO

### Similarities
1. **Password Hashing**: Uses SHA256 (same algorithm)
2. **GitHub Integration**: Same API calls and error handling
3. **Form Validation**: Matching validation logic
4. **User Interface**: Similar styling and layout
5. **Admin Privileges**: Same checkbox approach
6. **Error Handling**: Consistent error message patterns

### Differences
1. **Route Prefix**: `/eevis` instead of `/irvis`
2. **Repository Names**: `eevis-go` and `eevis_flutter` instead of `irvis-go` and `irvis_flutter`
3. **Color Scheme**: Maintains EEVIS brown (#8d6e63) instead of IRVIS brown
4. **Session Management**: Uses "username" key instead of session storing full user object
5. **Database Schema**: Same schema, different database name (eevis vs irvis)

## API Endpoints

### Issue Reporting
- **GET** `/eevis/report-issue` - Display issue form (admin only)
- **POST** `/eevis/report-issue` - Submit GitHub issue (admin only)

### User Management
- **GET** `/eevis/add-user` - Display add user form (admin only)
- **POST** `/eevis/add-user` - Create new user (admin only)

## Security Features

1. **Password Hashing**: SHA256 hashing before storage
2. **Password Confirmation**: Client and server-side validation
3. **Admin Authorization**: Middleware protects routes
4. **Input Validation**: All fields validated
5. **Duplicate Prevention**: Checks existing usernames/emails
6. **Secure Sessions**: HttpOnly cookies
7. **HTTPS Support**: Optional TLS configuration

## GitHub Integration

### Requirements
1. Valid GitHub Personal Access Token
2. Token stored in GITHUB_TOKEN environment variable
3. Token must have `repo` scope for issue creation

### Supported Repositories
- vaccs/eevis-go
- vaccs/eevis_flutter

### Issue Creation Flow
1. Admin fills out issue form
2. Form validates inputs
3. Creates HTTP POST to GitHub API
4. Sets proper headers (Authorization, Accept, Content-Type)
5. Returns success or error message
6. Logs action for audit

## Testing Recommendations

### Issue Reporting
1. Login as admin user
2. Navigate to Report Issue
3. Select repository
4. Enter title and description
5. Submit and verify GitHub issue created
6. Check error handling (missing fields, invalid repo)

### User Creation
1. Login as admin user
2. Navigate to Add User
3. Fill out all fields
4. Test password confirmation
5. Verify user created in database
6. Test duplicate username/email rejection
7. Verify password hashing in database

### Error Scenarios
- Missing GitHub token
- Invalid repository selection
- Password mismatch
- Duplicate username
- Missing required fields
- Database connection errors

## Migration Notes

If migrating from previous eevis-go implementation:
1. Existing users need passwords rehashed with SHA256
2. Update .env file with GITHUB_TOKEN
3. Test all admin routes with proper authentication
4. Verify database permissions for INSERT operations
5. Check GitHub token permissions

## Future Enhancements

Potential improvements (same as irvis-go):
1. Switch to bcrypt for password hashing
2. Add password strength requirements
3. Implement rate limiting on issue creation
4. Add email verification for new users
5. Support for issue labels and milestones
6. Issue template support
7. Audit log for admin actions
8. User role management beyond admin/non-admin

## Logging

All admin actions are logged with:
- Action performed
- User performing action
- Timestamp (via Go's log package)
- Success/failure status
- Error details (if applicable)

Example log entries:
```
POST /eevis/report-issue from 127.0.0.1
User admin successfully created issue in eevis-go
POST /eevis/add-user from 127.0.0.1
Admin admin successfully created user: newuser (email: user@example.com, admin: false)
```

## Conclusion

The eevis-go application now follows the same proven methodology as irvis-go for issue reporting and user management, providing a consistent, secure, and user-friendly admin interface.
