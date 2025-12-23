# Deployment Guide for TastyCompass Backend on Railway

This guide will help you deploy the TastyCompass backend to Railway with PostgreSQL database.

## Prerequisites

1. A [Railway](https://railway.app) account (free tier available)
2. Your GitHub repository pushed to GitHub
3. GitHub account connected to Railway

## Step 1: Create New Project

1. Go to [Railway Dashboard](https://railway.app/dashboard)
2. Click **"New Project"**
3. Select **"Deploy from GitHub repo"**
4. Choose your repository: `TastyCompass`
5. Railway will create a new project

## Step 2: Add PostgreSQL Database

1. In your Railway project, click **"+ New"**
2. Select **"Database"** → **"Add PostgreSQL"**
3. Railway will automatically provision a PostgreSQL database
4. The database will be added to your project

## Step 3: Configure Web Service

1. In your Railway project, click **"+ New"** → **"GitHub Repo"**
2. Select your repository again
3. Railway will detect it's a Node.js project
4. Click on the service to configure it

### Configure Build Settings

**IMPORTANT:** Since the backend code is in a subdirectory, you MUST set the root directory:

1. Go to **Settings** → **Build**
2. **Set Root Directory**: `tastycompass-backend` ⚠️ **This is critical!**
3. Railway will automatically detect:
   - Build Command: `npm install && npm run build`
   - Start Command: `npm start`

**If you get "error creating build plan with Nixpacks":**
- Make sure **Root Directory** is set to `tastycompass-backend` (not empty!)
- The Root Directory tells Railway where your `package.json` is located
- Without this, Railway tries to build from the repo root and fails

### Configure Environment Variables

1. Go to **Variables** tab
2. Add the following variables:

   ```
   NODE_ENV=production
   USE_POSTGRES=true
   PORT=3000
   JWT_SECRET=<generate a random secret, e.g., use: openssl rand -hex 32>
   ```

3. **Link the PostgreSQL database:**
   - Click **"Add Reference"**
   - Select your PostgreSQL database
   - Railway will automatically add:
     - `DATABASE_URL` (full connection string)
     - `PGHOST`
     - `PGPORT`
     - `PGDATABASE`
     - `PGUSER`
     - `PGPASSWORD`

### Alternative: Use Individual Database Variables

If Railway doesn't automatically create the individual variables, you can add them manually by clicking on the database service and copying the connection details:

```
DB_HOST=<from database service>
DB_PORT=<from database service>
DB_NAME=<from database service>
DB_USER=<from database service>
DB_PASSWORD=<from database service>
```

## Step 4: Update Database Connection (if needed)

Railway provides `DATABASE_URL` by default. If you want to use it instead of individual variables, you can update `src/database/connection.ts` to parse `DATABASE_URL`. However, the current setup using individual variables should work fine.

## Step 5: Deploy

1. Railway will automatically deploy when you push to your main branch
2. Or click **"Deploy"** in the Railway dashboard
3. Wait for the build to complete (usually 2-5 minutes)
4. Once deployed, Railway will provide a public URL like: `https://tastycompass-backend-production.up.railway.app`

## Step 6: Update iOS App Configuration

1. Copy your Railway service URL (from the **Settings** → **Networking** tab)
2. Open `TastyCompass/TastyCompass/Config.plist` in Xcode
3. Update the `BackendAPIURL` value:
   ```xml
   <key>BackendAPIURL</key>
   <string>https://your-service.up.railway.app/api</string>
   ```
4. Rebuild and run your iOS app

## Step 7: Verify Deployment

1. Check the service logs in Railway Dashboard
2. Test the health endpoint:
   ```bash
   curl https://your-service.up.railway.app/api/health
   ```
3. You should see:
   ```json
   {
     "status": "healthy",
     "uptime": ...,
     "timestamp": "..."
   }
   ```

## Environment Variables Reference

| Variable | Description | Required | Source |
|----------|-------------|----------|--------|
| `NODE_ENV` | Environment (production) | Yes | Manual |
| `USE_POSTGRES` | Enable PostgreSQL (set to `true`) | Yes | Manual |
| `PORT` | Server port (Railway sets this automatically) | Yes | Auto/Manual |
| `JWT_SECRET` | Secret for JWT tokens | Yes | Manual (generate) |
| `DB_HOST` | PostgreSQL host | Yes | From Database |
| `DB_PORT` | PostgreSQL port | Yes | From Database |
| `DB_NAME` | Database name | Yes | From Database |
| `DB_USER` | Database user | Yes | From Database |
| `DB_PASSWORD` | Database password | Yes | From Database |

## Troubleshooting

### "Error creating build plan with Nixpacks"

This error occurs when Railway can't find your `package.json`. **Solution:**

1. Go to your service in Railway Dashboard
2. Click **Settings** → **Build**
3. **Set Root Directory to**: `tastycompass-backend`
4. Save and redeploy

**Why this happens:**
- Railway looks for `package.json` in the repo root by default
- Your backend code is in the `tastycompass-backend/` subdirectory
- Setting Root Directory tells Railway where to find your code

**Alternative:** If Root Directory setting doesn't work, you can:
- Create a new service and select the `tastycompass-backend` folder directly
- Or move `package.json` to the repo root (not recommended)

### Database Connection Issues

- Verify all database environment variables are set correctly
- Check that the database service is running
- Ensure variables are linked/referenced correctly
- Check service logs for connection errors

### Build Failures

- Check that `package.json` has the correct build script
- Verify TypeScript is compiling: `npm run build` works locally
- Check build logs in Railway Dashboard
- Ensure `dist/index.js` exists after build

### Service Not Starting

- Check service logs in Railway Dashboard
- Verify `npm start` works locally
- Ensure `dist/index.js` exists
- Check that PORT environment variable is set

### Demo Account Not Created

- Check server logs for initialization messages
- Verify database connection is working
- The demo account is created automatically on first startup

## Free Tier Limitations

Railway's free tier includes:
- $5 credit per month (usually enough for small projects)
- Services may sleep after inactivity
- Database included in free tier

For production, consider upgrading to a paid plan.

## Custom Domain (Optional)

1. Go to **Settings** → **Networking**
2. Click **"Generate Domain"** or **"Custom Domain"**
3. Follow Railway's instructions to configure your domain

## Next Steps

1. Set up monitoring and alerts
2. Configure backup strategy for database
3. Set up CI/CD for automatic deployments
4. Consider adding environment-specific configurations

