# Supabase Configuration Setup

## Current Issue
Your app is experiencing network connectivity issues because the Supabase configuration is not properly set up. The app is trying to connect to `asvyjiuphcqfmwdpivsr.supabase.co` but doesn't have the proper API key.

## Quick Fix

### Option 1: Create .env file (Recommended)
Create a `.env` file in the root directory of your project with the following content:

```env
# Supabase Configuration
SUPABASE_URL=https://asvyjiuphcqfmwdpivsr.supabase.co
SUPABASE_ANON_KEY=your_actual_supabase_anon_key_here

# App Configuration
APP_NAME=Karatapp
APP_VERSION=1.0.0
ENVIRONMENT=development
```

**Important**: Replace `your_actual_supabase_anon_key_here` with your real Supabase anonymous key from your Supabase dashboard.

### Option 2: Update environment.dart directly
If you can't create a `.env` file, you can update the fallback values in `lib/config/environment.dart`:

```dart
static String get supabaseAnonKey => dotenv.env['SUPABASE_ANON_KEY'] ?? 'your_actual_supabase_anon_key_here';
```

## How to Get Your Supabase Anon Key

1. Go to your Supabase dashboard: https://supabase.com/dashboard
2. Select your project
3. Go to Settings → API
4. Copy the "anon public" key
5. Replace the placeholder in your configuration

## Offline Mode Improvements

The app now has improved offline handling:

✅ **Network Error Detection**: The app now properly detects network errors and switches to offline mode
✅ **Graceful Image Loading**: Image loading failures no longer crash the app
✅ **Connection Status**: Real-time connection status indicators
✅ **Retry Mechanisms**: Automatic retry with exponential backoff
✅ **Offline Indicators**: Clear visual feedback when offline

## Testing

After setting up the configuration:

1. **With Internet**: The app should connect to Supabase and load data normally
2. **Without Internet**: The app should show offline indicators and work with cached data
3. **Network Issues**: The app should gracefully handle connection problems

## Troubleshooting

If you're still seeing connection errors:

1. Verify your Supabase URL and API key are correct
2. Check your internet connection
3. Ensure your Supabase project is active and accessible
4. Check the app logs for more specific error messages

The app will now work in offline mode even without proper Supabase configuration, but you'll need the correct API key for full functionality.
