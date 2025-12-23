# Deployment Guide for TastyCompass Backend

This guide covers deployment options for the TastyCompass backend.

## Available Platforms

### 🚂 Railway (Recommended - Free Tier Available)

Railway is a modern platform similar to Render with excellent free tier support.

**See:** [DEPLOYMENT_RAILWAY.md](./DEPLOYMENT_RAILWAY.md) for detailed Railway deployment instructions.

**Quick Start:**
1. Sign up at [railway.app](https://railway.app)
2. Create new project from GitHub
3. Add PostgreSQL database
4. Configure environment variables
5. Deploy!

### 🎨 Render

Render is another great option with free tier support.

**Note:** Requires available project slots on your account.

### ☁️ Other Options

- **Fly.io** - Good for global distribution
- **Heroku** - Classic platform (limited free tier)
- **DigitalOcean App Platform** - Simple deployment
- **Vercel** - Great for serverless (may need adjustments)

## Quick Comparison

| Platform | Free Tier | Database | Ease of Use | Recommended |
|----------|-----------|----------|-------------|-------------|
| Railway | ✅ $5/month credit | ✅ PostgreSQL | ⭐⭐⭐⭐⭐ | ✅ Yes |
| Render | ✅ Limited | ✅ PostgreSQL | ⭐⭐⭐⭐ | ✅ Yes |
| Fly.io | ✅ Limited | ❌ External | ⭐⭐⭐ | Maybe |
| Heroku | ❌ No longer free | ✅ Add-on | ⭐⭐⭐ | No |

## Common Steps (All Platforms)

1. **Push code to GitHub**
2. **Create database** (PostgreSQL)
3. **Configure environment variables:**
   - `USE_POSTGRES=true`
   - `JWT_SECRET=<random secret>`
   - Database connection variables
4. **Update iOS app** with backend URL
5. **Test deployment**

## iOS App Configuration

After deployment, update `Config.plist`:

```xml
<key>BackendAPIURL</key>
<string>https://your-backend-url.com/api</string>
```

## Need Help?

- Check platform-specific deployment guides
- Review service logs for errors
- Verify environment variables are set correctly
- Test health endpoint: `curl https://your-url/api/health`
