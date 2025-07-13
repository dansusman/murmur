import Foundation
import Carbon

typealias KeyCode = UInt16

extension KeyCode {
    static let kVK_FN: UInt16 = 63
    static let kVK_F13: UInt16 = 105
    static let kVK_F14: UInt16 = 107
    static let kVK_F15: UInt16 = 113
    static let kVK_F16: UInt16 = 106
    static let kVK_F17: UInt16 = 64
    static let kVK_F18: UInt16 = 79
    static let kVK_F19: UInt16 = 80
    static let kVK_F20: UInt16 = 90
}

struct KeyCodeHelper {
    static func getKeyName(for keyCode: UInt32) -> String? {
        switch keyCode {
        case 0: return "A"
        case 1: return "S"
        case 2: return "D"
        case 3: return "F"
        case 4: return "H"
        case 5: return "G"
        case 6: return "Z"
        case 7: return "X"
        case 8: return "C"
        case 9: return "V"
        case 11: return "B"
        case 12: return "Q"
        case 13: return "W"
        case 14: return "E"
        case 15: return "R"
        case 16: return "Y"
        case 17: return "T"
        case 18: return "1"
        case 19: return "2"
        case 20: return "3"
        case 21: return "4"
        case 22: return "6"
        case 23: return "5"
        case 24: return "="
        case 25: return "9"
        case 26: return "7"
        case 27: return "-"
        case 28: return "8"
        case 29: return "0"
        case 30: return "]"
        case 31: return "O"
        case 32: return "U"
        case 33: return "["
        case 34: return "I"
        case 35: return "P"
        case 36: return "Return"
        case 37: return "L"
        case 38: return "J"
        case 39: return "'"
        case 40: return "K"
        case 41: return ";"
        case 42: return "\\"
        case 43: return ","
        case 44: return "/"
        case 45: return "N"
        case 46: return "M"
        case 47: return "."
        case 48: return "Tab"
        case 49: return "Space"
        case 50: return "`"
        case 51: return "Delete"
        case 53: return "Escape"
        case 55: return "Command"
        case 56: return "Shift"
        case 57: return "Caps Lock"
        case 58: return "Option"
        case 59: return "Control"
        case 60: return "Right Shift"
        case 61: return "Right Option"
        case 62: return "Right Control"
        case 63: return "FN"
        case 64: return "F17"
        case 65: return "Keypad ."
        case 67: return "Keypad *"
        case 69: return "Keypad +"
        case 71: return "Clear"
        case 75: return "Keypad /"
        case 76: return "Keypad Enter"
        case 78: return "Keypad -"
        case 79: return "F18"
        case 80: return "F19"
        case 81: return "Keypad ="
        case 82: return "Keypad 0"
        case 83: return "Keypad 1"
        case 84: return "Keypad 2"
        case 85: return "Keypad 3"
        case 86: return "Keypad 4"
        case 87: return "Keypad 5"
        case 88: return "Keypad 6"
        case 89: return "Keypad 7"
        case 90: return "F20"
        case 91: return "Keypad 8"
        case 92: return "Keypad 9"
        case 96: return "F5"
        case 97: return "F6"
        case 98: return "F7"
        case 99: return "F3"
        case 100: return "F8"
        case 101: return "F9"
        case 103: return "F11"
        case 105: return "F13"
        case 106: return "F16"
        case 107: return "F14"
        case 109: return "F10"
        case 111: return "F12"
        case 113: return "F15"
        case 114: return "Help"
        case 115: return "Home"
        case 116: return "Page Up"
        case 117: return "Forward Delete"
        case 118: return "F4"
        case 119: return "End"
        case 120: return "F2"
        case 121: return "Page Down"
        case 122: return "F1"
        case 123: return "Left Arrow"
        case 124: return "Right Arrow"
        case 125: return "Down Arrow"
        case 126: return "Up Arrow"
        default: return nil
        }
    }
    
    static func isValidHotkey(_ keyCode: UInt32) -> Bool {
        // Check if the key code is suitable for use as a hotkey
        // Avoid keys that are commonly used in other shortcuts
        let unsuitableKeys: Set<UInt32> = [
            55, // Command
            56, // Shift
            58, // Option
            59, // Control
            36, // Return
            48, // Tab
            49, // Space (unless specifically desired)
            53, // Escape
            51  // Delete
        ]
        
        return !unsuitableKeys.contains(keyCode)
    }
    
    static func getRecommendedHotkeys() -> [(name: String, keyCode: UInt32)] {
        return [
            ("FN", 63),
            ("F13", 105),
            ("F14", 107),
            ("F15", 113),
            ("F16", 106),
            ("F17", 64),
            ("F18", 79),
            ("F19", 80),
            ("F20", 90)
        ]
    }
}

// MARK: - Keyboard Event Utilities
struct KeyboardEventHelper {
    static func createKeyEvent(keyCode: CGKeyCode, keyDown: Bool, modifiers: CGEventFlags = []) -> CGEvent? {
        let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: keyDown)
        event?.flags = modifiers
        return event
    }
    
    static func simulateKeyPress(keyCode: CGKeyCode, modifiers: CGEventFlags = []) {
        guard let keyDownEvent = createKeyEvent(keyCode: keyCode, keyDown: true, modifiers: modifiers),
              let keyUpEvent = createKeyEvent(keyCode: keyCode, keyDown: false, modifiers: modifiers) else {
            return
        }
        
        keyDownEvent.post(tap: .cghidEventTap)
        keyUpEvent.post(tap: .cghidEventTap)
    }
    
    static func simulatePaste() {
        simulateKeyPress(keyCode: CGKeyCode(9), modifiers: .maskCommand) // Cmd+V
    }
    
    static func simulateCopy() {
        simulateKeyPress(keyCode: CGKeyCode(8), modifiers: .maskCommand) // Cmd+C
    }
}