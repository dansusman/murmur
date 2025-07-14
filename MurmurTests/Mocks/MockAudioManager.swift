import Foundation
import AVFoundation
@testable import Murmur

class MockAudioManager: AudioManager {
    var shouldFailRecording = false
    var shouldFailPermission = false
    var simulateRecordingData = Data()
    var recordingDelay: TimeInterval = 0.1
    
    override var isRecording: Bool {
        get { super.isRecording }
        set { super.isRecording = newValue }
    }
    
    override var recordingPermissionGranted: Bool {
        get { !shouldFailPermission }
        set { super.recordingPermissionGranted = newValue }
    }
    
    override init() {
        super.init()
        // Set up mock state
        recordingPermissionGranted = true
    }
    
    override func startRecording() {
        if shouldFailPermission {
            delegate?.audioManager(self, didFailWithError: AudioManagerError.permissionDenied)
            return
        }
        
        if shouldFailRecording {
            delegate?.audioManager(self, didFailWithError: AudioManagerError.recordingFailed)
            return
        }
        
        isRecording = true
        delegate?.audioManager(self, didStartRecording: true)
    }
    
    override func stopRecording() {
        guard isRecording else { return }
        
        isRecording = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + recordingDelay) {
            if self.shouldFailRecording {
                self.delegate?.audioManager(self, didFailWithError: AudioManagerError.recordingFailed)
            } else {
                let audioData = self.simulateRecordingData.isEmpty ? self.createMockAudioData() : self.simulateRecordingData
                self.delegate?.audioManager(self, didFinishRecording: audioData)
            }
        }
    }
    
    override func convertToWAV() -> Data? {
        if shouldFailRecording {
            return nil
        }
        return simulateRecordingData.isEmpty ? createMockAudioData() : simulateRecordingData
    }
    
    private func createMockAudioData() -> Data {
        // Create mock WAV data with proper header
        let sampleRate: UInt32 = 16000
        let channels: UInt16 = 1
        let bitsPerSample: UInt16 = 32
        let sampleCount = 1024
        
        // Create some mock audio samples
        var samples = [Float](repeating: 0.0, count: sampleCount)
        for i in 0..<sampleCount {
            samples[i] = sin(Float(i) * 2.0 * Float.pi / 100.0) * 0.5
        }
        
        let audioData = Data(bytes: samples, count: sampleCount * MemoryLayout<Float>.size)
        let dataSize = UInt32(audioData.count)
        let fileSize = dataSize + 36
        
        var header = Data()
        
        // RIFF header
        header.append("RIFF".data(using: .ascii)!)
        header.append(withUnsafeBytes(of: fileSize.littleEndian) { Data($0) })
        header.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        header.append("fmt ".data(using: .ascii)!)
        header.append(withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: UInt16(3).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: channels.littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: sampleRate.littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: (sampleRate * UInt32(channels * bitsPerSample / 8)).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: (channels * bitsPerSample / 8).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })
        
        // data chunk
        header.append("data".data(using: .ascii)!)
        header.append(withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })
        
        return header + audioData
    }
    
    func simulatePermissionGranted() {
        shouldFailPermission = false
        recordingPermissionGranted = true
    }
    
    func simulatePermissionDenied() {
        shouldFailPermission = true
        recordingPermissionGranted = false
    }
    
    func simulateRecordingFailure() {
        shouldFailRecording = true
    }
    
    func simulateRecordingSuccess() {
        shouldFailRecording = false
    }
    
    func setMockAudioData(_ data: Data) {
        simulateRecordingData = data
    }
}