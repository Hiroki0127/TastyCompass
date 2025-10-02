# Quick Fix: Location Not Working

## If you're testing on iOS Simulator:

1. **Set a custom location:**
   - In Simulator menu: **Features** → **Location** → **Custom Location...**
   - Enter coordinates:
     - **Latitude:** 37.7749
     - **Longitude:** -122.4194
     - (Or use **City Bicycle Ride** preset)

2. **Restart the app**
   - Press Stop in Xcode
   - Delete the app from Simulator (long press → delete)
   - Build and Run again (`Cmd + R`)

---

## If permission dialog never appeared:

### CRITICAL: Add Location Permission to Info.plist

1. **In Xcode:**
   - Click **TastyCompass** (blue project icon at top of navigator)
   - Select **TastyCompass** under TARGETS
   - Click **Info** tab
   - Find the list of keys/values
   
2. **Add this key:**
   - Click the **"+"** button
   - Start typing: "Privacy - Location When In Use"
   - Select: **Privacy - Location When In Use Usage Description**
   - Value: **We need your location to find restaurants near you**

3. **Delete the app and reinstall:**
   - Delete app from Simulator/Device
   - Build and Run again

---

## Check Console Logs

Look for these logs in Xcode console:

**GOOD** ✅:
```
📍 Requesting location permission...
📍 Authorization status changed: 3
📍 Location updated: 37.7749, -122.4194
🔍 Starting search...
📍 Using location-based search
```

**BAD** ❌:
```
🔍 Starting search...
📍 Current location: No location
🏙️ Using city-based search (San Francisco)
```

If you see "No location", location isn't being acquired!

