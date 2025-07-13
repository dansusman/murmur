# Recording Border Indicator Feature

## Overview
Visual border overlay that appears around the active window during voice recording to clearly indicate:
1. Recording is currently active
2. Which window will receive the transcribed text

## Core Design Principles
- **Static**: No animations, simple rectangle border
- **Non-intrusive**: Transparent overlay, mouse events pass through
- **Customizable**: User controls color and thickness
- **Robust**: Graceful degradation if permissions unavailable
- **Efficient**: Minimal resource usage with Core Graphics

## Architecture

### 1. Core Components

#### RecordingBorderView (NSView)
```swift
class RecordingBorderView: NSView {
    var borderColor: NSColor
    var borderWidth: CGFloat
    
    override func draw(_ dirtyRect: NSRect) {
        // Use NSBezierPath to draw border rectangle
        // Fill transparent, stroke with borderColor/borderWidth
    }
}
```

#### RecordingBorderWindow (NSWindow)
```swift
class RecordingBorderWindow: NSWindow {
    // Configuration:
    // - styleMask: .borderless
    // - backgroundColor: .clear
    // - isOpaque: false
    // - level: .floating
    // - ignoresMouseEvents: true
    // - canBecomeKey: false
    // - canBecomeMain: false
}
```

#### RecordingIndicatorManager
```swift
class RecordingIndicatorManager {
    private var borderWindow: RecordingBorderWindow?
    private var targetWindowBounds: CGRect?
    
    func showRecordingBorder()
    func hideRecordingBorder()
    private func captureActiveWindowBounds() -> CGRect?
    private func createBorderWindow(for bounds: CGRect)
}
```

### 2. Active Window Detection

#### Primary Method: NSWorkspace + Accessibility API
```swift
// Get frontmost application
let workspace = NSWorkspace.shared
let frontmostApp = workspace.frontmostApplication

// Use AXUIElement to get focused window bounds
let appElement = AXUIElementCreateApplication(frontmostApp.processIdentifier)
// Query for focused window frame using kAXFocusedWindowAttribute
```

#### Fallback Method: CGWindowListCopyWindowInfo
```swift
// If accessibility fails, use Core Graphics window list
let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID)
// Filter for frontmost app windows, find topmost
```

### 3. Settings Integration

#### BorderSettings Structure
```swift
struct BorderSettings {
    var isEnabled: Bool = true
    var color: NSColor = .systemRed
    var thickness: CGFloat = 3.0
    
    // Convenience for common colors
    static let presetColors: [NSColor] = [
        .systemRed, .systemBlue, .systemGreen, 
        .systemOrange, .systemPurple, .controlAccentColor
    ]
}
```

#### Settings Storage
- Use UserDefaults for persistence
- Keys: `recording_border_enabled`, `recording_border_color`, `recording_border_thickness`
- Color stored as archived NSColor data

### 4. Integration Points

#### MenuBarManager Integration
```swift
class MenuBarManager {
    private let indicatorManager = RecordingIndicatorManager()
    
    // Modified methods:
    func startRecording() {
        // Show border immediately when recording starts
        indicatorManager.showRecordingBorder()
        // ... existing recording logic
    }
    
    func stopRecording() {
        // Hide border immediately when recording stops
        indicatorManager.hideRecordingBorder()
        // ... existing stop logic
    }
}
```

#### Settings UI Integration
- Add "Recording Indicator" section to existing settings
- Color picker component
- Thickness slider (1-10px range)
- Enable/disable toggle
- Live preview when adjusting settings

## Implementation Steps

### Phase 1: Core Infrastructure
1. **Create RecordingBorderView**
   - Custom NSView with draw(_:) override
   - NSBezierPath border drawing
   - Color and thickness properties

2. **Create RecordingBorderWindow**
   - Borderless, transparent window configuration
   - Mouse event pass-through
   - Proper window level for overlay

3. **Create RecordingIndicatorManager**
   - Window lifecycle management
   - Active window detection logic
   - Error handling and graceful degradation

### Phase 2: Window Detection
1. **Implement Accessibility API integration**
   - NSWorkspace frontmost app detection
   - AXUIElement window bounds query
   - Permission checking and handling

2. **Add Core Graphics fallback**
   - CGWindowListCopyWindowInfo implementation
   - Window filtering logic
   - Coordinate system handling

3. **Multi-monitor support**
   - Screen bounds validation
   - Coordinate space conversion
   - Retina display scaling

### Phase 3: Settings System
1. **Create BorderSettings model**
   - Data structure and defaults
   - UserDefaults persistence
   - Color serialization/deserialization

2. **Settings UI components**
   - Color picker interface
   - Thickness slider
   - Enable/disable toggle
   - Live preview functionality

3. **Settings integration**
   - Load settings on app launch
   - Apply changes immediately
   - Settings validation

### Phase 4: Recording Integration
1. **MenuBarManager modifications**
   - Border show/hide calls
   - Error handling integration
   - State management

2. **Permission handling**
   - Accessibility permission checks
   - User guidance for permission setup
   - Graceful degradation without permissions

3. **Testing and edge cases**
   - Fullscreen app handling
   - Window state changes
   - Multi-monitor scenarios
   - Error recovery

## User Customization Options

### Supported Customizations
- **Border Color**: Color picker with presets + custom colors
- **Border Thickness**: Slider from 1-10 pixels
- **Enable/Disable**: Toggle to turn feature on/off entirely

### Preset Color Options
- System Red (default)
- System Blue
- System Green
- System Orange
- System Purple
- System Accent Color (follows user's system preference)
- Custom color picker for any color

### Not Supported (Keep Simple)
- ❌ Animations or pulsing effects
- ❌ Border styles (dashed, dotted, etc.)
- ❌ Corner radius customization
- ❌ Opacity/transparency settings
- ❌ Multiple border colors
- ❌ Border position offset
- ❌ Different border styles per app

## Dependencies & Requirements

### System Requirements
- **macOS**: Minimum version supporting NSWorkspace and Accessibility APIs
- **Permissions**: Accessibility access (essential for window detection)
- **Optional**: Screen Recording permission (fallback method only)

### Code Dependencies
- **AppKit**: NSWindow, NSView, NSWorkspace, NSBezierPath
- **Accessibility**: AXUIElement APIs
- **Core Graphics**: CGWindowListCopyWindowInfo (fallback)
- **Foundation**: UserDefaults for settings persistence

### Permission Handling
```swift
// Check accessibility permission
func checkAccessibilityPermission() -> Bool {
    return AXIsProcessTrusted()
}

// Request permission with user guidance
func requestAccessibilityPermission() {
    // Show alert explaining feature need
    // Guide user to System Preferences > Security & Privacy > Accessibility
}
```

## Error Handling & Edge Cases

### Graceful Degradation
- **No permissions**: Record without border, show settings explanation
- **Window detection fails**: Continue recording, log error
- **Invalid window bounds**: Skip border display
- **Multi-monitor edge cases**: Validate coordinates before display

### Edge Case Handling
1. **Fullscreen apps**: Detect fullscreen state, skip border or adapt
2. **Window minimized during recording**: Keep border visible (user's choice)
3. **Window resized during recording**: Accept misalignment (static approach)
4. **App switching during recording**: Keep original border (static approach)
5. **Monitor disconnection**: Handle coordinate system changes
6. **Window closed during recording**: Border remains until recording ends

### Error Recovery
```swift
func showRecordingBorder() {
    do {
        guard checkAccessibilityPermission() else {
            // Log and continue without border
            return
        }
        
        guard let bounds = captureActiveWindowBounds() else {
            // Log and continue without border
            return
        }
        
        createAndShowBorderWindow(for: bounds)
    } catch {
        // Log error, never block recording flow
        print("Border display failed: \(error)")
    }
}
```

## Testing Strategy

### Manual Testing Scenarios
1. **Basic functionality**: Start/stop recording with border display
2. **Permission states**: Test with/without accessibility permissions
3. **Window states**: Test with minimized, fullscreen, resized windows
4. **Multi-monitor**: Test window detection across monitors
5. **App switching**: Test recording with app switching mid-recording
6. **Settings changes**: Test live updates of color/thickness
7. **Edge cases**: Test with no active windows, invalid window data

### Automated Testing
- Unit tests for window detection logic
- Settings persistence tests
- Error handling validation
- Coordinate conversion accuracy

## Future Enhancements (Not in Initial Scope)

### Potential Future Features
- Border shape options (rounded corners)
- App-specific border settings
- Keyboard shortcut to toggle border mid-recording
- Border preview in settings
- Multiple border styles
- Integration with system appearance (dark/light mode)

### Architecture Considerations for Future
- Settings system designed for extension
- Manager pattern allows feature additions
- Clean separation between detection, display, and settings