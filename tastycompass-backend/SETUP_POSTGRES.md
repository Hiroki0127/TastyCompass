# PostgreSQL Database Setup

This guide will help you set up PostgreSQL for the TastyCompass backend.

## 1. Install PostgreSQL

### macOS (using Homebrew)
```bash
brew install postgresql
brew services start postgresql
```

### Ubuntu/Debian
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
sudo systemctl enable postgresql
```

### Windows
Download and install from: https://www.postgresql.org/download/windows/

## 2. Create Database and User

Connect to PostgreSQL as the postgres user:
```bash
sudo -u postgres psql
```

Create the database and user:
```sql
CREATE DATABASE tastycompass;
CREATE USER tastycompass_user WITH ENCRYPTED PASSWORD 'password';
GRANT ALL PRIVILEGES ON DATABASE tastycompass TO tastycompass_user;
\q
```

## 3. Environment Configuration

Copy the example environment file:
```bash
cp .env.example .env
```

Edit `.env` with your database credentials:
```env
# PostgreSQL Database Configuration
DB_HOST=localhost
DB_PORT=5432
DB_NAME=tastycompass
DB_USER=tastycompass_user
DB_PASSWORD=password
```

## 4. Test the Setup

Start the backend server:
```bash
npm run dev
```

You should see:
```
✅ PostgreSQL database connected successfully
✅ Database schema initialized successfully
🗄️ Database: PostgreSQL connected
```

## 5. Verify Database Tables

Connect to the database and verify tables were created:
```bash
psql -U tastycompass_user -d tastycompass
```

List tables:
```sql
\dt
```

You should see:
- users
- favorites

## Troubleshooting

### Connection Issues
- Ensure PostgreSQL is running: `brew services list | grep postgresql`
- Check if the database exists: `psql -U postgres -l`
- Verify user permissions: `psql -U postgres -c "\du"`

### Permission Issues
Grant additional permissions if needed:
```sql
GRANT ALL PRIVILEGES ON ALL TABLES IN SCHEMA public TO tastycompass_user;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA public TO tastycompass_user;
```

## Production Notes

For production deployment:
1. Change the default password
2. Use environment variables for all sensitive data
3. Configure SSL connections
4. Set up proper backup procedures
5. Consider using a managed PostgreSQL service (AWS RDS, Google Cloud SQL, etc.)
