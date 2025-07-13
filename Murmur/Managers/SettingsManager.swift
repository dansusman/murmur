import Combine
import Foundation
import SwiftUI
import ServiceManagement

class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var hotkeyCode: UInt32 = 63 // FN key default
    @Published var launchAtLogin: Bool = false
    @Published var whisperModelType: WhisperModelType = .tiny
    @Published var autoInsertText: Bool = true
    @Published var showNotifications: Bool = true
    @Published var recordingTimeout: TimeInterval = 30.0
    @Published var language: String = "en"
    @Published var borderSettings: BorderSettings = .default
    
    private let userDefaults = UserDefaults.standard
    private let launchAtLoginKey = "LaunchAtLogin"
    private let hotkeyCodeKey = "HotkeyCode"
    private let whisperModelTypeKey = "WhisperModelType"
    private let autoInsertTextKey = "AutoInsertText"
    private let showNotificationsKey = "ShowNotifications"
    private let recordingTimeoutKey = "RecordingTimeout"
    private let languageKey = "Language"
    private let borderSettingsKey = "BorderSettings"
    
    init() {
        loadSettings()
        setupObservers()
    }
    
    private func loadSettings() {
        hotkeyCode = UInt32(userDefaults.integer(forKey: hotkeyCodeKey))
        if hotkeyCode == 0 { hotkeyCode = 63 } // Default to FN key
        
        launchAtLogin = userDefaults.bool(forKey: launchAtLoginKey)
        autoInsertText = userDefaults.object(forKey: autoInsertTextKey) as? Bool ?? true
        showNotifications = userDefaults.object(forKey: showNotificationsKey) as? Bool ?? true
        recordingTimeout = userDefaults.double(forKey: recordingTimeoutKey)
        if recordingTimeout == 0 { recordingTimeout = 30.0 }
        language = userDefaults.string(forKey: languageKey) ?? "en"
        
        // Load whisper model type
        if let modelTypeString = userDefaults.string(forKey: whisperModelTypeKey),
           let modelType = WhisperModelType(rawValue: modelTypeString) {
            whisperModelType = modelType
        }
        
        // Load border settings
        if let borderData = userDefaults.data(forKey: borderSettingsKey),
           let loadedBorderSettings = try? JSONDecoder().decode(BorderSettings.self, from: borderData) {
            borderSettings = loadedBorderSettings
        }
    }
    
    private func setupObservers() {
        // Observe changes and save automatically
        $hotkeyCode
            .sink { [weak self] value in
                self?.userDefaults.set(Int(value), forKey: self?.hotkeyCodeKey ?? "")
            }
            .store(in: &cancellables)
        
        $launchAtLogin
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: self?.launchAtLoginKey ?? "")
                self?.updateLaunchAtLoginStatus(value)
            }
            .store(in: &cancellables)
        
        
        $whisperModelType
            .sink { [weak self] value in
                self?.userDefaults.set(value.rawValue, forKey: self?.whisperModelTypeKey ?? "")
            }
            .store(in: &cancellables)
        
        $autoInsertText
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: self?.autoInsertTextKey ?? "")
            }
            .store(in: &cancellables)
        
        $showNotifications
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: self?.showNotificationsKey ?? "")
            }
            .store(in: &cancellables)
        
        $recordingTimeout
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: self?.recordingTimeoutKey ?? "")
            }
            .store(in: &cancellables)
        
        $language
            .sink { [weak self] value in
                self?.userDefaults.set(value, forKey: self?.languageKey ?? "")
            }
            .store(in: &cancellables)
        
        $borderSettings
            .sink { [weak self] value in
                if let data = try? JSONEncoder().encode(value) {
                    self?.userDefaults.set(data, forKey: self?.borderSettingsKey ?? "")
                }
            }
            .store(in: &cancellables)
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    private func updateLaunchAtLoginStatus(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            Logger.settings.error("Failed to update launch at login status: \(error)")
        }
    }
    
    func resetToDefaults() {
        hotkeyCode = 63
        launchAtLogin = false
        whisperModelType = .tiny
        autoInsertText = true
        showNotifications = true
        recordingTimeout = 30.0
        language = "en"
        borderSettings = .default
    }
    
    func exportSettings() -> [String: Any] {
        return [
            "hotkeyCode": hotkeyCode,
            "launchAtLogin": launchAtLogin,
            "whisperModelType": whisperModelType.rawValue,
            "autoInsertText": autoInsertText,
            "showNotifications": showNotifications,
            "recordingTimeout": recordingTimeout,
            "language": language
        ]
    }
    
    func importSettings(_ settings: [String: Any]) {
        if let value = settings["hotkeyCode"] as? UInt32 {
            hotkeyCode = value
        }
        if let value = settings["launchAtLogin"] as? Bool {
            launchAtLogin = value
        }
        if let value = settings["whisperModelType"] as? String,
           let modelType = WhisperModelType(rawValue: value) {
            whisperModelType = modelType
        }
        if let value = settings["autoInsertText"] as? Bool {
            autoInsertText = value
        }
        if let value = settings["showNotifications"] as? Bool {
            showNotifications = value
        }
        if let value = settings["recordingTimeout"] as? TimeInterval {
            recordingTimeout = value
        }
        if let value = settings["language"] as? String {
            language = value
        }
    }
    
    func getHotkeyDisplayName() -> String {
        return HotkeyManager.getKeyName(for: hotkeyCode) ?? "Unknown"
    }
    
    func validateWhisperSetup() -> Bool {
        // Check if whisper.cpp binary and at least one model are available
        guard let binaryPath = Bundle.main.path(forResource: "whisper", ofType: nil, inDirectory: "Binaries"),
              FileManager.default.fileExists(atPath: binaryPath) else {
            return false
        }
        
        guard let modelsPath = Bundle.main.path(forResource: "Models", ofType: nil),
              let modelFiles = try? FileManager.default.contentsOfDirectory(atPath: modelsPath),
              modelFiles.contains(where: { $0.hasPrefix("ggml-") && $0.hasSuffix(".bin") }) else {
            return false
        }
        
        return true
    }
}

// MARK: - Whisper Model Types
enum WhisperModelType: String, CaseIterable, Codable {
    case tiny = "tiny"
    case base = "base"
    case small = "small"
    case medium = "medium"
    case large = "large"
    
    var displayName: String {
        switch self {
        case .tiny: return "Tiny (39MB, fastest)"
        case .base: return "Base (142MB, balanced)"
        case .small: return "Small (244MB, better accuracy)"
        case .medium: return "Medium (769MB, high accuracy)"
        case .large: return "Large (1550MB, best accuracy)"
        }
    }
    
    var size: String {
        switch self {
        case .tiny: return "39MB"
        case .base: return "142MB"
        case .small: return "244MB"
        case .medium: return "769MB"
        case .large: return "1550MB"
        }
    }
    
    var speed: String {
        switch self {
        case .tiny: return "Fastest"
        case .base: return "Fast"
        case .small: return "Medium"
        case .medium: return "Slow"
        case .large: return "Slowest"
        }
    }
}
