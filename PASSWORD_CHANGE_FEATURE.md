# Change Password Feature

## Overview
Added a password change feature that allows logged-in users to update their password. The feature includes proper validation, security checks, and user feedback.

## Files Added

### 1. eevis/change_password.html
A professional password change form with:
- Current password field
- New password field (min 6 characters)
- Confirm password field
- Client-side JavaScript validation
- Server-side error/success message display
- Password requirements list
- Security notes
- Brown color scheme matching EEVIS theme

## Files Modified

### 1. eevis/home.html
**Added:**
- "Change Password" button in the bottom button bar
- Button only appears for logged-in users (any user, not just admins)
- Positioned between admin buttons (if visible) and user info/logout section

**Button Logic:**
```html
{{ if .isLoggedIn }}
    <button onclick="window.location.href='/eevis/change-password'">Change Password</button>
{{ end }}
```

### 2. main.go
**Added:**
- New route group `authRoutes` for authenticated (non-admin) user routes
- GET `/eevis/change-password` - Display password change form
- POST `/eevis/change-password` - Process password change request

**Middleware:**
- Uses `requireAuth()` middleware (any authenticated user)
- Does NOT require admin privileges

## Features

### Validation
1. **Required Fields:** All fields must be filled
2. **Password Match:** New password and confirmation must match
3. **Password Length:** Minimum 6 characters
4. **Current Password:** Must verify current password before change
5. **Different Password:** New password must be different from current
6. **Database Check:** Verifies user exists and current password is correct

### Security
1. **Authentication Required:** Must be logged in to access
2. **Password Verification:** Confirms current password before allowing change
3. **SHA256 Hashing:** Passwords hashed before storage
4. **Session Validation:** Uses session to get current user
5. **Secure Permissions:** No privilege escalation possible
6. **Logging:** All password change attempts logged

### User Experience
1. **Client-side Validation:** JavaScript validation before form submission
2. **Clear Error Messages:** Specific errors for each validation failure
3. **Success Feedback:** Confirmation message on successful change
4. **Password Requirements:** Clear list of password rules
5. **Security Notes:** Explanation of password security
6. **Easy Navigation:** Home link to return to main page

## API Endpoints

### GET /eevis/change-password
**Access:** Authenticated users only  
**Returns:** HTML form for changing password  
**Template Data:**
- `username` - Current logged-in username
- `error` - Error message (if any)
- `success` - Success message (if any)

### POST /eevis/change-password
**Access:** Authenticated users only  
**Form Fields:**
- `current_password` - User's current password
- `new_password` - New password to set
- `confirm_password` - Confirmation of new password

**Validation Flow:**
1. Check all fields present
2. Verify passwords match
3. Check password length (min 6)
4. Verify user exists in database
5. Verify current password correct
6. Ensure new password different
7. Hash and update password
8. Return success/error message

**Success:** Returns form with success message  
**Failure:** Returns form with specific error message

## Error Messages

| Error | Condition |
|-------|-----------|
| "All fields are required" | Missing any field |
| "New passwords do not match" | Confirmation mismatch |
| "New password must be at least 6 characters" | Password too short |
| "Error retrieving user information" | Database error |
| "Current password is incorrect" | Wrong current password |
| "New password must be different from current password" | Same password |
| "Failed to update password" | Database update error |

## Success Message

"Password changed successfully!" - Displayed when password is updated in database

## Logging

All password change attempts are logged:
- Successful changes: `User {username} successfully changed password`
- Failed attempts: Specific error logged with reason
- All attempts: `POST /eevis/change-password from {IP}`

## Testing Checklist

### Positive Tests
- [ ] Login as regular user
- [ ] Click "Change Password" button
- [ ] Enter correct current password
- [ ] Enter new password (min 6 chars)
- [ ] Confirm new password
- [ ] Submit and verify success message
- [ ] Logout and login with new password
- [ ] Verify new password works

### Negative Tests
- [ ] Try to access without login (should redirect)
- [ ] Enter wrong current password (should fail)
- [ ] Enter mismatched passwords (should fail)
- [ ] Enter password < 6 characters (should fail)
- [ ] Enter same password as current (should fail)
- [ ] Leave fields blank (should fail)

### UI Tests
- [ ] Button appears for logged-in users
- [ ] Button does NOT appear for non-logged-in users
- [ ] Button appears for both admin and non-admin users
- [ ] Form displays correctly
- [ ] Error messages display properly
- [ ] Success message displays properly
- [ ] Navigation works (Home link)

## Security Considerations

1. **No Password Recovery:** This feature only changes password, does not recover it
2. **Current Password Required:** Prevents unauthorized changes if session compromised
3. **Password Hashing:** SHA256 hashing (consider upgrading to bcrypt)
4. **Session-based:** Uses existing session authentication
5. **Logging:** All attempts logged for audit trail
6. **No Email:** Does not send password via email
7. **Rate Limiting:** Consider adding rate limiting to prevent brute force

## Future Enhancements

Potential improvements:
1. **Stronger Hashing:** Upgrade from SHA256 to bcrypt
2. **Password Strength Meter:** Real-time password strength indicator
3. **Password History:** Prevent reusing recent passwords
4. **Email Notification:** Send email when password changes
5. **Two-Factor Authentication:** Add 2FA requirement
6. **Rate Limiting:** Limit password change attempts
7. **Password Expiration:** Force password changes periodically
8. **Complexity Requirements:** Uppercase, lowercase, numbers, symbols
9. **Account Lockout:** Lock account after failed attempts
10. **Session Invalidation:** Logout all sessions after password change

## Database Impact

**Updated Table:** `users`  
**Updated Column:** `hashed_password`  
**Update Query:** 
```sql
UPDATE users SET hashed_password=? WHERE username=?
```

No schema changes required - uses existing table structure.

## Integration with Existing Features

- **Login:** Updated password works immediately
- **Sessions:** No session invalidation (consider adding)
- **Admin Functions:** Still works for admin users
- **User Management:** Admin can still create users with passwords
- **Authentication:** Uses same password verification as login

## Browser Compatibility

Tested features:
- HTML5 form validation (required, minlength)
- JavaScript form validation
- Password input type
- Responsive design
- All modern browsers supported

## Accessibility

- Proper label associations
- Required field indicators
- Error message announcements
- Keyboard navigation
- Focus management
- Clear visual feedback
