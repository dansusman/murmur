import Foundation
@testable import Murmur

class MockWhisperService: WhisperService {
    var shouldFailTranscription = false
    var mockTranscriptionResult = "Mock transcription result"
    var transcriptionDelay: TimeInterval = 0.1
    var mockError: Error = MockWhisperServiceError.transcriptionFailed
    var mockAvailableModels: [WhisperModel] = []
    
    override func transcribe(audioData: Data) {
        DispatchQueue.main.asyncAfter(deadline: .now() + transcriptionDelay) {
            if self.shouldFailTranscription {
                self.delegate?.whisperService(self, didFailWithError: self.mockError)
            } else {
                self.delegate?.whisperService(self, didTranscribe: self.mockTranscriptionResult)
            }
        }
    }
    
    override func getAvailableModels() -> [WhisperModel] {
        return mockAvailableModels
    }
    
    override func getModelInfo(for modelType: WhisperModelType) -> WhisperModel? {
        return mockAvailableModels.first { $0.name == modelType.rawValue }
    }
    
    override func getRecommendedModel() -> WhisperModelType {
        return .tiny
    }
    
    override func isModelAvailable(_ modelType: WhisperModelType) -> Bool {
        return mockAvailableModels.contains { $0.name == modelType.rawValue }
    }
    
    func simulateTranscriptionSuccess(result: String) {
        shouldFailTranscription = false
        mockTranscriptionResult = result
    }
    
    func simulateTranscriptionFailure(error: Error) {
        shouldFailTranscription = true
        mockError = error
    }
    
    func setTranscriptionDelay(_ delay: TimeInterval) {
        transcriptionDelay = delay
    }
    
    func addMockModel(_ model: WhisperModel) {
        mockAvailableModels.append(model)
    }
    
    func setMockModels(_ models: [WhisperModel]) {
        mockAvailableModels = models
    }
    
    func reset() {
        shouldFailTranscription = false
        mockTranscriptionResult = "Mock transcription result"
        transcriptionDelay = 0.1
        mockError = MockWhisperServiceError.transcriptionFailed
        mockAvailableModels = []
    }
}

enum MockWhisperServiceError: Error, LocalizedError {
    case transcriptionFailed
    case invalidAudioData
    case modelNotFound
    case whisperBinaryNotFound
    
    var errorDescription: String? {
        switch self {
        case .transcriptionFailed:
            return "Transcription failed"
        case .invalidAudioData:
            return "Invalid audio data"
        case .modelNotFound:
            return "Whisper model not found"
        case .whisperBinaryNotFound:
            return "Whisper binary not found"
        }
    }
}