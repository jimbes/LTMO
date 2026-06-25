# Flutter App Rebuild Guide

This guide explains how to rebuild and run the PMA Flutter application on your device.

## Prerequisites

- Flutter SDK installed and in your PATH
- Android Studio or Xcode (depending on target platform)
- A connected device (physical or emulator)
- Git repository synced with latest changes

## Installing Flutter (Linux)

If you don't have Flutter installed yet, follow these steps:

### 1. Download Flutter SDK
```bash
cd ~/development  # or any directory where you want to install Flutter
git clone https://github.com/flutter/flutter.git -b stable
```

### 2. Add Flutter to PATH
Add the Flutter binary to your system PATH. Edit your shell profile (`~/.bashrc`, `~/.zshrc`, or similar):

```bash
export PATH="$HOME/development/flutter/bin:$PATH"
```

Then reload:
```bash
source ~/.bashrc  # or source ~/.zshrc
```

### 3. Verify Installation
```bash
flutter --version
flutter doctor
```

This shows your Flutter version and checks for any missing dependencies.

### 4. Install Missing Dependencies
`flutter doctor` will tell you what's missing. Common requirements:

**For Android development:**
- Install Android SDK (via Android Studio)
- Accept Android licenses: `flutter doctor --android-licenses`

**For Linux development:**
- Install required libraries: `sudo apt-get install clang cmake git ninja-build pkg-config libgtk-3-dev`

**For general use:**
```bash
flutter pub global activate get_cli
```

### 5. Re-run Doctor to Confirm
```bash
flutter doctor
```

All checkmarks (✓) confirm Flutter is properly installed.

## After Installing Flutter

## Quick Rebuild

```bash
cd pma_flutter
flutter clean
flutter pub get
flutter run
```

## Step-by-Step Rebuild Process

### 1. Clean Previous Build
Removes all build artifacts to ensure a fresh build:
```bash
flutter clean
```

### 2. Get Dependencies
Installs or updates all pub dependencies:
```bash
flutter pub get
```

### 3. Run on Device
Builds and installs the app on your connected device:
```bash
flutter run
```

## Building for Specific Platforms

### Android
```bash
flutter run -d <device-id>
# or for release build:
flutter build apk --release
flutter build appbundle --release
```

### iOS
```bash
flutter run -d <device-id>
# or for release build:
flutter build ipa --release
```

### Web
```bash
flutter run -d chrome
# or for release build:
flutter build web --release
```

## Verbose Mode (Debugging)

If you encounter build issues, run with verbose logging:
```bash
flutter run -v
```

This shows detailed output helpful for troubleshooting.

## Common Issues

### "No devices found"
List available devices:
```bash
flutter devices
```

Make sure your device is connected and USB debugging is enabled (Android) or properly configured (iOS).

### "Pub dependencies not found"
Clear and reinstall dependencies:
```bash
flutter pub cache clean
flutter pub get
```

### Build cache issues
Force a complete rebuild:
```bash
flutter clean
rm -rf pubspec.lock
flutter pub get
flutter run
```

### Configuration changes not appearing
After updating `api_config.dart` or environment variables:
```bash
flutter clean
flutter pub get
flutter run
```

## Checking Configuration

After rebuilding, verify your backend URL is correct:

```bash
flutter run -v | grep -i "baseUrl\|api"
```

Or check the logs in the app after it launches to confirm the API connection.

## Building for Production

### Create Release Build
```bash
flutter build apk --release    # Android APK
flutter build appbundle --release  # Android App Bundle
flutter build ipa --release    # iOS
flutter build web --release    # Web
```

Output location:
- Android APK: `build/app/outputs/flutter-apk/app-release.apk`
- Android Bundle: `build/app/outputs/bundle/release/app-release.aab`
- iOS: `build/ios/iphoneos/Runner.app`
- Web: `build/web/`

## Helpful Commands

```bash
# Check Flutter version and environment
flutter doctor

# List all devices
flutter devices

# Run with a specific device ID
flutter run -d <device-id>

# Install without running
flutter install

# Get app info
flutter pub get
flutter pub outdated
```

## Notes

- Always run `flutter clean` after major config changes or when switching branches
- The first build takes longer as it compiles dependencies
- Subsequent builds are faster due to caching
- Use `-v` flag for detailed logs when troubleshooting
