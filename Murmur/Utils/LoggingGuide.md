# Logging System Guide

## Overview
The Murmur app uses a custom logging system that provides structured logging with emoji indicators, component identification, and configurable log levels. This replaces the previous `print()` statements with a more robust solution.

## Usage

### Basic Logging
```swift
// Use static loggers - no need for instance variables
Logger.audio.info("🎤 Starting audio recording")
Logger.audio.error("Failed to initialize audio engine")
Logger.audio.success("✅ Audio recording completed")
Logger.audio.warning("⚠️ Low audio levels detected")
Logger.audio.debug("🔧 Audio format: 16kHz, mono")
```

### Available Log Levels
- `debug` 🔍 - Detailed debugging information
- `info` ℹ️ - General information
- `warning` ⚠️ - Warning messages
- `error` ❌ - Error messages
- `success` ✅ - Success messages

### Pre-configured Static Loggers
- `Logger.audio` - AudioManager (works in static and instance methods)
- `Logger.hotkey` - HotkeyManager (works in static and instance methods)
- `Logger.menuBar` - MenuBarManager (works in static and instance methods)
- `Logger.textInjector` - TextInjector (works in static and instance methods)
- `Logger.whisper` - WhisperService (works in static and instance methods)
- `Logger.settings` - SettingsManager (works in static and instance methods)
- `Logger.app` - MurmurApp (works in static and instance methods)

### Configuration
```swift
// Enable/disable logging
Logger.isEnabled = true

// Set minimum log level
Logger.minimumLevel = .info  // Only show info, warning, error, success
```

## Features

### Debug vs Production
- In DEBUG builds: Logs to both console and os_log
- In production: Only logs to os_log (viewable in Console.app)

### Emoji Indicators
The system maintains the visual emoji style from the original logging:
- 🎤 Audio operations
- 🔥 Hotkey events
- 🔧 Setup/configuration
- 🔄 State changes
- 📝 Text injection
- 🛑 Stop operations

### Component Identification
Each log message is automatically prefixed with the component name:
```
[AudioManager] 🎤 Starting recording
[HotkeyManager] 🔥 Hotkey pressed
```

### Structured Logging
All logs include:
- Timestamp
- Component name
- Log level emoji
- Message content
- System integration (os_log)

## Migration from print()
All existing `print()` statements have been replaced:
- `print("[AudioManager] 🎤 message")` → `Logger.audio.info("🎤 message")`
- Component prefixes are now automatic
- Log levels are properly categorized
- Emoji indicators are preserved
- Static loggers work in both static and instance methods

## Best Practices
1. Use appropriate log levels (don't log everything as `info`)
2. Keep emoji indicators for visual consistency
3. Use the pre-configured static loggers for each component
4. Avoid logging sensitive information
5. Use `debug()` for detailed technical information
6. Use `info()` for general operational messages
7. Use `warning()` for non-critical issues
8. Use `error()` for failures and exceptions
9. Use `success()` for completed operations
10. Static loggers work from anywhere - no need for instance variables