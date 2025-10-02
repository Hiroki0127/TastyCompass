# API Configuration Setup

This guide explains how to set up the Google Places API for the TastyCompass app.

## For New Developers

### 1. Get Your Google Places API Key

Follow the instructions in the main README to:
- Create a Google Cloud Console project
- Enable the Places API
- Create an API key
- Set up billing (free tier available)

### 2. Configure the App

1. Copy the template configuration file:
   ```bash
   cp TastyCompass/TastyCompass/Config.plist.template TastyCompass/TastyCompass/Config.plist
   ```

2. Open `Config.plist` and replace `YOUR_GOOGLE_PLACES_API_KEY_HERE` with your actual API key.

3. **IMPORTANT**: Never commit `Config.plist` to Git. It's already in `.gitignore`.

## Security Notes

- ✅ `Config.plist` contains your real API key and is **ignored by Git**
- ✅ `Config.plist.template` is a safe template that **can be committed**
- ⚠️ Never share your API key publicly or commit it to version control
- ⚠️ Always use API key restrictions in Google Cloud Console

## Verifying Your Setup

The app will validate your API key on launch. If you see an error about missing configuration, check that:
1. `Config.plist` exists in `TastyCompass/TastyCompass/`
2. The API key is not the placeholder value
3. The Places API is enabled in Google Cloud Console

