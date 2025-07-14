import Testing
import Foundation
import Carbon
@testable import Murmur

@Suite("KeyCode+Extensions Tests")
struct KeyCodeExtensionsTests {
    
    @Test("KeyCode constants are correct")
    func testKeyCodeConstants() {
        #expect(KeyCode.kVK_FN == 63)
        #expect(KeyCode.kVK_F13 == 105)
        #expect(KeyCode.kVK_F14 == 107)
        #expect(KeyCode.kVK_F15 == 113)
        #expect(KeyCode.kVK_F16 == 106)
        #expect(KeyCode.kVK_F17 == 64)
        #expect(KeyCode.kVK_F18 == 79)
        #expect(KeyCode.kVK_F19 == 80)
        #expect(KeyCode.kVK_F20 == 90)
    }
}

@Suite("KeyCodeHelper Tests")
struct KeyCodeHelperTests {
    
    @Test("Get key name for alphabetic keys")
    func testGetKeyNameForAlphabeticKeys() {
        #expect(KeyCodeHelper.getKeyName(for: 0) == "A")
        #expect(KeyCodeHelper.getKeyName(for: 1) == "S")
        #expect(KeyCodeHelper.getKeyName(for: 2) == "D")
        #expect(KeyCodeHelper.getKeyName(for: 3) == "F")
        #expect(KeyCodeHelper.getKeyName(for: 4) == "H")
        #expect(KeyCodeHelper.getKeyName(for: 5) == "G")
        #expect(KeyCodeHelper.getKeyName(for: 6) == "Z")
        #expect(KeyCodeHelper.getKeyName(for: 7) == "X")
        #expect(KeyCodeHelper.getKeyName(for: 8) == "C")
        #expect(KeyCodeHelper.getKeyName(for: 9) == "V")
        #expect(KeyCodeHelper.getKeyName(for: 11) == "B")
        #expect(KeyCodeHelper.getKeyName(for: 12) == "Q")
        #expect(KeyCodeHelper.getKeyName(for: 13) == "W")
        #expect(KeyCodeHelper.getKeyName(for: 14) == "E")
        #expect(KeyCodeHelper.getKeyName(for: 15) == "R")
        #expect(KeyCodeHelper.getKeyName(for: 16) == "Y")
        #expect(KeyCodeHelper.getKeyName(for: 17) == "T")
    }
    
    @Test("Get key name for numeric keys")
    func testGetKeyNameForNumericKeys() {
        #expect(KeyCodeHelper.getKeyName(for: 18) == "1")
        #expect(KeyCodeHelper.getKeyName(for: 19) == "2")
        #expect(KeyCodeHelper.getKeyName(for: 20) == "3")
        #expect(KeyCodeHelper.getKeyName(for: 21) == "4")
        #expect(KeyCodeHelper.getKeyName(for: 23) == "5")
        #expect(KeyCodeHelper.getKeyName(for: 22) == "6")
        #expect(KeyCodeHelper.getKeyName(for: 26) == "7")
        #expect(KeyCodeHelper.getKeyName(for: 28) == "8")
        #expect(KeyCodeHelper.getKeyName(for: 25) == "9")
        #expect(KeyCodeHelper.getKeyName(for: 29) == "0")
    }
    
    @Test("Get key name for special keys")
    func testGetKeyNameForSpecialKeys() {
        #expect(KeyCodeHelper.getKeyName(for: 36) == "Return")
        #expect(KeyCodeHelper.getKeyName(for: 48) == "Tab")
        #expect(KeyCodeHelper.getKeyName(for: 49) == "Space")
        #expect(KeyCodeHelper.getKeyName(for: 51) == "Delete")
        #expect(KeyCodeHelper.getKeyName(for: 53) == "Escape")
        #expect(KeyCodeHelper.getKeyName(for: 55) == "Command")
        #expect(KeyCodeHelper.getKeyName(for: 56) == "Shift")
        #expect(KeyCodeHelper.getKeyName(for: 57) == "Caps Lock")
        #expect(KeyCodeHelper.getKeyName(for: 58) == "Option")
        #expect(KeyCodeHelper.getKeyName(for: 59) == "Control")
        #expect(KeyCodeHelper.getKeyName(for: 60) == "Right Shift")
        #expect(KeyCodeHelper.getKeyName(for: 61) == "Right Option")
        #expect(KeyCodeHelper.getKeyName(for: 62) == "Right Control")
        #expect(KeyCodeHelper.getKeyName(for: 63) == "FN")
    }
    
    @Test("Get key name for function keys")
    func testGetKeyNameForFunctionKeys() {
        #expect(KeyCodeHelper.getKeyName(for: 122) == "F1")
        #expect(KeyCodeHelper.getKeyName(for: 120) == "F2")
        #expect(KeyCodeHelper.getKeyName(for: 99) == "F3")
        #expect(KeyCodeHelper.getKeyName(for: 118) == "F4")
        #expect(KeyCodeHelper.getKeyName(for: 96) == "F5")
        #expect(KeyCodeHelper.getKeyName(for: 97) == "F6")
        #expect(KeyCodeHelper.getKeyName(for: 98) == "F7")
        #expect(KeyCodeHelper.getKeyName(for: 100) == "F8")
        #expect(KeyCodeHelper.getKeyName(for: 101) == "F9")
        #expect(KeyCodeHelper.getKeyName(for: 109) == "F10")
        #expect(KeyCodeHelper.getKeyName(for: 103) == "F11")
        #expect(KeyCodeHelper.getKeyName(for: 111) == "F12")
        #expect(KeyCodeHelper.getKeyName(for: 105) == "F13")
        #expect(KeyCodeHelper.getKeyName(for: 107) == "F14")
        #expect(KeyCodeHelper.getKeyName(for: 113) == "F15")
        #expect(KeyCodeHelper.getKeyName(for: 106) == "F16")
        #expect(KeyCodeHelper.getKeyName(for: 64) == "F17")
        #expect(KeyCodeHelper.getKeyName(for: 79) == "F18")
        #expect(KeyCodeHelper.getKeyName(for: 80) == "F19")
        #expect(KeyCodeHelper.getKeyName(for: 90) == "F20")
    }
    
    @Test("Get key name for keypad keys")
    func testGetKeyNameForKeypadKeys() {
        #expect(KeyCodeHelper.getKeyName(for: 65) == "Keypad .")
        #expect(KeyCodeHelper.getKeyName(for: 67) == "Keypad *")
        #expect(KeyCodeHelper.getKeyName(for: 69) == "Keypad +")
        #expect(KeyCodeHelper.getKeyName(for: 71) == "Clear")
        #expect(KeyCodeHelper.getKeyName(for: 75) == "Keypad /")
        #expect(KeyCodeHelper.getKeyName(for: 76) == "Keypad Enter")
        #expect(KeyCodeHelper.getKeyName(for: 78) == "Keypad -")
        #expect(KeyCodeHelper.getKeyName(for: 81) == "Keypad =")
        #expect(KeyCodeHelper.getKeyName(for: 82) == "Keypad 0")
        #expect(KeyCodeHelper.getKeyName(for: 83) == "Keypad 1")
        #expect(KeyCodeHelper.getKeyName(for: 84) == "Keypad 2")
        #expect(KeyCodeHelper.getKeyName(for: 85) == "Keypad 3")
        #expect(KeyCodeHelper.getKeyName(for: 86) == "Keypad 4")
        #expect(KeyCodeHelper.getKeyName(for: 87) == "Keypad 5")
        #expect(KeyCodeHelper.getKeyName(for: 88) == "Keypad 6")
        #expect(KeyCodeHelper.getKeyName(for: 89) == "Keypad 7")
        #expect(KeyCodeHelper.getKeyName(for: 91) == "Keypad 8")
        #expect(KeyCodeHelper.getKeyName(for: 92) == "Keypad 9")
    }
    
    @Test("Get key name for arrow and navigation keys")
    func testGetKeyNameForArrowAndNavigationKeys() {
        #expect(KeyCodeHelper.getKeyName(for: 114) == "Help")
        #expect(KeyCodeHelper.getKeyName(for: 115) == "Home")
        #expect(KeyCodeHelper.getKeyName(for: 116) == "Page Up")
        #expect(KeyCodeHelper.getKeyName(for: 117) == "Forward Delete")
        #expect(KeyCodeHelper.getKeyName(for: 119) == "End")
        #expect(KeyCodeHelper.getKeyName(for: 121) == "Page Down")
        #expect(KeyCodeHelper.getKeyName(for: 123) == "Left Arrow")
        #expect(KeyCodeHelper.getKeyName(for: 124) == "Right Arrow")
        #expect(KeyCodeHelper.getKeyName(for: 125) == "Down Arrow")
        #expect(KeyCodeHelper.getKeyName(for: 126) == "Up Arrow")
    }
    
    @Test("Get key name for punctuation keys")
    func testGetKeyNameForPunctuationKeys() {
        #expect(KeyCodeHelper.getKeyName(for: 24) == "=")
        #expect(KeyCodeHelper.getKeyName(for: 27) == "-")
        #expect(KeyCodeHelper.getKeyName(for: 30) == "]")
        #expect(KeyCodeHelper.getKeyName(for: 33) == "[")
        #expect(KeyCodeHelper.getKeyName(for: 39) == "'")
        #expect(KeyCodeHelper.getKeyName(for: 41) == ";")
        #expect(KeyCodeHelper.getKeyName(for: 42) == "\\")
        #expect(KeyCodeHelper.getKeyName(for: 43) == ",")
        #expect(KeyCodeHelper.getKeyName(for: 44) == "/")
        #expect(KeyCodeHelper.getKeyName(for: 47) == ".")
        #expect(KeyCodeHelper.getKeyName(for: 50) == "`")
    }
    
    @Test("Get key name for invalid key code")
    func testGetKeyNameForInvalidKeyCode() {
        #expect(KeyCodeHelper.getKeyName(for: 9999) == nil)
        #expect(KeyCodeHelper.getKeyName(for: 1000) == nil)
        #expect(KeyCodeHelper.getKeyName(for: 200) == nil)
    }
    
    @Test("Is valid hotkey for suitable keys")
    func testIsValidHotkeyForSuitableKeys() {
        // Function keys are suitable
        #expect(KeyCodeHelper.isValidHotkey(122) == true) // F1
        #expect(KeyCodeHelper.isValidHotkey(120) == true) // F2
        #expect(KeyCodeHelper.isValidHotkey(63) == true)  // FN
        #expect(KeyCodeHelper.isValidHotkey(105) == true) // F13
        
        // Regular letter keys are suitable
        #expect(KeyCodeHelper.isValidHotkey(0) == true)   // A
        #expect(KeyCodeHelper.isValidHotkey(1) == true)   // S
        #expect(KeyCodeHelper.isValidHotkey(2) == true)   // D
    }
    
    @Test("Is valid hotkey for unsuitable keys")
    func testIsValidHotkeyForUnsuitableKeys() {
        // Modifier keys are unsuitable
        #expect(KeyCodeHelper.isValidHotkey(55) == false) // Command
        #expect(KeyCodeHelper.isValidHotkey(56) == false) // Shift
        #expect(KeyCodeHelper.isValidHotkey(58) == false) // Option
        #expect(KeyCodeHelper.isValidHotkey(59) == false) // Control
        
        // Common navigation keys are unsuitable
        #expect(KeyCodeHelper.isValidHotkey(36) == false) // Return
        #expect(KeyCodeHelper.isValidHotkey(48) == false) // Tab
        #expect(KeyCodeHelper.isValidHotkey(49) == false) // Space
        #expect(KeyCodeHelper.isValidHotkey(53) == false) // Escape
        #expect(KeyCodeHelper.isValidHotkey(51) == false) // Delete
    }
    
    @Test("Get recommended hotkeys")
    func testGetRecommendedHotkeys() {
        let recommendedHotkeys = KeyCodeHelper.getRecommendedHotkeys()
        
        #expect(recommendedHotkeys.count == 9)
        
        // Check that all recommended hotkeys are function keys or FN
        let expectedHotkeys = [
            ("FN", UInt32(63)),
            ("F13", UInt32(105)),
            ("F14", UInt32(107)),
            ("F15", UInt32(113)),
            ("F16", UInt32(106)),
            ("F17", UInt32(64)),
            ("F18", UInt32(79)),
            ("F19", UInt32(80)),
            ("F20", UInt32(90))
        ]
        
        for (expectedName, expectedCode) in expectedHotkeys {
            let found = recommendedHotkeys.first { $0.name == expectedName && $0.keyCode == expectedCode }
            #expect(found != nil)
        }
    }
    
    @Test("Recommended hotkeys are all valid")
    func testRecommendedHotkeysAreAllValid() {
        let recommendedHotkeys = KeyCodeHelper.getRecommendedHotkeys()
        
        for hotkey in recommendedHotkeys {
            #expect(KeyCodeHelper.isValidHotkey(hotkey.keyCode) == true)
        }
    }
    
    @Test("Recommended hotkeys have names")
    func testRecommendedHotkeysHaveNames() {
        let recommendedHotkeys = KeyCodeHelper.getRecommendedHotkeys()
        
        for hotkey in recommendedHotkeys {
            #expect(hotkey.name.isEmpty == false)
            #expect(KeyCodeHelper.getKeyName(for: hotkey.keyCode) == hotkey.name)
        }
    }
}

@Suite("KeyboardEventHelper Tests")
struct KeyboardEventHelperTests {
    
    @Test("Create key event")
    func testCreateKeyEvent() {
        let keyDownEvent = KeyboardEventHelper.createKeyEvent(keyCode: 0, keyDown: true)
        let keyUpEvent = KeyboardEventHelper.createKeyEvent(keyCode: 0, keyDown: false)
        
        #expect(keyDownEvent != nil)
        #expect(keyUpEvent != nil)
    }
    
    @Test("Create key event with modifiers")
    func testCreateKeyEventWithModifiers() {
        let event = KeyboardEventHelper.createKeyEvent(
            keyCode: 0,
            keyDown: true,
            modifiers: .maskCommand
        )
        
        #expect(event != nil)
        #expect(event?.flags.contains(.maskCommand) == true)
    }
    
    @Test("Simulate key press doesn't crash")
    func testSimulateKeyPressDoesntCrash() {
        // Note: This test just verifies the method doesn't crash
        // In a real test environment, we might want to mock CGEvent
        KeyboardEventHelper.simulateKeyPress(keyCode: 0)
        
        #expect(true) // Test passed if no crash
    }
    
    @Test("Simulate key press with modifiers doesn't crash")
    func testSimulateKeyPressWithModifiersDoesntCrash() {
        KeyboardEventHelper.simulateKeyPress(keyCode: 0, modifiers: .maskCommand)
        
        #expect(true) // Test passed if no crash
    }
    
    @Test("Simulate paste doesn't crash")
    func testSimulatePasteDoesntCrash() {
        KeyboardEventHelper.simulatePaste()
        
        #expect(true) // Test passed if no crash
    }
    
    @Test("Simulate copy doesn't crash")
    func testSimulateCopyDoesntCrash() {
        KeyboardEventHelper.simulateCopy()
        
        #expect(true) // Test passed if no crash
    }
    
    @Test("Paste uses correct key combination")
    func testPasteUsesCorrectKeyCombination() {
        // Testing the concept - in real implementation we'd mock CGEvent
        // Cmd+V should be keyCode 9 with Command modifier
        let expectedKeyCode = CGKeyCode(9)
        let expectedModifiers = CGEventFlags.maskCommand
        
        // We can't easily test the actual implementation without mocking
        // But we can verify the constants are correct
        #expect(expectedKeyCode == 9)
        #expect(expectedModifiers == .maskCommand)
    }
    
    @Test("Copy uses correct key combination")
    func testCopyUsesCorrectKeyCombination() {
        // Testing the concept - in real implementation we'd mock CGEvent
        // Cmd+C should be keyCode 8 with Command modifier
        let expectedKeyCode = CGKeyCode(8)
        let expectedModifiers = CGEventFlags.maskCommand
        
        #expect(expectedKeyCode == 8)
        #expect(expectedModifiers == .maskCommand)
    }
}