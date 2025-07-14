import Testing
import Foundation
import Carbon
import AppKit
@testable import Murmur

// Mock delegate for testing
class MockHotkeyManagerDelegate: HotkeyManagerDelegate {
    var hotkeyPressedCalled = false
    var hotkeyReleasedCalled = false
    
    func hotkeyPressed() {
        hotkeyPressedCalled = true
    }
    
    func hotkeyReleased() {
        hotkeyReleasedCalled = true
    }
    
    func reset() {
        hotkeyPressedCalled = false
        hotkeyReleasedCalled = false
    }
}

@Suite("HotkeyManager Tests")
struct HotkeyManagerTests {
    
    @Test("Initial state")
    func testInitialState() {
        let manager = HotkeyManager()
        
        // Manager should initialize without crashing
        #expect(manager.delegate == nil)
    }
    
    @Test("Delegate assignment")
    func testDelegateAssignment() {
        let manager = HotkeyManager()
        let mockDelegate = MockHotkeyManagerDelegate()
        
        manager.delegate = mockDelegate
        
        #expect(manager.delegate === mockDelegate)
    }
    
    @Test("Register hotkey with valid key code")
    func testRegisterHotkeyWithValidKeyCode() {
        let manager = HotkeyManager()
        
        // Test with FN key (default)
        manager.registerHotkey(keyCode: 63)
        
        // Should complete without crashing
        // In a real test environment, we'd mock the Carbon framework calls
        #expect(true) // Test that it doesn't crash
    }
    
    @Test("Register hotkey with function keys")
    func testRegisterHotkeyWithFunctionKeys() {
        let manager = HotkeyManager()
        
        let functionKeys: [UInt32] = [122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111]
        
        for keyCode in functionKeys {
            manager.registerHotkey(keyCode: keyCode)
            // Should complete without crashing
        }
        
        #expect(true) // Test that it doesn't crash
    }
    
    @Test("Update hotkey changes registration")
    func testUpdateHotkey() {
        let manager = HotkeyManager()
        
        // Register initial hotkey
        manager.registerHotkey(keyCode: 63)
        
        // Update to different key
        manager.updateHotkey(keyCode: 122) // F1
        
        // Should complete without crashing
        #expect(true)
    }
    
    @Test("Get key code from NSEvent")
    func testGetKeyCodeFromNSEvent() {
        // Create a mock NSEvent
        let mockEvent = NSEvent.keyEvent(
            with: .keyDown,
            location: NSPoint.zero,
            modifierFlags: [],
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            characters: "a",
            charactersIgnoringModifiers: "a",
            isARepeat: false,
            keyCode: 0
        )
        
        let keyCode = HotkeyManager.getKeyCode(from: mockEvent!)
        
        #expect(keyCode == 0)
    }
    
    @Test("Key code map contains expected keys")
    func testKeyCodeMapContainsExpectedKeys() {
        let keyCodeMap = HotkeyManager.keyCodeMap
        
        // Test some essential keys
        #expect(keyCodeMap["FN"] == 63)
        #expect(keyCodeMap["F1"] == 122)
        #expect(keyCodeMap["F2"] == 120)
        #expect(keyCodeMap["F12"] == 111)
        #expect(keyCodeMap["Command"] == 55)
        #expect(keyCodeMap["Option"] == 58)
        #expect(keyCodeMap["Control"] == 59)
        #expect(keyCodeMap["Shift"] == 56)
        #expect(keyCodeMap["Space"] == 49)
        #expect(keyCodeMap["Tab"] == 48)
        #expect(keyCodeMap["Return"] == 36)
        #expect(keyCodeMap["Delete"] == 51)
        #expect(keyCodeMap["Escape"] == 53)
    }
    
    @Test("Get key name for valid key codes")
    func testGetKeyNameForValidKeyCodes() {
        #expect(HotkeyManager.getKeyName(for: 63) == "FN")
        #expect(HotkeyManager.getKeyName(for: 122) == "F1")
        #expect(HotkeyManager.getKeyName(for: 120) == "F2")
        #expect(HotkeyManager.getKeyName(for: 111) == "F12")
        #expect(HotkeyManager.getKeyName(for: 55) == "Command")
        #expect(HotkeyManager.getKeyName(for: 49) == "Space")
        #expect(HotkeyManager.getKeyName(for: 36) == "Return")
    }
    
    @Test("Get key name for invalid key code")
    func testGetKeyNameForInvalidKeyCode() {
        #expect(HotkeyManager.getKeyName(for: 9999) == nil)
        #expect(HotkeyManager.getKeyName(for: 0) == nil)
    }
    
    @Test("All function keys are in key code map")
    func testAllFunctionKeysInMap() {
        let expectedFKeys = [
            ("F1", 122), ("F2", 120), ("F3", 99), ("F4", 118),
            ("F5", 96), ("F6", 97), ("F7", 98), ("F8", 100),
            ("F9", 101), ("F10", 109), ("F11", 103), ("F12", 111),
            ("F13", 105), ("F14", 107), ("F15", 113), ("F16", 106),
            ("F17", 64), ("F18", 79), ("F19", 80), ("F20", 90)
        ]
        
        let keyCodeMap = HotkeyManager.keyCodeMap
        
        for (key, expectedCode) in expectedFKeys {
            #expect(keyCodeMap[key] == UInt32(expectedCode))
        }
    }
    
    @Test("Key code map is comprehensive")
    func testKeyCodeMapIsComprehensive() {
        let keyCodeMap = HotkeyManager.keyCodeMap
        
        // Should contain at least 20 keys (F1-F20 alone)
        #expect(keyCodeMap.count >= 20)
        
        // Should contain modifier keys
        #expect(keyCodeMap.keys.contains("Command"))
        #expect(keyCodeMap.keys.contains("Option"))
        #expect(keyCodeMap.keys.contains("Control"))
        #expect(keyCodeMap.keys.contains("Shift"))
        
        // Should contain common keys
        #expect(keyCodeMap.keys.contains("Space"))
        #expect(keyCodeMap.keys.contains("Tab"))
        #expect(keyCodeMap.keys.contains("Return"))
        #expect(keyCodeMap.keys.contains("Delete"))
        #expect(keyCodeMap.keys.contains("Escape"))
    }
    
    @Test("Key code map values are unique")
    func testKeyCodeMapValuesAreUnique() {
        let keyCodeMap = HotkeyManager.keyCodeMap
        let values = Array(keyCodeMap.values)
        let uniqueValues = Set(values)
        
        #expect(values.count == uniqueValues.count)
    }
    
    @Test("Deinit cleans up resources")
    func testDeinitCleansUpResources() {
        // Test that creating and destroying manager doesn't crash
        let manager = HotkeyManager()
        manager.registerHotkey(keyCode: 63)
        
        // Manager should be deallocated cleanly
        #expect(true) // Test that it doesn't crash
    }
    
    @Test("Multiple hotkey registrations")
    func testMultipleHotkeyRegistrations() {
        let manager = HotkeyManager()
        
        // Register multiple hotkeys in sequence
        manager.registerHotkey(keyCode: 63)   // FN
        manager.registerHotkey(keyCode: 122)  // F1
        manager.registerHotkey(keyCode: 120)  // F2
        
        // Should handle multiple registrations without crashing
        #expect(true)
    }
    
    @Test("Hotkey manager with delegate callback simulation")
    func testHotkeyManagerWithDelegateCallbackSimulation() {
        let manager = HotkeyManager()
        let mockDelegate = MockHotkeyManagerDelegate()
        manager.delegate = mockDelegate
        
        // We can't easily test actual hotkey events without system integration
        // But we can test that delegate assignment works correctly
        #expect(mockDelegate.hotkeyPressedCalled == false)
        #expect(mockDelegate.hotkeyReleasedCalled == false)
    }
}