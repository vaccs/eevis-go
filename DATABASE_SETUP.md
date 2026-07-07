# EEVIS Database Setup

## Database Information

- **Database Name:** eevis
- **Username:** eevis
- **Password:** 1h0ck3y$
- **Character Set:** utf8mb4
- **Collation:** utf8mb4_unicode_ci

## Schema

The database has been created with the same schema as the `irvis` database.

### Tables

#### users
| Field           | Type         | Null | Key | Default | Extra          |
|-----------------|--------------|------|-----|---------|----------------|
| id              | int          | NO   | PRI | NULL    | auto_increment |
| username        | varchar(64)  | NO   | UNI | NULL    |                |
| email           | varchar(255) | NO   | UNI | NULL    |                |
| hashed_password | varchar(255) | NO   |     | NULL    |                |
| is_logged_in    | tinyint(1)   | NO   |     | 0       |                |
| is_admin        | tinyint(1)   | NO   |     | 0       |                |

## Connection Examples

### MySQL Command Line
```bash
mysql -u eevis -p'1h0ck3y$' eevis
```

### Go (using go-sql-driver/mysql)
```go
import (
    "database/sql"
    _ "github.com/go-sql-driver/mysql"
)

db, err := sql.Open("mysql", "eevis:1h0ck3y$@tcp(localhost:3306)/eevis?parseTime=true")
```

### Connection String
```
eevis:1h0ck3y$@tcp(localhost:3306)/eevis
```

## Files Generated

- `setup_database.sql` - SQL script used to create the database
- `irvis_schema.sql` - Backup of the irvis schema
- `setup_eevis_database.sh` - Automated setup script

## Setup Script

To recreate the database or run on another machine:

```bash
./setup_eevis_database.sh
```

### Fresh setup without an existing `irvis` database

`setup_eevis_database.sh` copies its schema from an existing `irvis` database, which
won't be available on a new machine (or in a container). Use `schema.sql` instead:

```bash
mysql -u root -p < schema.sql
```

This creates the `eevis` database and `users` table directly, with no dependency on
`irvis`. It's also what the Docker setup in `../eevis-docker` uses to provision the
database automatically.

The script will:
1. Prompt for MySQL root password
2. Check if irvis database exists
3. Extract the irvis schema
4. Create the eevis database
5. Create the eevis user with proper permissions
6. Apply the schema to the new database
7. Verify the setup

## Permissions

The `eevis` user has been granted:
- ALL PRIVILEGES on the `eevis` database
- Access from localhost and any host (%)

## Notes

- The password policy was temporarily adjusted during setup to allow the specified password
- The schema includes proper indexes and constraints from the original irvis database
- The database uses InnoDB engine with AUTO_INCREMENT for the id field
