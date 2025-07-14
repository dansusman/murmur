import Foundation
@testable import Murmur

class MockWhisperCppWrapper: WhisperCppWrapper {
    var shouldFailTranscription = false
    var mockTranscriptionResult = "Mock transcription from WhisperCpp"
    var transcriptionDelay: TimeInterval = 0.1
    var mockError: Error = WhisperWrapperError.transcriptionFailed
    var lastUsedModelType: WhisperModelType?
    var lastUsedLanguage: String?
    var shouldFailModelLoad = false
    var mockAvailableModels: [WhisperModel] = []
    
    override func transcribe(audioData: Data, using modelType: WhisperModelType, language: String = "en") async throws -> String {
        lastUsedModelType = modelType
        lastUsedLanguage = language
        
        if shouldFailTranscription {
            throw mockError
        }
        
        // Simulate processing delay
        if transcriptionDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(transcriptionDelay * 1_000_000_000))
        }
        
        return mockTranscriptionResult
    }
    
    override func isModelAvailable(_ modelType: WhisperModelType) -> Bool {
        if shouldFailModelLoad {
            return false
        }
        return mockAvailableModels.contains { $0.name == modelType.rawValue }
    }
    
    override func getModelInfo(for modelType: WhisperModelType) -> WhisperModel? {
        return mockAvailableModels.first { $0.name == modelType.rawValue }
    }
    
    override func getRecommendedModel() -> WhisperModelType {
        return .tiny
    }
    
    func simulateTranscriptionSuccess(result: String) {
        shouldFailTranscription = false
        mockTranscriptionResult = result
    }
    
    func simulateTranscriptionFailure(error: Error) {
        shouldFailTranscription = true
        mockError = error
    }
    
    func simulateModelLoadSuccess() {
        shouldFailModelLoad = false
    }
    
    func simulateModelLoadFailure() {
        shouldFailModelLoad = true
    }
    
    func setTranscriptionDelay(_ delay: TimeInterval) {
        transcriptionDelay = delay
    }
    
    func getLastUsedModelType() -> WhisperModelType? {
        return lastUsedModelType
    }
    
    func getLastUsedLanguage() -> String? {
        return lastUsedLanguage
    }
    
    func addMockModel(_ model: WhisperModel) {
        mockAvailableModels.append(model)
    }
    
    func setMockModels(_ models: [WhisperModel]) {
        mockAvailableModels = models
    }
    
    func reset() {
        shouldFailTranscription = false
        mockTranscriptionResult = "Mock transcription from WhisperCpp"
        transcriptionDelay = 0.1
        lastUsedModelType = nil
        lastUsedLanguage = nil
        shouldFailModelLoad = false
        mockAvailableModels = []
    }
}

enum WhisperWrapperError: Error, LocalizedError {
    case transcriptionFailed
    case modelLoadFailed
    case audioFileNotFound
    case invalidAudioFormat
    
    var errorDescription: String? {
        switch self {
        case .transcriptionFailed:
            return "Transcription failed"
        case .modelLoadFailed:
            return "Failed to load Whisper model"
        case .audioFileNotFound:
            return "Audio file not found"
        case .invalidAudioFormat:
            return "Invalid audio format"
        }
    }
}