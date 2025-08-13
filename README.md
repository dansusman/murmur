# Murmur

A lightweight macOS menu bar application for AI-powered voice transcription. Hold a hotkey to record audio, release to transcribe using Whisper AI and automatically paste the text into the active application.

I'm putting this app on pause after discovering [Voiceink](https://github.com/Beingpax/VoiceInk).

## Features

- **Global Hotkey Recording**: Hold FN key (or customize) to record audio
- **Meeting Mode**: Capture both microphone and system audio simultaneously with ScreenCaptureKit
- **Dual Hotkey System**: Normal recording (FN) and meeting mode toggle (F17)
- **Chronological Audio Mixing**: Synchronized playback of mixed microphone and system audio
- **AI Transcription**: Uses Whisper AI model for accurate speech-to-text
- **Automatic Text Insertion**: Transcribed text is automatically pasted into active text fields
- **Floating Recording Indicator**: Visual feedback with a floating indicator during recording
- **Menu Bar Interface**: Lightweight menu bar app with easy access to settings
- **Launch at Login**: Option to start automatically when macOS boots
- **Privacy First**: Local processing with Whisper (no cloud required)
- **Customizable**: Adjust hotkeys, model types, and behavior to your needs

## Requirements

- macOS 15.0 (Sequoia) or later
- Microphone access permission
- Screen recording permission (required for meeting mode system audio capture)
- Accessibility permissions (for text insertion)
- Input monitoring permission (for global hotkeys)

## Installation

### From Source

1. Clone this repository
2. Open the project in Xcode
3. Build and run the application
4. Grant required permissions when prompted

### Permissions Required

The app requires these permissions to function:

- **Microphone**: For recording audio
- **Accessibility**: For inserting text into other applications
- **Input Monitoring**: For detecting global hotkey presses

## Usage

### Normal Mode Recording

1. Launch Murmur - it will appear in your menu bar
2. Hold the hotkey (FN key by default) to start recording
3. Speak your message
4. Release the hotkey to stop recording and start transcription
5. The transcribed text will automatically be pasted into the active text field

### Meeting Mode Recording

1. Press the meeting mode toggle hotkey (F17 by default) to start recording both microphone and system audio
2. Speak and continue with your meeting/call - both your voice and system audio will be captured
3. Press the meeting mode hotkey again to stop recording
4. Audio streams are mixed chronologically and transcribed together
5. The complete transcription will be pasted into the active text field

## Configuration

### Hotkey Settings

- Access settings through the menu bar icon
- **Normal Recording**: Default hotkey is FN key (hold to record)
- **Meeting Mode**: Default hotkey is F17 key (toggle on/off)
- Recommended alternatives: F13-F20 (don't interfere with other shortcuts)
- Avoid Command, Option, Control keys

### Visual Feedback

- **Floating Recording Indicator**: Toggle the floating indicator that appears during recording
- Provides visual confirmation that recording is active

### Whisper Models

Choose between different Whisper models based on your needs:

- **Tiny** (39MB): Fastest, good for real-time use
- **Base** (142MB): Balanced speed and accuracy
- **Small** (244MB): Better accuracy, slower
- **Medium** (769MB): High accuracy, even slower
- **Large** (1550MB): Best accuracy, slowest

### API Options

- **Local Whisper** (Recommended): Process audio locally for privacy and speed
- **OpenAI API**: Cloud-based processing (requires API key and internet)

## Project Structure

```
Murmur/
├── MurmurApp.swift                 # Main app entry point
├── Managers/
│   ├── MenuBarManager.swift        # Menu bar status item
│   ├── HotkeyManager.swift         # Global hotkey handling
│   ├── AudioManager.swift          # Audio recording
│   ├── ScreenAudioRecorder.swift   # System audio capture for meeting mode
│   ├── WhisperService.swift        # AI transcription
│   ├── WhisperCppWrapper.swift     # Local Whisper integration
│   ├── TextInjector.swift          # Text insertion
│   ├── SettingsManager.swift       # User preferences
│   └── FloatingIndicatorManager.swift # Floating recording indicator
├── Views/
│   ├── MenuBarView.swift           # Menu bar dropdown
│   ├── SettingsView.swift          # Settings panel
│   ├── HotkeyPickerView.swift      # Hotkey selection UI
│   ├── FloatingRecordingIndicator.swift # Recording indicator UI
│   └── FloatingRecordingWindow.swift # Recording window container
├── Models/
│   ├── AppSettings.swift           # Settings data model
│   └── TranscriptionState.swift    # App state management
├── Extensions/
│   └── KeyCode+Extensions.swift    # Keyboard handling utilities
├── Utils/
│   └── Logger.swift                # Logging utilities
├── Resources/
│   ├── Info.plist                  # App metadata & permissions
│   ├── Binaries/
│   │   └── whisper                 # Local Whisper binary
│   └── Models/
│       ├── ggml-base.bin           # Whisper base model
│       ├── ggml-tiny.bin           # Whisper tiny model
│       └── model_info.json         # Model metadata
└── Entitlements/
    └── Murmur.entitlements        # Security entitlements
```

## Development

### Building

1. Open `Murmur.xcodeproj` in Xcode
2. Set your development team in project settings
3. Build and run

### Dependencies

The app uses only built-in macOS frameworks:

- **SwiftUI**: Modern UI framework
- **AppKit**: Menu bar integration
- **AVFoundation**: Audio recording
- **ScreenCaptureKit**: System audio capture for meeting mode
- **Carbon**: Global hotkey registration
- **Accessibility**: Text insertion into other apps

### Whisper Integration

The app supports both local and cloud Whisper processing:

- **Local**: Uses whisper.cpp for local processing
- **Cloud**: Uses OpenAI Whisper API

## Privacy

- All audio processing can be done locally
- No data is sent to external servers (when using local Whisper)
- Microphone access is only used during active recording
- No persistent storage of audio data

## Troubleshooting

### Common Issues

1. **Hotkey not working**: Check Input Monitoring permissions in System Preferences
2. **Text not inserting**: Verify Accessibility permissions are granted
3. **No audio recording**: Check Microphone permissions
4. **App won't start**: Ensure macOS 12.0 or later

### Permissions

If permissions are denied:
1. Open System Preferences > Security & Privacy
2. Grant required permissions for Murmur
3. Restart the application

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## Acknowledgments

- OpenAI for the Whisper AI model
- ggerganov for whisper.cpp implementation
