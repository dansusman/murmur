import Foundation

class WhisperService: NSObject, ObservableObject {
    weak var delegate: WhisperServiceDelegate?
    
    private let whisperWrapper: WhisperCppWrapper
    private let settingsManager: SettingsManager
    
    @Published var isTranscribing = false
    
    init(settingsManager: SettingsManager = SettingsManager.shared) {
        self.whisperWrapper = WhisperCppWrapper()
        self.settingsManager = settingsManager
        super.init()
        
        // Observe transcription state from wrapper
        whisperWrapper.$isTranscribing
            .assign(to: &$isTranscribing)
    }
    
    func transcribe(audioData: Data) {
        guard !audioData.isEmpty else {
            delegate?.whisperService(self, didFailWithError: WhisperServiceError.noAudioData)
            return
        }
        
        // Validate audio format
        guard whisperWrapper.validateAudioFormat(audioData) else {
            delegate?.whisperService(self, didFailWithError: WhisperServiceError.invalidAudioFormat)
            return
        }
        
        // Get current model and language from settings
        let modelType = settingsManager.whisperModelType
        let language = settingsManager.language
        
        // Verify model is available
        guard whisperWrapper.isModelAvailable(modelType) else {
            delegate?.whisperService(self, didFailWithError: WhisperServiceError.modelNotAvailable(modelType.rawValue))
            return
        }
        
        // Run transcription asynchronously
        Task {
            do {
                let transcription = try await whisperWrapper.transcribe(
                    audioData: audioData,
                    using: modelType,
                    language: language
                )
                
                DispatchQueue.main.async {
                    if !transcription.isEmpty {
                        Logger.whisper.success("✅ Transcription successful: \"\(transcription)\"")
                        self.delegate?.whisperService(self, didTranscribe: transcription)
                    } else {
                        Logger.whisper.warning("❌ Transcription returned empty result")
                        self.delegate?.whisperService(self, didFailWithError: WhisperServiceError.emptyTranscription)
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.delegate?.whisperService(self, didFailWithError: error)
                }
            }
        }
    }
    
    func getAvailableModels() -> [WhisperModel] {
        return whisperWrapper.availableModels
    }
    
    func getModelInfo(for modelType: WhisperModelType) -> WhisperModel? {
        return whisperWrapper.getModelInfo(for: modelType)
    }
    
    func getRecommendedModel() -> WhisperModelType {
        return whisperWrapper.getRecommendedModel()
    }
    
    func isModelAvailable(_ modelType: WhisperModelType) -> Bool {
        return whisperWrapper.isModelAvailable(modelType)
    }
}

// MARK: - Whisper Service Errors
enum WhisperServiceError: Error, LocalizedError {
    case noAudioData
    case invalidAudioFormat
    case modelNotAvailable(String)
    case emptyTranscription
    case transcriptionFailed(String)
    
    var errorDescription: String? {
        switch self {
        case .noAudioData:
            return "No audio data to transcribe"
        case .invalidAudioFormat:
            return "Invalid audio format. Expected WAV format."
        case .modelNotAvailable(let model):
            return "Model '\(model)' is not available. Please check if the model file exists."
        case .emptyTranscription:
            return "Transcription returned empty result"
        case .transcriptionFailed(let message):
            return "Transcription failed: \(message)"
        }
    }
}
