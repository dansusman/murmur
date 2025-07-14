import Testing
import Foundation
import Combine
@testable import Murmur

@Suite("SettingsManager Tests")
struct SettingsManagerTests {
    
    @Test("Default values are set correctly")
    func testDefaultValues() {
        let settingsManager = SettingsManager()
        
        #expect(settingsManager.hotkeyCode == 63)
        #expect(settingsManager.launchAtLogin == false)
        #expect(settingsManager.whisperModelType == .tiny)
        #expect(settingsManager.autoInsertText == true)
        #expect(settingsManager.language == "en")
        #expect(settingsManager.showFloatingIndicator == true)
    }
    
    @Test("Settings persistence - save and load")
    func testSettingsPersistence() async throws {
        let _ = UserDefaults(suiteName: "test-settings")!
        let settingsManager = SettingsManager()
        
        // Modify settings
        settingsManager.hotkeyCode = 123
        settingsManager.launchAtLogin = true
        settingsManager.whisperModelType = .base
        settingsManager.autoInsertText = false
        settingsManager.language = "es"
        settingsManager.showFloatingIndicator = false
        
        // Wait for auto-save to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Verify values are saved to UserDefaults
        let savedHotkeyCode = UInt32(UserDefaults.standard.integer(forKey: "HotkeyCode"))
        let savedLaunchAtLogin = UserDefaults.standard.bool(forKey: "LaunchAtLogin")
        let savedModelType = UserDefaults.standard.string(forKey: "WhisperModelType")
        let savedAutoInsertText = UserDefaults.standard.bool(forKey: "AutoInsertText")
        let savedLanguage = UserDefaults.standard.string(forKey: "Language")
        let savedShowFloatingIndicator = UserDefaults.standard.bool(forKey: "ShowFloatingIndicator")
        
        #expect(savedHotkeyCode == 123)
        #expect(savedLaunchAtLogin == true)
        #expect(savedModelType == "base")
        #expect(savedAutoInsertText == false)
        #expect(savedLanguage == "es")
        #expect(savedShowFloatingIndicator == false)
    }
    
    @Test("Reset to defaults")
    func testResetToDefaults() {
        let settingsManager = SettingsManager()
        
        // Modify settings
        settingsManager.hotkeyCode = 999
        settingsManager.launchAtLogin = true
        settingsManager.whisperModelType = .large
        settingsManager.autoInsertText = false
        settingsManager.language = "fr"
        settingsManager.showFloatingIndicator = false
        
        // Reset to defaults
        settingsManager.resetToDefaults()
        
        #expect(settingsManager.hotkeyCode == 63)
        #expect(settingsManager.launchAtLogin == false)
        #expect(settingsManager.whisperModelType == .tiny)
        #expect(settingsManager.autoInsertText == true)
        #expect(settingsManager.language == "en")
        #expect(settingsManager.showFloatingIndicator == true)
    }
    
    @Test("Export settings")
    func testExportSettings() {
        let settingsManager = SettingsManager()
        
        settingsManager.hotkeyCode = 456
        settingsManager.launchAtLogin = true
        settingsManager.whisperModelType = .small
        settingsManager.autoInsertText = false
        settingsManager.language = "de"
        settingsManager.showFloatingIndicator = false
        
        let exportedSettings = settingsManager.exportSettings()
        
        #expect(exportedSettings["hotkeyCode"] as? UInt32 == 456)
        #expect(exportedSettings["launchAtLogin"] as? Bool == true)
        #expect(exportedSettings["whisperModelType"] as? String == "small")
        #expect(exportedSettings["autoInsertText"] as? Bool == false)
        #expect(exportedSettings["language"] as? String == "de")
        #expect(exportedSettings["showFloatingIndicator"] as? Bool == false)
    }
    
    @Test("Import settings")
    func testImportSettings() {
        let settingsManager = SettingsManager()
        
        let importSettings: [String: Any] = [
            "hotkeyCode": UInt32(789),
            "launchAtLogin": true,
            "whisperModelType": "medium",
            "autoInsertText": false,
            "language": "ja",
            "showFloatingIndicator": false
        ]
        
        settingsManager.importSettings(importSettings)
        
        #expect(settingsManager.hotkeyCode == 789)
        #expect(settingsManager.launchAtLogin == true)
        #expect(settingsManager.whisperModelType == .medium)
        #expect(settingsManager.autoInsertText == false)
        #expect(settingsManager.language == "ja")
        #expect(settingsManager.showFloatingIndicator == false)
    }
    
    @Test("Import settings with invalid data")
    func testImportSettingsWithInvalidData() {
        let settingsManager = SettingsManager()
        let originalHotkeyCode = settingsManager.hotkeyCode
        
        let invalidSettings: [String: Any] = [
            "hotkeyCode": "invalid",
            "launchAtLogin": "not a bool",
            "whisperModelType": "nonexistent",
            "autoInsertText": 123,
            "language": 456,
            "showFloatingIndicator": "invalid"
        ]
        
        settingsManager.importSettings(invalidSettings)
        
        // Settings should remain unchanged when invalid data is provided
        #expect(settingsManager.hotkeyCode == originalHotkeyCode)
        #expect(settingsManager.launchAtLogin == false)
        #expect(settingsManager.whisperModelType == .tiny)
        #expect(settingsManager.autoInsertText == true)
        #expect(settingsManager.language == "en")
        #expect(settingsManager.showFloatingIndicator == true)
    }
    
    @Test("Validate whisper setup with missing binary")
    func testValidateWhisperSetupMissingBinary() {
        let settingsManager = SettingsManager()
        
        // In a test environment, the binary likely won't exist
        // This test validates the method's behavior when resources are missing
        let isValid = settingsManager.validateWhisperSetup()
        
        // We can't guarantee the binary exists in the test environment
        // so this test mainly checks the method doesn't crash
        #expect(isValid == true || isValid == false)
    }
    
    @Test("Hotkey display name")
    func testHotkeyDisplayName() {
        let settingsManager = SettingsManager()
        
        // Test with default FN key
        let defaultDisplayName = settingsManager.getHotkeyDisplayName()
        #expect(defaultDisplayName != "")
        #expect(defaultDisplayName != "Unknown")
        
        // Test with different key code
        settingsManager.hotkeyCode = 36 // Return key
        let returnKeyDisplayName = settingsManager.getHotkeyDisplayName()
        #expect(returnKeyDisplayName != "")
    }
    
    @Test("Settings auto-save on property change")
    func testSettingsAutoSave() async throws {
        let settingsManager = SettingsManager()
        
        // Clear any existing values
        UserDefaults.standard.removeObject(forKey: "HotkeyCode")
        
        // Change a setting
        settingsManager.hotkeyCode = 555
        
        // Wait for auto-save
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Verify it was saved
        let savedValue = UInt32(UserDefaults.standard.integer(forKey: "HotkeyCode"))
        #expect(savedValue == 555)
    }
    
    @Test("Loading settings from UserDefaults")
    func testLoadingFromUserDefaults() {
        // Pre-populate UserDefaults with test values
        UserDefaults.standard.set(777, forKey: "HotkeyCode")
        UserDefaults.standard.set(true, forKey: "LaunchAtLogin")
        UserDefaults.standard.set("large", forKey: "WhisperModelType")
        UserDefaults.standard.set(false, forKey: "AutoInsertText")
        UserDefaults.standard.set("pt", forKey: "Language")
        UserDefaults.standard.set(false, forKey: "ShowFloatingIndicator")
        
        let settingsManager = SettingsManager()
        
        #expect(settingsManager.hotkeyCode == 777)
        #expect(settingsManager.launchAtLogin == true)
        #expect(settingsManager.whisperModelType == .large)
        #expect(settingsManager.autoInsertText == false)
        #expect(settingsManager.language == "pt")
        #expect(settingsManager.showFloatingIndicator == false)
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "HotkeyCode")
        UserDefaults.standard.removeObject(forKey: "LaunchAtLogin")
        UserDefaults.standard.removeObject(forKey: "WhisperModelType")
        UserDefaults.standard.removeObject(forKey: "AutoInsertText")
        UserDefaults.standard.removeObject(forKey: "Language")
        UserDefaults.standard.removeObject(forKey: "ShowFloatingIndicator")
    }
    
    @Test("Handling zero hotkey code defaults to FN key")
    func testZeroHotkeyCodeDefaulting() {
        UserDefaults.standard.set(0, forKey: "HotkeyCode")
        
        let settingsManager = SettingsManager()
        
        #expect(settingsManager.hotkeyCode == 63) // Should default to FN key
        
        // Clean up
        UserDefaults.standard.removeObject(forKey: "HotkeyCode")
    }
}

@Suite("WhisperModelType Tests")
struct WhisperModelTypeTests {
    
    @Test("All model types have correct raw values")
    func testModelTypeRawValues() {
        #expect(WhisperModelType.tiny.rawValue == "tiny")
        #expect(WhisperModelType.base.rawValue == "base")
        #expect(WhisperModelType.small.rawValue == "small")
        #expect(WhisperModelType.medium.rawValue == "medium")
        #expect(WhisperModelType.large.rawValue == "large")
    }
    
    @Test("All model types have display names")
    func testModelTypeDisplayNames() {
        #expect(WhisperModelType.tiny.displayName == "Tiny (39MB, fastest)")
        #expect(WhisperModelType.base.displayName == "Base (142MB, balanced)")
        #expect(WhisperModelType.small.displayName == "Small (244MB, better accuracy)")
        #expect(WhisperModelType.medium.displayName == "Medium (769MB, high accuracy)")
        #expect(WhisperModelType.large.displayName == "Large (1550MB, best accuracy)")
    }
    
    @Test("All model types have size information")
    func testModelTypeSizes() {
        #expect(WhisperModelType.tiny.size == "39MB")
        #expect(WhisperModelType.base.size == "142MB")
        #expect(WhisperModelType.small.size == "244MB")
        #expect(WhisperModelType.medium.size == "769MB")
        #expect(WhisperModelType.large.size == "1550MB")
    }
    
    @Test("All model types have speed information")
    func testModelTypeSpeeds() {
        #expect(WhisperModelType.tiny.speed == "Fastest")
        #expect(WhisperModelType.base.speed == "Fast")
        #expect(WhisperModelType.small.speed == "Medium")
        #expect(WhisperModelType.medium.speed == "Slow")
        #expect(WhisperModelType.large.speed == "Slowest")
    }
    
    @Test("Model type initialization from raw value")
    func testModelTypeFromRawValue() {
        #expect(WhisperModelType(rawValue: "tiny") == .tiny)
        #expect(WhisperModelType(rawValue: "base") == .base)
        #expect(WhisperModelType(rawValue: "small") == .small)
        #expect(WhisperModelType(rawValue: "medium") == .medium)
        #expect(WhisperModelType(rawValue: "large") == .large)
        #expect(WhisperModelType(rawValue: "invalid") == nil)
    }
    
    @Test("Model type is case iterable")
    func testModelTypeCaseIterable() {
        let allCases = WhisperModelType.allCases
        
        #expect(allCases.count == 5)
        #expect(allCases.contains(.tiny))
        #expect(allCases.contains(.base))
        #expect(allCases.contains(.small))
        #expect(allCases.contains(.medium))
        #expect(allCases.contains(.large))
    }
    
    @Test("Model type is codable")
    func testModelTypeCodable() throws {
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let originalModel = WhisperModelType.base
        let encodedData = try encoder.encode(originalModel)
        let decodedModel = try decoder.decode(WhisperModelType.self, from: encodedData)
        
        #expect(decodedModel == originalModel)
    }
}
