# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Development Commands

### Building & Running
- **Build**: Open `Murmur.xcodeproj` in Xcode and build (⌘+B)
- **Run**: Build and run from Xcode (⌘+R)
- **Swift Package**: Uses Package.swift for dependency management (no external dependencies)

### Testing
- Use Xcode's built-in test runner (⌘+U)
- No separate test script - all testing done through Xcode

### Debugging
- Use Xcode's debugger with breakpoints
- Console logs use the custom Logger system with component-specific loggers
- Check Console.app for system logs from the Logger framework

## Architecture Overview

This is a macOS menu bar application built with SwiftUI that provides AI-powered voice transcription using Whisper.

### Core Architecture Pattern
- **Manager Pattern**: Central managers handle specific functionality (audio, hotkeys, settings, etc.)
- **Delegate Pattern**: WhisperService uses delegation for async transcription callbacks
- **Observer Pattern**: Uses @Published/@StateObject for reactive UI updates
- **State Management**: TranscriptionSession manages the app's transcription state machine

### Key Components

#### Managers (Business Logic)
- `MenuBarManager`: Handles menu bar status item and app lifecycle
- `HotkeyManager`: Global hotkey registration using Carbon framework
- `AudioManager`: Audio recording using AVFoundation
- `WhisperService`: Orchestrates transcription with WhisperCppWrapper
- `WhisperCppWrapper`: Native wrapper around whisper.cpp binary
- `TextInjector`: Accessibility-based text insertion into other apps
- `SettingsManager`: UserDefaults persistence for app settings
- `FloatingIndicatorManager`: Controls floating recording indicator window

#### Models (Data Layer)
- `AppSettings`: Codable settings structure with defaults
- `TranscriptionState`: Enum-based state machine for transcription flow
- `TranscriptionSession`: ObservableObject managing recording/transcription lifecycle

#### Views (UI Layer)
- `SettingsView`: Main settings panel
- `MenuBarView`: Menu bar dropdown content
- `HotkeyPickerView`: Hotkey selection interface
- `FloatingRecordingIndicator`: Visual recording feedback
- `FloatingRecordingWindow`: Window container for floating indicator

### Data Flow
1. User presses hotkey → `HotkeyManager` → `MenuBarManager`
2. Recording starts → `AudioManager` → `TranscriptionSession`
3. Recording stops → `WhisperService` → `WhisperCppWrapper`
4. Transcription completes → `TextInjector` → Target application

### Key Frameworks
- **SwiftUI**: Modern declarative UI
- **AppKit**: Menu bar integration and window management
- **AVFoundation**: Audio recording and processing
- **Carbon**: Global hotkey registration
- **Accessibility**: Text insertion into other applications
- **Foundation**: Core data structures and utilities

### Resource Management
- Whisper models stored in `Resources/Models/` (ggml-*.bin files)
- Whisper binary at `Resources/Binaries/whisper` (whisper.cpp compiled)
- Model selection affects transcription speed vs accuracy tradeoff

### State Management
- `TranscriptionState` enum handles: idle → recording → processing → completed/error
- `TranscriptionSession` manages timing, history, and state transitions
- Settings persist via `SettingsManager` using UserDefaults

### Security & Permissions
- Requires Microphone, Accessibility, and Input Monitoring permissions
- Uses app sandbox with specific entitlements
- No external network dependencies when using local Whisper

### Error Handling
- Custom `WhisperServiceError` for transcription failures
- Comprehensive logging via component-specific Logger instances
- Graceful degradation when permissions are missing

### Performance Considerations
- Whisper models vary in size: tiny (39MB) to large (1550MB)
- Audio processing happens on background threads
- UI updates dispatched to main thread
- Temporary audio files cleaned up after transcription

## Development Notes

### Adding New Features
- Follow the Manager pattern for new functionality
- Use the Logger system for debugging (Logger.component.level)
- Ensure proper thread handling for UI updates
- Consider accessibility and permissions requirements

### Model Management
- Models are bundled in Resources/Models/
- Add new models to WhisperModelType enum
- Update model loading logic in WhisperCppWrapper
- Consider app bundle size when adding models

### UI Development
- Use SwiftUI with @StateObject/@ObservedObject for reactive updates
- Follow existing view hierarchy patterns
- Maintain menu bar app conventions (no dock icon)
- Consider floating window positioning and behavior

### Debugging Audio Issues
- Check microphone permissions in System Preferences
- Verify audio format matches whisper.cpp expectations (16kHz WAV)
- Use AudioManager logging to trace recording pipeline
- Test with different Whisper models for accuracy issues