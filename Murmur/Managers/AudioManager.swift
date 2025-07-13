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
    private var audioConverter: AVAudioConverter?
    
    @Published var isRecording = false
    @Published var recordingPermissionGranted = false
    
    override init() {
        super.init()
        setupAudioEngine()
        checkMicrophonePermission()
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
            Logger.audio.error("Failed to create audio format")
            return
        }
        
        // Create audio buffer
        let bufferSize = AVAudioFrameCount(1024)
        audioBuffer = AVAudioPCMBuffer(pcmFormat: audioFormat, frameCapacity: bufferSize)
    }
    
    private func checkMicrophonePermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        recordingPermissionGranted = (status == .authorized)
        
        if recordingPermissionGranted {
            Logger.audio.info("🎤 Microphone permission already granted")
        } else {
            Logger.audio.warning("🎤 Microphone permission not granted")
        }
    }
    
    func pollMicrophonePermission() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let status = AVCaptureDevice.authorizationStatus(for: .audio)
            self.recordingPermissionGranted = (status == .authorized)
            
            if !self.recordingPermissionGranted {
                self.pollMicrophonePermission()
            }
        }
    }
    
    static func requestMicrophonePermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        
        switch status {
        case .authorized:
            Logger.audio.info("🎤 Microphone permission already granted")
        case .notDetermined:
            Logger.audio.info("🎤 Requesting microphone permission...")
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                if granted {
                    Logger.audio.success("🎤 Microphone permission granted")
                } else {
                    Logger.audio.error("🎤 Microphone permission denied")
                }
            }
        case .denied, .restricted:
            Logger.audio.error("🎤 Microphone permission previously denied")
        @unknown default:
            Logger.audio.warning("🎤 Unknown microphone permission status")
        }
    }
    
    func startRecording() {
        Logger.audio.info("🎤 startRecording() called")
        
        guard recordingPermissionGranted else {
            Logger.audio.error("Recording permission not granted")
            delegate?.audioManager(self, didFailWithError: AudioManagerError.permissionDenied)
            return
        }
        
        guard let audioEngine = audioEngine,
              let inputNode = inputNode else {
            Logger.audio.error("Audio engine setup failed")
            delegate?.audioManager(self, didFailWithError: AudioManagerError.setupFailed)
            return
        }
        
        Logger.audio.info("🔧 Setting up audio recording...")
        
        // Reset recorded data
        recordedAudioData = Data()
        
        // Use the input node's hardware format for the tap
        let inputFormat = inputNode.inputFormat(forBus: 0)
        Logger.audio.debug("🔧 Hardware format: \(inputFormat.sampleRate)Hz, \(inputFormat.channelCount) channels")
        
        // Setup audio converter for resampling to 16kHz
        guard let targetFormat = audioFormat else {
            Logger.audio.error("Target audio format not available")
            delegate?.audioManager(self, didFailWithError: AudioManagerError.setupFailed)
            return
        }
        
        audioConverter = AVAudioConverter(from: inputFormat, to: targetFormat)
        guard audioConverter != nil else {
            Logger.audio.error("Failed to create audio converter")
            delegate?.audioManager(self, didFailWithError: AudioManagerError.setupFailed)
            return
        }
        
        // Install tap to capture audio using hardware format
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] (buffer, time) in
            self?.processAudioBuffer(buffer)
        }
        
        do {
            try audioEngine.start()
            Logger.audio.success("Audio engine started successfully")
            DispatchQueue.main.async {
                self.isRecording = true
                self.delegate?.audioManager(self, didStartRecording: true)
            }
        } catch {
            Logger.audio.error("Failed to start audio engine: \(error)")
            delegate?.audioManager(self, didFailWithError: error)
        }
    }
    
    func stopRecording() {
        Logger.audio.info("🛑 stopRecording() called")
        
        guard let audioEngine = audioEngine,
              let inputNode = inputNode else { 
            Logger.audio.warning("stopRecording() - audio engine or input node is nil")
            return 
        }
        
        Logger.audio.info("🔧 Stopping audio engine...")
        inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        
        DispatchQueue.main.async {
            self.isRecording = false
            
            Logger.audio.info("🔄 Converting audio to WAV format...")
            // Convert to WAV format for whisper.cpp
            if let wavData = self.convertToWAV() {
                Logger.audio.success("Audio conversion successful, size: \(wavData.count) bytes")
                self.delegate?.audioManager(self, didFinishRecording: wavData)
            } else {
                Logger.audio.error("Audio conversion failed")
                self.delegate?.audioManager(self, didFailWithError: AudioManagerError.recordingFailed)
            }
        }
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let converter = audioConverter,
              let targetFormat = audioFormat else { return }
        
        // Calculate output buffer size based on sample rate ratio
        let ratio = targetFormat.sampleRate / buffer.format.sampleRate
        let outputFrameCount = AVAudioFrameCount(Double(buffer.frameLength) * ratio)
        
        guard let outputBuffer = AVAudioPCMBuffer(pcmFormat: targetFormat, frameCapacity: outputFrameCount) else {
            return
        }
        
        var error: NSError?
        let status = converter.convert(to: outputBuffer, error: &error) { _, outStatus in
            outStatus.pointee = .haveData
            return buffer
        }
        
        guard status == .haveData, let floatChannelData = outputBuffer.floatChannelData else { return }
        
        let frameLength = Int(outputBuffer.frameLength)
        let channelCount = Int(outputBuffer.format.channelCount)
        
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