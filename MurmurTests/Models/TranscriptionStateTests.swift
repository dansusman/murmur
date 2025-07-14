import Testing
import Foundation
@testable import Murmur

@Suite("TranscriptionState Tests")
struct TranscriptionStateTests {
    
    @Test("Idle state properties")
    func testIdleState() {
        let state = TranscriptionState.idle
        
        #expect(state.isActive == false)
        #expect(state.displayText == "Ready")
    }
    
    @Test("Recording state properties")
    func testRecordingState() {
        let state = TranscriptionState.recording
        
        #expect(state.isActive == true)
        #expect(state.displayText == "Recording...")
    }
    
    @Test("Processing state properties")
    func testProcessingState() {
        let state = TranscriptionState.processing
        
        #expect(state.isActive == true)
        #expect(state.displayText == "Transcribing...")
    }
    
    @Test("Completed state properties")
    func testCompletedState() {
        let text = "Hello, world!"
        let state = TranscriptionState.completed(text)
        
        #expect(state.isActive == false)
        #expect(state.displayText == "Completed: Hello, world!")
    }
    
    @Test("Completed state with long text truncation")
    func testCompletedStateWithLongText() {
        let longText = String(repeating: "a", count: 100)
        let state = TranscriptionState.completed(longText)
        
        #expect(state.isActive == false)
        #expect(state.displayText.hasPrefix("Completed: "))
        #expect(state.displayText.count <= 61) // "Completed: " + 50 chars
    }
    
    @Test("Error state properties")
    func testErrorState() {
        let error = NSError(domain: "TestError", code: 123, userInfo: [NSLocalizedDescriptionKey: "Test error message"])
        let state = TranscriptionState.error(error)
        
        #expect(state.isActive == false)
        #expect(state.displayText == "Error: Test error message")
    }
    
    @Test("State transition validation - idle to recording")
    func testIdleToRecordingTransition() {
        let initialState = TranscriptionState.idle
        let nextState = TranscriptionState.recording
        
        #expect(initialState.isActive == false)
        #expect(nextState.isActive == true)
    }
    
    @Test("State transition validation - recording to processing")
    func testRecordingToProcessingTransition() {
        let initialState = TranscriptionState.recording
        let nextState = TranscriptionState.processing
        
        #expect(initialState.isActive == true)
        #expect(nextState.isActive == true)
    }
    
    @Test("State transition validation - processing to completed")
    func testProcessingToCompletedTransition() {
        let initialState = TranscriptionState.processing
        let nextState = TranscriptionState.completed("Success")
        
        #expect(initialState.isActive == true)
        #expect(nextState.isActive == false)
    }
    
    @Test("State transition validation - processing to error")
    func testProcessingToErrorTransition() {
        let initialState = TranscriptionState.processing
        let error = NSError(domain: "TestError", code: 456, userInfo: [NSLocalizedDescriptionKey: "Processing failed"])
        let nextState = TranscriptionState.error(error)
        
        #expect(initialState.isActive == true)
        #expect(nextState.isActive == false)
    }
    
    @Test("Multiple state instances equality")
    func testStateEquality() {
        let idle1 = TranscriptionState.idle
        let idle2 = TranscriptionState.idle
        let recording1 = TranscriptionState.recording
        let recording2 = TranscriptionState.recording
        
        // Note: Swift enums with associated values don't automatically conform to Equatable
        // We're testing that the same cases produce the same isActive behavior
        #expect(idle1.isActive == idle2.isActive)
        #expect(recording1.isActive == recording2.isActive)
    }
}

@Suite("TranscriptionSession Tests")
struct TranscriptionSessionTests {
    
    @Test("Initial state")
    func testInitialState() {
        let session = TranscriptionSession()
        
        #expect(session.state.isActive == false)
        #expect(session.recordingDuration == 0)
        #expect(session.transcriptionHistory.isEmpty)
    }
    
    @Test("Start recording from idle state")
    func testStartRecordingFromIdle() async throws {
        let session = TranscriptionSession()
        
        session.startRecording()
        
        #expect(session.state.isActive == true)
        #expect(session.recordingDuration == 0)
        
        // Wait briefly for timer to update
        try await Task.sleep(nanoseconds: 200_000_000)
        #expect(session.recordingDuration > 0)
    }
    
    @Test("Start recording from non-idle state should be ignored")
    func testStartRecordingFromNonIdleState() {
        let session = TranscriptionSession()
        
        session.startRecording()
        let firstState = session.state
        
        // Try to start recording again
        session.startRecording()
        
        // State should remain the same
        #expect(session.state.isActive == firstState.isActive)
    }
    
    @Test("Stop recording transitions to processing")
    func testStopRecording() {
        let session = TranscriptionSession()
        
        session.startRecording()
        session.stopRecording()
        
        #expect(session.state.isActive == true) // Should be processing
        
        // Check that we're in processing state specifically
        switch session.state {
        case .processing:
            break // Expected
        default:
            Issue.record("Expected processing state")
        }
    }
    
    @Test("Stop recording from non-recording state should be ignored")
    func testStopRecordingFromNonRecordingState() {
        let session = TranscriptionSession()
        
        // Try to stop recording when not recording
        session.stopRecording()
        
        // Should remain idle
        #expect(session.state.isActive == false)
    }
    
    @Test("Complete transcription adds to history")
    func testCompleteTranscription() {
        let session = TranscriptionSession()
        
        session.startRecording()
        session.stopRecording()
        
        let testText = "Test transcription"
        session.completeTranscription(text: testText)
        
        #expect(session.transcriptionHistory.count == 1)
        #expect(session.transcriptionHistory.first?.text == testText)
        #expect(session.state.isActive == false)
    }
    
    @Test("Complete transcription from non-processing state should be ignored")
    func testCompleteTranscriptionFromNonProcessingState() {
        let session = TranscriptionSession()
        
        session.completeTranscription(text: "Should be ignored")
        
        #expect(session.transcriptionHistory.isEmpty)
        #expect(session.state.isActive == false)
    }
    
    @Test("Fail transcription handles error")
    func testFailTranscription() {
        let session = TranscriptionSession()
        
        session.startRecording()
        session.stopRecording()
        
        let testError = NSError(domain: "TestError", code: 789, userInfo: [NSLocalizedDescriptionKey: "Transcription failed"])
        session.failTranscription(error: testError)
        
        #expect(session.state.isActive == false)
        
        switch session.state {
        case .error(let error):
            #expect(error.localizedDescription == "Transcription failed")
        default:
            Issue.record("Expected error state")
        }
    }
    
    @Test("Clear history removes all transcriptions")
    func testClearHistory() {
        let session = TranscriptionSession()
        
        // Add some transcriptions
        session.startRecording()
        session.stopRecording()
        session.completeTranscription(text: "First")
        
        session.startRecording()
        session.stopRecording()
        session.completeTranscription(text: "Second")
        
        #expect(session.transcriptionHistory.count == 2)
        
        session.clearHistory()
        
        #expect(session.transcriptionHistory.isEmpty)
    }
    
    @Test("Get recent transcriptions with limit")
    func testGetRecentTranscriptions() {
        let session = TranscriptionSession()
        
        // Add multiple transcriptions
        for i in 1...15 {
            session.startRecording()
            session.stopRecording()
            session.completeTranscription(text: "Transcription \(i)")
        }
        
        let recent = session.getRecentTranscriptions(limit: 5)
        
        #expect(recent.count == 5)
        #expect(recent.last?.text == "Transcription 15")
        #expect(recent.first?.text == "Transcription 11")
    }
    
    @Test("Get recent transcriptions default limit")
    func testGetRecentTranscriptionsDefaultLimit() {
        let session = TranscriptionSession()
        
        // Add 15 transcriptions
        for i in 1...15 {
            session.startRecording()
            session.stopRecording()
            session.completeTranscription(text: "Transcription \(i)")
        }
        
        let recent = session.getRecentTranscriptions()
        
        #expect(recent.count == 10) // Default limit
        #expect(recent.last?.text == "Transcription 15")
        #expect(recent.first?.text == "Transcription 6")
    }
    
    @Test("Transcription result has correct duration")
    func testTranscriptionResultDuration() async throws {
        let session = TranscriptionSession()
        
        session.startRecording()
        
        // Wait for some recording time
        try await Task.sleep(nanoseconds: 500_000_000)
        
        session.stopRecording()
        session.completeTranscription(text: "Test")
        
        #expect(session.transcriptionHistory.first?.duration ?? 0 > 0.4)
    }
}
