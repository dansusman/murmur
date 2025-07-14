import Foundation
import Testing
@testable import Murmur

@Suite("TranscriptionSession Integration Tests")
struct TranscriptionSessionIntegrationTests {
    
    @Test("Complete transcription workflow")
    func testCompleteTranscriptionWorkflow() async throws {
        let session = TranscriptionSession()
        
        // Initial state
        #expect(session.state.isActive == false)
        #expect(session.recordingDuration == 0)
        #expect(session.transcriptionHistory.isEmpty)
        
        // Start recording
        session.startRecording()
        #expect(session.state.isActive == true)
        
        // Wait for recording to build up some duration
        try await Task.sleep(nanoseconds: 500_000_000)
        #expect(session.recordingDuration > 0)
        
        // Stop recording
        session.stopRecording()
        #expect(session.state.isActive == true) // Should be processing
        
        // Complete transcription
        let testText = "Hello, this is a test transcription"
        session.completeTranscription(text: testText)
        
        #expect(session.transcriptionHistory.count == 1)
        #expect(session.transcriptionHistory.first?.text == testText)
        #expect(session.state.isActive == false)
        
        // Wait for auto-reset to idle
        try await Task.sleep(nanoseconds: 2_100_000_000)
        
        switch session.state {
        case .idle:
            break // Expected
        default:
            Issue.record("Expected idle state after auto-reset")
        }
    }
    
    @Test("Error handling in transcription workflow")
    func testErrorHandlingInTranscriptionWorkflow() async throws {
        let session = TranscriptionSession()
        
        // Start recording
        session.startRecording()
        #expect(session.state.isActive == true)
        
        // Stop recording
        session.stopRecording()
        #expect(session.state.isActive == true) // Should be processing
        
        // Simulate transcription failure
        let testError = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Transcription failed"])
        session.failTranscription(error: testError)
        
        #expect(session.state.isActive == false)
        #expect(session.transcriptionHistory.isEmpty) // No transcription added on failure
        
        // Verify error state
        switch session.state {
        case .error(let error):
            #expect(error.localizedDescription == "Transcription failed")
        default:
            Issue.record("Expected error state")
        }
        
        // Wait for auto-reset to idle
        try await Task.sleep(nanoseconds: 3_100_000_000)
        
        switch session.state {
        case .idle:
            break // Expected
        default:
            Issue.record("Expected idle state after error auto-reset")
        }
    }
    
    @Test("Multiple transcription sessions")
    func testMultipleTranscriptionSessions() async throws {
        let session = TranscriptionSession()
        
        // Perform multiple transcription sessions
        for i in 1...5 {
            session.startRecording()
            
            // Short recording time
            try await Task.sleep(nanoseconds: 100_000_000)
            
            session.stopRecording()
            session.completeTranscription(text: "Transcription \(i)")
            
            // Wait for state to settle
            try await Task.sleep(nanoseconds: 100_000_000)
        }
        
        // Check history
        #expect(session.transcriptionHistory.count == 5)
        for i in 1...5 {
            let transcription = session.transcriptionHistory[i - 1]
            #expect(transcription.text == "Transcription \(i)")
        }
        
        // Test recent transcriptions
        let recent = session.getRecentTranscriptions(limit: 3)
        #expect(recent.count == 3)
        #expect(recent[0].text == "Transcription 3")
        #expect(recent[1].text == "Transcription 4")
        #expect(recent[2].text == "Transcription 5")
    }
    
    @Test("Concurrent state transitions")
    func testConcurrentStateTransitions() async {
        let session = TranscriptionSession()
        
        // Try to start recording multiple times concurrently
        session.startRecording()
        session.startRecording() // Should be ignored
        session.startRecording() // Should be ignored
        
        #expect(session.state.isActive == true)
        
        // Try to stop recording multiple times
        session.stopRecording()
        session.stopRecording() // Should be ignored
        
        #expect(session.state.isActive == true) // Should be processing
        
        // Complete transcription
        session.completeTranscription(text: "Concurrent test")
        
        #expect(session.transcriptionHistory.count == 1)
        #expect(session.transcriptionHistory.first?.text == "Concurrent test")
    }
    
    @Test("Recording duration accuracy")
    func testRecordingDurationAccuracy() async throws {
        let session = TranscriptionSession()
        
        session.startRecording()
        
        // Record for approximately 1 second
        try await Task.sleep(nanoseconds: 1_000_000_000)
        
        let recordedDuration = session.recordingDuration
        session.stopRecording()
        session.completeTranscription(text: "Duration test")
        
        // Check that recorded duration is approximately 1 second (with some tolerance)
        #expect(recordedDuration >= 0.9 && recordedDuration <= 1.1)
        
        // Check that transcription result has correct duration
        #expect(session.transcriptionHistory.first?.duration ?? 0 >= 0.9)
        #expect(session.transcriptionHistory.first?.duration ?? 0 <= 1.1)
    }
    
    @Test("History management")
    func testHistoryManagement() async throws {
        let session = TranscriptionSession()
        
        // Add many transcriptions
        for i in 1...20 {
            session.startRecording()
            
            try await Task.sleep(nanoseconds: 50_000_000)
            
            session.stopRecording()
            session.completeTranscription(text: "History test \(i)")
        }
        
        #expect(session.transcriptionHistory.count == 20)
        
        // Test recent transcriptions with default limit
        let recentDefault = session.getRecentTranscriptions()
        #expect(recentDefault.count == 10) // Default limit
        #expect(recentDefault.first?.text == "History test 11")
        #expect(recentDefault.last?.text == "History test 20")
        
        // Test recent transcriptions with custom limit
        let recentCustom = session.getRecentTranscriptions(limit: 5)
        #expect(recentCustom.count == 5)
        #expect(recentCustom.first?.text == "History test 16")
        #expect(recentCustom.last?.text == "History test 20")
        
        // Clear history
        session.clearHistory()
        #expect(session.transcriptionHistory.isEmpty)
        
        // Test recent transcriptions after clearing
        let recentAfterClear = session.getRecentTranscriptions()
        #expect(recentAfterClear.isEmpty)
    }
    
    @Test("State machine invariants")
    func testStateMachineInvariants() async {
        let session = TranscriptionSession()
        
        // Test invalid state transitions
        
        // Cannot stop recording when not recording
        session.stopRecording()
        #expect(session.state.isActive == false) // Should remain idle
        
        // Cannot complete transcription when not processing
        session.completeTranscription(text: "Invalid completion")
        #expect(session.transcriptionHistory.isEmpty) // Should not add to history
        
        // Cannot fail transcription when not processing
        let testError = NSError(domain: "TestError", code: 400, userInfo: [NSLocalizedDescriptionKey: "Invalid failure"])
        session.failTranscription(error: testError)
        #expect(session.state.isActive == false) // Should remain idle
        
        // Start recording and test valid transitions
        session.startRecording()
        #expect(session.state.isActive == true)
        
        // Cannot start recording when already recording
        session.startRecording()
        #expect(session.state.isActive == true) // Should remain recording
        
        // Stop recording to enter processing state
        session.stopRecording()
        #expect(session.state.isActive == true) // Should be processing
        
        // Cannot start recording when processing
        session.startRecording()
        #expect(session.state.isActive == true) // Should remain processing
        
        // Complete transcription
        session.completeTranscription(text: "Valid completion")
        #expect(session.transcriptionHistory.count == 1)
        #expect(session.state.isActive == false) // Should be completed
    }
    
    @Test("Transcription result metadata")
    func testTranscriptionResultMetadata() async throws {
        let session = TranscriptionSession()
        
        session.startRecording()
        
        let startTime = Date()
        
        // Record for a specific duration
        try await Task.sleep(nanoseconds: 300_000_000)
        
        session.stopRecording()
        
        let completionTime = Date()
        session.completeTranscription(text: "Metadata test")
        
        guard let result = session.transcriptionHistory.first else {
            Issue.record("No transcription result found")
            return
        }
        
        // Check metadata
        #expect(result.text == "Metadata test")
        #expect(result.duration >= 0.25 && result.duration <= 0.35) // Approximately 0.3 seconds
        #expect(result.timestamp >= startTime && result.timestamp <= completionTime)
        #expect(result.confidence == nil) // Default confidence is nil
    }
}
