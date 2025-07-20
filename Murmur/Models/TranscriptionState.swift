import Foundation

enum TranscriptionState {
    case idle
    case recording
    case processing
    case completed(String)
    case error(Error)
    
    var isActive: Bool {
        switch self {
        case .idle, .completed, .error:
            return false
        case .recording, .processing:
            return true
        }
    }
    
    var displayText: String {
        switch self {
        case .idle:
            return "Ready"
        case .recording:
            return "Recording..."
        case .processing:
            return "Transcribing..."
        case .completed(let text):
            return "Completed: \(text.prefix(50))"
        case .error(let error):
            return "Error: \(error.localizedDescription)"
        }
    }
}

class TranscriptionSession: ObservableObject {
    @Published var state: TranscriptionState = .idle
    @Published var recordingDuration: TimeInterval = 0
    @Published var transcriptionHistory: [TranscriptionResult] = []
    @Published var recordingMode: RecordingMode = .microphoneOnly
    
    private var recordingStartTime: Date?
    private var recordingTimer: Timer?
    
    func startRecording() {
        guard case .idle = state else { return }

        state = .recording
        recordingStartTime = Date()
        recordingDuration = 0
        
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            guard let self = self, let startTime = self.recordingStartTime else { return }
            self.recordingDuration = Date().timeIntervalSince(startTime)
        }
    }
    
    func stopRecording() {
        guard case .recording = state else { return }

        recordingTimer?.invalidate()
        recordingTimer = nil
        state = .processing
    }
    
    func completeTranscription(text: String) {
        guard case .processing = state else { return }
        
        let result = TranscriptionResult(
            text: text,
            duration: recordingDuration,
            timestamp: Date()
        )
        
        transcriptionHistory.append(result)
        state = .completed(text)
        
        // Reset to idle after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            if case .completed = self.state {
                self.state = .idle
            }
        }
    }
    
    func failTranscription(error: Error) {
        recordingTimer?.invalidate()
        recordingTimer = nil
        state = .error(error)
        
        // Reset to idle after a delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            if case .error = self.state {
                self.state = .idle
            }
        }
    }
    
    func clearHistory() {
        transcriptionHistory.removeAll()
    }
    
    func getRecentTranscriptions(limit: Int = 10) -> [TranscriptionResult] {
        return Array(transcriptionHistory.suffix(limit))
    }
}
