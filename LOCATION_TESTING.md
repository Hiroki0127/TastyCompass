# Location-Based Search Testing Guide

This guide explains how to set up and test location-based restaurant search in TastyCompass.

## 📍 Required Setup

### Step 1: Add Location Permission to Xcode Project

**IMPORTANT:** iOS requires you to explain why your app needs location access.

1. Open your project in Xcode
2. Select the **TastyCompass** project in the navigator (top-level)
3. Select the **TastyCompass** target
4. Go to the **Info** tab
5. Click the **"+"** button to add new keys
6. Add these two entries:

   | Key | Type | Value |
   |-----|------|-------|
   | `Privacy - Location When In Use Usage Description` | String | `We need your location to find restaurants near you` |
   | `Privacy - Location Always and When In Use Usage Description` | String | `We need your location to find restaurants near you` |

   **OR** if you're editing Info.plist directly:
   ```xml
   <key>NSLocationWhenInUseUsageDescription</key>
   <string>We need your location to find restaurants near you</string>
   <key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
   <string>We need your location to find restaurants near you</string>
   ```

### Step 2: Build and Run

After adding the permission keys, build and run your app (`Cmd + R`).

---

## 🧪 Testing Location Features

### Test 1: iOS Simulator (Custom Location)

1. Run the app in the iOS Simulator
2. When prompted, tap **"Allow While Using App"** for location permission
3. In the Simulator menu, go to **Features** → **Location** → Choose:
   - **Apple** (Cupertino, CA)
   - **City Bicycle Ride** (San Francisco)
   - **Custom Location...** (set your own coordinates)

### Test 2: Real Device

1. Run the app on your iPhone/iPad
2. Allow location permission when prompted
3. The app will use your actual GPS location
4. Test by moving to different locations!

### Test 3: Location Permission Denied

1. Deny location permission when first prompted
2. The app should show:
   - "Location Access Needed" message
   - "Open Settings" button
   - "Search San Francisco Instead" fallback option

---

## 🎯 Expected Behavior

### ✅ When Location Permission is Granted:

1. App acquires your current location
2. Shows "Finding restaurants..." loading state
3. Searches for restaurants within your specified radius (default 25 miles)
4. Displays results sorted by distance
5. Updates location as you move (every 100 meters)

### ✅ When Location Permission is Denied:

1. Shows friendly error message
2. Offers "Open Settings" button to enable location
3. Provides fallback: "Search San Francisco Instead"
4. Users can still search by typing city names

### ✅ Fallback Behavior:

- If no location available → Falls back to San Francisco
- If location errors → Shows error with retry option
- Users can always manually search by city name

---

## 🔧 Location Manager Features

The improved LocationManager now includes:

- ✅ **Battery-efficient**: Uses `kCLLocationAccuracyHundredMeters`
- ✅ **Smart updates**: Only updates every 100 meters
- ✅ **Error handling**: Tracks and displays location errors
- ✅ **Settings integration**: Direct link to iOS Settings
- ✅ **Status tracking**: Published authorization status
- ✅ **iOS 14+ compatible**: Uses latest delegate methods

---

## 🐛 Troubleshooting

### Problem: Location permission dialog doesn't appear

**Solution:** Make sure you added the `NSLocationWhenInUseUsageDescription` key to your project's Info settings.

### Problem: "Location services disabled" error

**Solutions:**
1. On Simulator: Features → Location → (select a location)
2. On Device: Settings → Privacy → Location Services → Enable
3. On Device: Settings → Privacy → Location Services → TastyCompass → "While Using the App"

### Problem: App uses San Francisco instead of my location

**Check:**
1. Did you grant location permission?
2. Is location services enabled on your device?
3. Are you testing in a location with GPS signal? (indoors might be weak)
4. Check Xcode console for location logs (look for 📍 emoji)

### Problem: Location is inaccurate

**Solutions:**
1. Make sure you're not in airplane mode
2. Go outside for better GPS signal
3. Wait a few seconds for GPS to acquire signal
4. On Simulator: Use "City Bicycle Ride" for realistic movement

---

## 📊 Console Logs

Watch for these helpful logs in Xcode console:

```
📍 Requesting location permission...
📍 Authorization status changed: 3 (authorized)
📍 Location updated: 37.7749, -122.4194
🔍 Starting search...
📍 Using location-based search
🌐 Making Google Places API request...
✅ Found 15 restaurants
```

---

## 🎨 User Experience Flow

1. **First Launch:**
   - App requests location permission
   - User taps "Allow While Using App"
   - App acquires location
   - Automatically searches nearby restaurants

2. **Subsequent Launches:**
   - App remembers permission status
   - Starts updating location immediately
   - Shows last search results while loading

3. **Permission Denied:**
   - Shows friendly error screen
   - "Open Settings" button
   - "Search San Francisco Instead" fallback
   - User can still search by typing

---

## ✨ Next Steps

After testing location features:

1. ✅ Test all filters (price, rating, distance, open now)
2. ✅ Test search functionality (type restaurant names)
3. ✅ Test on multiple devices/locations
4. ✅ Test with location services disabled
5. ✅ Add error handling for network issues

