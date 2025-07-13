# Murmur Setup Guide - whisper.cpp Integration

This guide will help you set up Murmur with whisper.cpp for local AI-powered voice transcription.

## Prerequisites

- macOS 13.0 or later
- Xcode 14.0 or later
- Command Line Tools for Xcode
- Git

## Step 1: Setup whisper.cpp

Run the included setup script to download and build whisper.cpp:

```bash
cd /Users/danielsusman/murmur
./setup_whisper.sh
```

This script will:
- Clone the whisper.cpp repository
- Build a universal binary (Intel + Apple Silicon)
- Download Whisper models (tiny, base, small)
- Copy binaries and models to the app bundle

## Step 2: Create Xcode Project

1. Open Xcode
2. Create a new macOS App project
3. Choose SwiftUI for the interface
4. Set Bundle Identifier: `com.yourcompany.murmur`
5. Set Minimum Deployment Target: macOS 13.0

## Step 3: Add Source Files

Copy all the Swift files from the `Murmur/` directory to your Xcode project:

```
Murmur/
├── MurmurApp.swift
├── Managers/
│   ├── MenuBarManager.swift
│   ├── HotkeyManager.swift
│   ├── AudioManager.swift
│   ├── WhisperService.swift
│   ├── WhisperCppWrapper.swift
│   ├── TextInjector.swift
│   └── SettingsManager.swift
├── Views/
│   ├── MenuBarView.swift
│   ├── SettingsView.swift
│   └── HotkeyPickerView.swift
├── Models/
│   ├── AppSettings.swift
│   └── TranscriptionState.swift
├── Extensions/
│   └── KeyCode+Extensions.swift
└── Resources/
    ├── Info.plist
    ├── Models/ (created by setup script)
    └── Binaries/ (created by setup script)
```

## Step 4: Configure Project Settings

### 4.1 Add Resources to Bundle

1. In Xcode, right-click on your project
2. Select "Add Files to [ProjectName]"
3. Add the `Resources/Models/` directory
4. Add the `Resources/Binaries/` directory
5. Make sure "Copy items if needed" is checked
6. Select "Create folder references" (not groups)

### 4.2 Set Build Settings

1. Go to Project Settings > Build Settings
2. Set "Other Linker Flags" to include: `-framework Carbon -framework ApplicationServices`
3. Set "Enable Hardened Runtime" to "Yes"

### 4.3 Configure Entitlements

1. Add the entitlements file to your project
2. Go to Project Settings > Signing & Capabilities
3. Add "Hardened Runtime" capability
4. Configure the entitlements file path

### 4.4 Set Info.plist

1. Replace the default Info.plist with the one provided
2. Update `CFBundleIdentifier` to match your bundle ID
3. Ensure privacy usage descriptions are included

## Step 5: Configure Signing

1. Go to Project Settings > Signing & Capabilities
2. Select your development team
3. Ensure "Automatically manage signing" is enabled
4. Add required entitlements:
   - Microphone access
   - Accessibility permissions
   - Input monitoring

## Step 6: Test the Setup

1. Build and run the project
2. Check that the menu bar icon appears
3. Grant permissions when prompted:
   - Microphone access
   - Accessibility permissions
   - Input monitoring permissions

## Step 7: Verify whisper.cpp Integration

1. Open the app settings
2. Go to the "Whisper" tab
3. Verify that models are shown as available
4. Try recording a short test phrase

## Troubleshooting

### Models Not Found

If the Whisper settings show "No models found":

1. Verify the setup script ran successfully
2. Check that model files exist in `Resources/Models/`
3. Ensure models are included in the app bundle

### Binary Not Found

If you get "Whisper binary not found":

1. Check that the whisper binary exists in `Resources/Binaries/`
2. Verify the binary has execute permissions
3. Ensure the binary is included in the app bundle

### Permission Issues

If hotkeys or text insertion don't work:

1. Open System Preferences > Security & Privacy
2. Go to Privacy tab
3. Grant permissions for:
   - Microphone
   - Accessibility
   - Input Monitoring

### Build Errors

Common build issues:

1. **Missing frameworks**: Add Carbon and ApplicationServices frameworks
2. **Signing issues**: Ensure proper entitlements are configured
3. **Resource not found**: Check that Resources folder is properly added to project

## Performance Tips

1. **Start with tiny model**: Best for testing and real-time use
2. **Upgrade to base model**: Once you verify everything works
3. **Consider larger models**: Only if you need maximum accuracy
4. **Monitor CPU usage**: Larger models require more processing power

## Distribution

### For Development

The app is ready to run locally with the current setup.

### For Distribution

1. **Code signing**: Configure proper certificates
2. **Notarization**: Required for distribution outside App Store
3. **App Store**: Additional sandboxing requirements may apply

## Next Steps

1. Test the complete workflow: hotkey → record → transcribe → paste
2. Customize settings to your preferences
3. Test with different applications
4. Consider adding more features or improvements

## Support

- Check the main README.md for general information
- Review the source code for implementation details
- Test with different Whisper models to find the best balance