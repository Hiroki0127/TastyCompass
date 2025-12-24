# Railway Setup - Step by Step

## ⚠️ CRITICAL: You MUST Set Root Directory in Railway Dashboard

The error you're seeing happens because Railway is scanning the repo root instead of the `tastycompass-backend/` folder.

## Exact Steps to Fix:

### Step 1: Open Railway Dashboard
1. Go to https://railway.app/dashboard
2. Click on your project
3. Click on your web service (the one that's failing)

### Step 2: Set Root Directory
1. Click the **"Settings"** tab (top of the page)
2. Scroll down to the **"Build"** section
3. Find the field labeled **"Root Directory"**
4. **Type exactly**: `tastycompass-backend`
   - No leading slash
   - No trailing slash
   - Just: `tastycompass-backend`
5. Click **"Save"** or **"Update"**

### Step 3: Redeploy
1. After saving, Railway should automatically trigger a new deployment
2. If not, go to the **"Deployments"** tab
3. Click **"Redeploy"** or **"Deploy"**

### Step 4: Verify
After redeploying, check the build logs. You should see:
```
Found package.json in tastycompass-backend/
Detected Node.js project
Installing dependencies...
Building...
```

## Visual Guide:

```
Railway Dashboard
├── Your Project
    ├── Your Web Service
        ├── Settings Tab ← Click here
            ├── Build Section
                ├── Root Directory: [tastycompass-backend] ← Type here
                    └── Save Button ← Click here
```

## Still Not Working?

If you've set the Root Directory but it's still failing:

1. **Delete the service and recreate it:**
   - In Railway, delete the current web service
   - Create a new one from GitHub
   - **IMMEDIATELY** go to Settings → Build → Root Directory
   - Set it to `tastycompass-backend` BEFORE the first deployment

2. **Check the Root Directory value:**
   - Make sure there are no spaces
   - Make sure it's exactly `tastycompass-backend` (lowercase)
   - No quotes, no slashes

3. **Alternative: Use Railway CLI:**
   ```bash
   railway link
   railway variables set RAILWAY_ROOT_DIRECTORY=tastycompass-backend
   ```

## Why This Is Required

Railway's build system (Nixpacks) needs to know where your `package.json` is located. By default, it looks in the repo root. Since your backend code is in a subdirectory, you must tell Railway where to look.

Without this setting, Railway sees:
- `README.md` (not a Node.js project)
- `TastyCompass/` (iOS app, not Node.js)
- No `package.json` in root → Build fails

With Root Directory set to `tastycompass-backend`, Railway sees:
- `package.json` ✅
- `src/` folder ✅
- `tsconfig.json` ✅
- Build succeeds! ✅

