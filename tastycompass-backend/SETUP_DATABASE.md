# PostgreSQL Setup Guide for TastyCompass

## Option 1: Use In-Memory Storage (Current Default)

The app currently uses in-memory storage. No setup needed, but data resets on server restart.

## Option 2: Enable PostgreSQL for Persistent Storage

### Prerequisites

1. Install PostgreSQL (if not already installed):
   ```bash
   # macOS with Homebrew
   brew install postgresql@15
   brew services start postgresql@15
   
   # Or use Postgres.app from https://postgresapp.com/
   ```

### Setup Steps

1. **Create the database**:
   ```bash
   # Connect to PostgreSQL
   psql postgres
   
   # Create database
   CREATE DATABASE tastycompass;
   
   # Exit
   \q
   ```

2. **Update `.env` file**:
   Uncomment and configure the PostgreSQL section:
   ```env
   USE_POSTGRES=true
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=tastycompass
   DB_USER=postgres           # or your PostgreSQL username
   DB_PASSWORD=yourpassword   # your PostgreSQL password (or leave empty if none)
   ```

3. **Restart the backend server**:
   ```bash
   npm run dev
   ```

The server will automatically:
- Connect to PostgreSQL
- Create tables (users, favorites, reviews)
- Set up indexes and triggers
- Migrate to persistent storage

### Verify Setup

Check the server logs for:
```
✅ PostgreSQL database connected successfully
✅ Database schema initialized successfully
💾 Storage: PostgreSQL (persistent)
```

### Create Your First Real User

1. Stop using demo@tastycompass.com
2. Register a new account in the app
3. Your data will persist across server restarts!

### Troubleshooting

**Connection Failed**:
- Verify PostgreSQL is running: `pg_isready`
- Check credentials in `.env`
- Try connecting manually: `psql -U postgres -d tastycompass`

**Tables Not Created**:
- Check server logs for initialization errors
- Manually run schema: `psql -U postgres -d tastycompass -f src/database/schema.sql`

**Data Still Resetting**:
- Verify `USE_POSTGRES=true` in `.env`
- Check server logs show "PostgreSQL" not "In-memory"
- Restart the server after changing `.env`

### Switch Back to In-Memory

Set in `.env`:
```env
USE_POSTGRES=false
```
or comment out the line.

## Database Management

### View Data
```bash
psql -d tastycompass

# List tables
\dt

# View users
SELECT * FROM users;

# View favorites
SELECT * FROM favorites;

# View reviews
SELECT * FROM reviews;
```

### Reset Database
```bash
# Drop and recreate
psql postgres
DROP DATABASE tastycompass;
CREATE DATABASE tastycompass;
\q

# Restart server to recreate schema
```

### Backup Data
```bash
pg_dump tastycompass > backup.sql
```

### Restore Data
```bash
psql tastycompass < backup.sql
```

