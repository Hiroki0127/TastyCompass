# TastyCompass User Guide

## Creating Your Own Account

### Current Setup (In-Memory Storage)
The app currently uses **in-memory storage**, which means:
- ✅ Works immediately, no database setup needed
- ❌ **Data resets when server restarts** (users, favorites, reviews all gone)
- ❌ You'll need to recreate your account after server restarts

### Creating a New User

1. **Open the app** and tap "Sign Up"
2. **Enter your details**:
   - Email: your-email@example.com
   - Password: your-password
   - First Name: Your first name
   - Last Name: Your last name
3. **Tap "Register"**
4. You'll be automatically logged in!

### Demo Account
For testing, you can use:
- **Email**: demo@tastycompass.com
- **Password**: demo123

**Note**: This account is recreated on server restart, so it's always available.

---

## Enabling Persistent Storage (PostgreSQL)

If you want your account and favorites to persist across server restarts, you need to set up PostgreSQL.

### Quick Setup

1. **Install PostgreSQL** (if not already installed):
   ```bash
   # macOS with Homebrew
   brew install postgresql@15
   brew services start postgresql@15
   ```

2. **Create the database**:
   ```bash
   createdb tastycompass
   ```

3. **Update backend `.env` file**:
   Uncomment the PostgreSQL configuration:
   ```env
   USE_POSTGRES=true
   DB_HOST=localhost
   DB_PORT=5432
   DB_NAME=tastycompass
   DB_USER=hiro              # your macOS username
   DB_PASSWORD=              # leave empty if no password
   ```

4. **Restart the backend server**:
   ```bash
   cd tastycompass-backend
   npm run dev
   ```

5. **Verify** you see in the logs:
   ```
   ✅ PostgreSQL database connected successfully
   💾 Storage: PostgreSQL (persistent)
   ```

### Benefits of PostgreSQL

Once enabled:
- ✅ **Your account persists** - no need to recreate after restarts
- ✅ **Favorites persist** - saved restaurants stay saved
- ✅ **Reviews persist** - your reviews are permanently stored
- ✅ **Multiple real users** - create as many accounts as you need

---

## Features Overview

### 1. Search Restaurants
- Uses your GPS location
- Finds nearby restaurants
- Filter by cuisine, price, rating, distance

### 2. View Details
- Restaurant info (hours, phone, address)
- Photo gallery
- Google Maps with directions
- **Google Reviews** - Click the "Google Reviews" card to see real user reviews with pagination

### 3. Write Reviews
- Rate restaurants (1-5 stars)
- Write detailed reviews
- Edit your reviews anytime

### 4. Favorites
- ❤️ Tap the heart icon to favorite
- View all favorites in the Favorites tab
- Remove favorites anytime

### 5. User Account
- Secure login with JWT tokens
- Your reviews and favorites tied to your account

---

## Troubleshooting

### "Cannot login" / "User not found"
- **If using in-memory storage**: Server restarted, recreate your account
- **If using PostgreSQL**: Check database connection in server logs

### "Favorites disappeared"
- **In-memory mode**: This happens on server restart
- **Solution**: Enable PostgreSQL for persistence

### "Resource exceeds maximum size"
- Already fixed! Reviews are now truncated to reasonable sizes

### "Cannot see Google reviews"
- Click the **"Google Reviews"** card in the restaurant details page
- Or click the star rating at the top of the page

---

## Tips

1. **For development**: In-memory storage is faster and simpler
2. **For production/testing**: Use PostgreSQL for data persistence
3. **Create real accounts**: Don't rely on demo@tastycompass.com for important data
4. **Backup your data**: If using PostgreSQL, periodically backup with `pg_dump tastycompass > backup.sql`

---

## Need Help?

Check these files:
- `SETUP_DATABASE.md` - Detailed PostgreSQL setup guide
- `README.md` - Project overview and tech stack
- Backend logs - Server terminal shows all API requests and errors

