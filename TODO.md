# Unit Testing Implementation Plan

## Overview
Create comprehensive unit tests for the Murmur macOS menu bar application using Swift Testing framework. The project currently has zero test coverage, so we'll build a complete testing foundation from scratch.

## Phase 1: Test Infrastructure Setup

### 1. Add Swift Testing Framework to Xcode Project
- Create new Unit Test target in Murmur.xcodeproj configured for Swift Testing
- Add Swift Testing framework dependency
- Configure test target settings and build phases
- Set up test bundle configuration with proper entitlements

### 2. Create Test Directory Structure
```
MurmurTests/
├── Managers/           # Manager component tests
├── Models/             # Model and data structure tests  
├── Utils/              # Utility and extension tests
├── Mocks/              # Mock objects and test doubles
└── Integration/        # Integration tests
```

## Phase 2: Core Model Tests

### 3. AppSettings Tests (`MurmurTests/Models/AppSettingsTests.swift`)
- **Default Values**: Test initialization with proper defaults
- **Codable Compliance**: Test JSON encoding/decoding roundtrips
- **Property Validation**: Test constraints and value ranges
- **Settings Persistence**: Test UserDefaults integration

### 4. TranscriptionState Tests (`MurmurTests/Models/TranscriptionStateTests.swift`)
- **State Transitions**: Test valid state machine transitions
  - idle → recording → processing → completed
  - idle → recording → processing → error
- **Invalid Transitions**: Ensure invalid state changes are handled
- **Enum Properties**: Test associated values and descriptions

## Phase 3: Manager Layer Tests

### 5. SettingsManager Tests (`MurmurTests/Managers/SettingsManagerTests.swift`)
- **Persistence Operations**: Test save/load to UserDefaults
- **Default Fallbacks**: Test behavior when settings don't exist
- **Settings Validation**: Test invalid setting value handling
- **Thread Safety**: Test concurrent access to settings

### 6. HotkeyManager Tests (`MurmurTests/Managers/HotkeyManagerTests.swift`)
- **Registration/Unregistration**: Test hotkey lifecycle
- **Carbon Framework Interaction**: Test with mocked Carbon calls
- **Delegate Callbacks**: Test hotkey press event handling
- **Error Scenarios**: Test registration failures and recovery

### 7. AudioManager Tests (`MurmurTests/Managers/AudioManagerTests.swift`)
- **Recording Lifecycle**: Test start/stop recording workflow
- **Audio Format Configuration**: Test 16kHz WAV format setup
- **Permission Handling**: Test microphone permission checks
- **File Management**: Test temporary file creation/cleanup
- **Error Handling**: Test audio session failures

### 8. WhisperService Tests (`MurmurTests/Managers/WhisperServiceTests.swift`)
- **Transcription Orchestration**: Test end-to-end transcription flow
- **Delegate Pattern**: Test async callback handling
- **Model Selection**: Test different Whisper model configurations
- **Error Recovery**: Test transcription failure scenarios
- **Resource Management**: Test proper cleanup of resources

### 9. TextInjector Tests (`MurmurTests/Managers/TextInjectorTests.swift`)
- **Accessibility Integration**: Test text insertion via Accessibility API
- **Permission Validation**: Test accessibility permission checks
- **Target Application Detection**: Test active app identification
- **Text Formatting**: Test text preparation and insertion
- **Fallback Mechanisms**: Test clipboard fallback when direct injection fails

### 10. FloatingIndicatorManager Tests (`MurmurTests/Managers/FloatingIndicatorManagerTests.swift`)
- **Window Positioning**: Test indicator placement logic
- **State Management**: Test show/hide operations
- **Multi-Display Support**: Test behavior across multiple monitors
- **Window Lifecycle**: Test proper window creation/disposal

## Phase 4: Utility and Support Tests

### 11. Logger Tests (`MurmurTests/Utils/LoggerTests.swift`)
- **Component Loggers**: Test component-specific logger creation
- **Log Level Filtering**: Test debug/info/error level handling
- **Output Formatting**: Test log message structure
- **Performance**: Test logging overhead

### 12. KeyCode+Extensions Tests (`MurmurTests/Extensions/KeyCodeExtensionsTests.swift`)
- **Key Mapping**: Test key code to human-readable string conversion
- **Special Keys**: Test modifier keys and function keys
- **Edge Cases**: Test invalid or unknown key codes

## Phase 5: Mock Infrastructure

### 13. Create Mock Objects (`MurmurTests/Mocks/`)
- **MockAudioManager**: Simulate audio recording without hardware
- **MockWhisperService**: Simulate transcription without actual processing
- **MockHotkeyManager**: Simulate hotkey events for testing
- **MockTextInjector**: Simulate text insertion for testing
- **MockWhisperCppWrapper**: Mock the native whisper.cpp interface

## Phase 6: Integration Tests

### 14. TranscriptionSession Integration Tests (`MurmurTests/Integration/TranscriptionSessionTests.swift`)
- **End-to-End Workflow**: Test complete transcription flow
- **State Coordination**: Test state machine across multiple components
- **Error Propagation**: Test error handling across component boundaries
- **Performance Testing**: Test transcription timing and resource usage

## Swift Testing Framework Features

### Modern Testing Syntax
- Use `@Test` attribute for test functions
- Leverage `#expect()` for assertions with better error messages
- Use `@Suite` for organized test groupings
- Implement parameterized tests with `@Test(.arguments())`

### Async Testing Support
- Use `async` test functions for testing async manager operations
- Test concurrent operations with proper async/await patterns
- Validate timing-sensitive operations

### Test Organization
- Group related tests using `@Suite` attributes
- Use descriptive test names that explain the scenario
- Implement `@Test(.disabled)` for temporarily disabled tests
- Use tags for categorizing tests (e.g., `.tags(.integration)`)

## Testing Strategy

### Component Isolation
- Test each manager in isolation using dependency injection
- Mock external dependencies (system frameworks, file system, network)
- Focus on business logic rather than framework integration

### Error Path Coverage
- Test all error conditions and edge cases
- Verify proper error propagation and handling
- Test recovery mechanisms and fallback behaviors

### Performance Considerations
- Test with different Whisper model sizes
- Validate memory usage during long recording sessions
- Test concurrent transcription scenarios

## Expected Deliverables
- ✅ 14 test files covering all major components
- ✅ Mock infrastructure for system dependencies  
- ✅ Xcode test target configured for Swift Testing
- ✅ Comprehensive test coverage for critical business logic
- ✅ Foundation for future UI testing capabilities
- ✅ Automated test execution via Xcode (⌘+U)

## Development Workflow
1. Implement tests alongside feature development
2. Run tests frequently during development (⌘+U)
3. Maintain >80% code coverage for critical components
4. Use tests as documentation for component behavior
5. Refactor with confidence using comprehensive test suite
