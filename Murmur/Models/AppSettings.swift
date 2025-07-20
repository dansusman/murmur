import Foundation

struct AppSettings: Codable {
    var hotkeyCode: UInt32
    var meetingModeHotkeyCode: UInt32
    var launchAtLogin: Bool
    var whisperModelType: WhisperModelType
    var autoInsertText: Bool
    var language: String
    var showFloatingIndicator: Bool
    var enableMeetingMode: Bool
    
    static let `default` = AppSettings(
        hotkeyCode: 63, // FN key
        meetingModeHotkeyCode: 64, // F17 key
        launchAtLogin: false,
        whisperModelType: .tiny,
        autoInsertText: true,
        language: "en",
        showFloatingIndicator: true,
        enableMeetingMode: false
    )
}

struct TranscriptionResult {
    let text: String
    let confidence: Double?
    let duration: TimeInterval
    let timestamp: Date
    
    init(text: String, confidence: Double? = nil, duration: TimeInterval = 0, timestamp: Date = Date()) {
        self.text = text
        self.confidence = confidence
        self.duration = duration
        self.timestamp = timestamp
    }
}

struct AudioRecordingInfo {
    let duration: TimeInterval
    let sampleRate: Double
    let channels: Int
    let fileSize: Int64
    let format: String
    
    init(duration: TimeInterval, sampleRate: Double = 16000, channels: Int = 1, fileSize: Int64 = 0, format: String = "wav") {
        self.duration = duration
        self.sampleRate = sampleRate
        self.channels = channels
        self.fileSize = fileSize
        self.format = format
    }
}