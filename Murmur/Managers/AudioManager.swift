import Foundation
import AVFoundation
import CoreAudio

class AudioManager: NSObject, ObservableObject {
    weak var delegate: AudioManagerDelegate?
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioBuffer: AVAudioPCMBuffer?
    private var audioFormat: AVAudioFormat?
    private var recordedAudioData = Data()
    
    @Published var isRecording = false
    @Published var recordingPermissionGranted = false
    
    override init() {
        super.init()
        setupAudioEngine()
        requestMicrophonePermission()
    }
    
    deinit {
        stopRecording()
    }
    
    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        
        guard let audioEngine = audioEngine else { return }
        
        inputNode = audioEngine.inputNode
        
        // Configure audio format for Whisper (16kHz, mono, 16-bit)
        audioFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )
        
        guard let audioFormat = audioFormat else {
            print("Failed to create audio format")
            return
        }
        
        // Create audio buffer
        let bufferSize = AVAudioFrameCount(1024)
        audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: bufferSize)
    }
    
    private func requestMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            DispatchQueue.main.async {
                self.recordingPermissionGranted = true
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { [weak self] granted in
                DispatchQueue.main.async {
                    self?.recordingPermissionGranted = granted
                    if !granted {
                        print("Microphone permission denied")
                    }
                }
            }
        case .denied, .restricted:
            DispatchQueue.main.async {
                self.recordingPermissionGranted = false
                print("Microphone permission denied")
            }
        @unknown default:
            DispatchQueue.main.async {
                self.recordingPermissionGranted = false
                print("Unknown microphone permission status")
            }
        }
    }
    
    func startRecording() {
        guard recordingPermissionGranted else {
            print("Recording permission not granted")
            delegate?.audioManager(self, didFailWithError: AudioManagerError.permissionDenied)
            return
        }
        
        guard let audioEngine = audioEngine,
              let inputNode = inputNode,
              let audioFormat = audioFormat else {
            delegate?.audioManager(self, didFailWithError: AudioManagerError.setupFailed)
            return
        }
        
        // Reset recorded data
        recordedAudioData = Data()
        
        // Install tap to capture audio
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: audioFormat) { [weak self] (buffer, time) in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
            DispatchQueue.main.async {
                self.isRecording = true
                self.delegate?.audioManager(self, didStartRecording: true)
            }
        } catch {
            print("Failed to start audio engine: \(error)")
            delegate?.audioManager(self, didFailWithError: error)
        }
    }
    
    func stopRecording() {
        guard let audioEngine = audioEngine,
              let inputNode = inputNode else { return }
        
        inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        
        DispatchQueue.main.async {
            self.isRecording = false
            
            // Convert to WAV format for whisper.cpp
            if let wavData = self.convertToWAV() {
                self.delegate?.audioManager(self, didFinishRecording: wavData)
            } else {
                self.delegate?.audioManager(self, didFailWithError: AudioManagerError.recordingFailed)
            }
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let floatChannelData = buffer.floatChannelData else { return }
        
        let frameLength = Int(buffer.frameLength)
        let channelCount = Int(buffer.format.channelCount)
        
        // Convert float32 to Data (for Whisper processing)
        for channel in 0..<channelCount {
            let channelData = floatChannelData[channel]
            let data = Data(bytes: channelData, count: frameLength * MemoryLayout<Float>.size)
            recordedAudioData.append(data)
        }
    }
    
    // Convert recorded audio data to WAV format for Whisper
    func convertToWAV() -> Data? {
        guard !recordedAudioData.isEmpty else { return nil }
        
        let sampleRate: UInt32 = 16000
        let channels: UInt16 = 1
        let bitsPerSample: UInt16 = 32 // Float32
        
        let dataSize = UInt32(recordedAudioData.count)
        let fileSize = dataSize + 36
        
        var header = Data()
        
        // RIFF header
        header.append("RIFF".data(using: .ascii)!)
        header.append(withUnsafeBytes(of: fileSize.littleEndian) { Data($0) })
        header.append("WAVE".data(using: .ascii)!)
        
        // fmt chunk
        header.append("fmt ".data(using: .ascii)!)
        header.append(withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) }) // chunk size
        header.append(withUnsafeBytes(of: UInt16(3).littleEndian) { Data($0) }) // format (IEEE float)
        header.append(withUnsafeBytes(of: channels.littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: sampleRate.littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: (sampleRate * UInt32(channels * bitsPerSample / 8)).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: (channels * bitsPerSample / 8).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })
        
        // data chunk
        header.append("data".data(using: .ascii)!)
        header.append(withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })
        
        return header + recordedAudioData
    }
}

// MARK: - Audio Manager Errors
enum AudioManagerError: Error, LocalizedError {
    case permissionDenied
    case setupFailed
    case recordingFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied"
        case .setupFailed:
            return "Failed to setup audio engine"
        case .recordingFailed:
            return "Recording failed"
        }
    }
}