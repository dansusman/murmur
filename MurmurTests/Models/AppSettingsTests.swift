import Testing
import Foundation
@testable import Murmur

@Suite("AppSettings Tests")
struct AppSettingsTests {
    
    @Test("Default values are correct")
    func testDefaultValues() {
        let settings = AppSettings.default
        
        #expect(settings.hotkeyCode == 63) // FN key
        #expect(settings.launchAtLogin == false)
        #expect(settings.whisperModelType == .tiny)
        #expect(settings.autoInsertText == true)
        #expect(settings.language == "en")
        #expect(settings.showFloatingIndicator == true)
    }
    
    @Test("Codable encoding and decoding")
    func testCodableCompliance() throws {
        let originalSettings = AppSettings(
            hotkeyCode: 123,
            launchAtLogin: true,
            whisperModelType: .base,
            autoInsertText: false,
            language: "es",
            showFloatingIndicator: false
        )
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        let encodedData = try encoder.encode(originalSettings)
        let decodedSettings = try decoder.decode(AppSettings.self, from: encodedData)
        
        #expect(decodedSettings.hotkeyCode == originalSettings.hotkeyCode)
        #expect(decodedSettings.launchAtLogin == originalSettings.launchAtLogin)
        #expect(decodedSettings.whisperModelType == originalSettings.whisperModelType)
        #expect(decodedSettings.autoInsertText == originalSettings.autoInsertText)
        #expect(decodedSettings.language == originalSettings.language)
        #expect(decodedSettings.showFloatingIndicator == originalSettings.showFloatingIndicator)
    }
    
    @Test("JSON encoding produces expected structure")
    func testJSONStructure() throws {
        let settings = AppSettings.default
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        
        let jsonData = try encoder.encode(settings)
        let jsonString = String(data: jsonData, encoding: .utf8)!
        
        #expect(jsonString.contains("\"hotkeyCode\""))
        #expect(jsonString.contains("\"launchAtLogin\""))
        #expect(jsonString.contains("\"whisperModelType\""))
        #expect(jsonString.contains("\"autoInsertText\""))
        #expect(jsonString.contains("\"language\""))
        #expect(jsonString.contains("\"showFloatingIndicator\""))
    }
    
    @Test("Invalid JSON data handling")
    func testInvalidJSONHandling() {
        let invalidJSON = "{ \"invalid\": \"json\" }"
        let jsonData = invalidJSON.data(using: .utf8)!
        
        let decoder = JSONDecoder()
        
        #expect(throws: (any Error).self) {
            try decoder.decode(AppSettings.self, from: jsonData)
        }
    }
    
    @Test("All WhisperModelType values are valid")
    func testWhisperModelTypeValues() {
        let modelTypes: [WhisperModelType] = [.tiny, .base, .small, .medium, .large]
        
        for modelType in modelTypes {
            let settings = AppSettings(
                hotkeyCode: 63,
                launchAtLogin: false,
                whisperModelType: modelType,
                autoInsertText: true,
                language: "en",
                showFloatingIndicator: true
            )
            
            #expect(settings.whisperModelType == modelType)
        }
    }
}

@Suite("TranscriptionResult Tests")
struct TranscriptionResultTests {
    
    @Test("Default initialization")
    func testDefaultInitialization() {
        let result = TranscriptionResult(text: "Hello, world!")
        
        #expect(result.text == "Hello, world!")
        #expect(result.confidence == nil)
        #expect(result.duration == 0)
        #expect(result.timestamp <= Date())
    }
    
    @Test("Full initialization")
    func testFullInitialization() {
        let timestamp = Date()
        let result = TranscriptionResult(
            text: "Test text",
            confidence: 0.95,
            duration: 5.0,
            timestamp: timestamp
        )
        
        #expect(result.text == "Test text")
        #expect(result.confidence == 0.95)
        #expect(result.duration == 5.0)
        #expect(result.timestamp == timestamp)
    }
    
    @Test("Confidence value ranges")
    func testConfidenceRanges() {
        let lowConfidence = TranscriptionResult(text: "Low", confidence: 0.1)
        let highConfidence = TranscriptionResult(text: "High", confidence: 0.99)
        
        #expect(lowConfidence.confidence == 0.1)
        #expect(highConfidence.confidence == 0.99)
    }
}

@Suite("AudioRecordingInfo Tests")
struct AudioRecordingInfoTests {
    
    @Test("Default initialization")
    func testDefaultInitialization() {
        let info = AudioRecordingInfo(duration: 10.0)
        
        #expect(info.duration == 10.0)
        #expect(info.sampleRate == 16000)
        #expect(info.channels == 1)
        #expect(info.fileSize == 0)
        #expect(info.format == "wav")
    }
    
    @Test("Full initialization")
    func testFullInitialization() {
        let info = AudioRecordingInfo(
            duration: 15.5,
            sampleRate: 44100,
            channels: 2,
            fileSize: 1024,
            format: "mp3"
        )
        
        #expect(info.duration == 15.5)
        #expect(info.sampleRate == 44100)
        #expect(info.channels == 2)
        #expect(info.fileSize == 1024)
        #expect(info.format == "mp3")
    }
    
    @Test("Standard audio format configuration")
    func testStandardAudioFormat() {
        let info = AudioRecordingInfo(duration: 5.0)
        
        // Verify Whisper-compatible format
        #expect(info.sampleRate == 16000)
        #expect(info.channels == 1)
        #expect(info.format == "wav")
    }
}