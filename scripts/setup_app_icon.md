# Karatapp Logo Setup Guide

## Step 1: Prepare Your Logo Files

You need to create two image files in the `assets/icons/` directory:

### 1. Main App Icon (`app_icon.png`)
- **File**: `assets/icons/app_icon.png`
- **Size**: 1024x1024 pixels
- **Content**: Your complete logo (white rounded square with green karate figure)
- **Format**: PNG with transparency support

### 2. Foreground Icon (`app_icon_foreground.png`)
- **File**: `assets/icons/app_icon_foreground.png`
- **Size**: 1024x1024 pixels
- **Content**: Just the green karate figure (no white background)
- **Format**: PNG with transparent background
- **Purpose**: Used for Android adaptive icons

## Color Specifications

**Green Karate Figure**: #7ED321 (or similar green shade)
**Background**: #FFFFFF (white)
**Rounded Square**: White with subtle shadow/border

## Step 2: Save the Files

1. Right-click on your logo image and save it as `app_icon.png` in the `assets/icons/` folder
2. Create a version with just the karate figure (transparent background) and save as `app_icon_foreground.png`

## Step 3: Generate App Icons

Run this command in your terminal:

```bash
dart run flutter_launcher_icons:main
```

## Step 4: Clean and Rebuild

```bash
flutter clean
flutter pub get
flutter run
```

## Changing Colors Later

To change colors in the future:

1. Edit your logo files in `assets/icons/`
2. Re-run: `flutter pub run flutter_launcher_icons:main`
3. Rebuild your app

## Current Configuration

Your `pubspec.yaml` is already configured with:
- Android adaptive icons with white background
- iOS, Web, Windows, and macOS icon generation
- Proper file paths pointing to your assets

## Troubleshooting

If icons don't update:
1. Try `flutter clean` then `flutter pub get`
2. Uninstall and reinstall the app
3. Check that image files are exactly 1024x1024 pixels
4. Ensure PNG format with proper transparency
