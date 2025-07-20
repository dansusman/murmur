import Foundation
import AVFoundation
import CoreAudio
import ScreenCaptureKit

// MARK: - Recording Mode
enum RecordingMode {
    case microphoneOnly
    case meetingMode // Microphone + System Audio via ScreenCaptureKit
}

class AudioManager: NSObject, ObservableObject {
    weak var delegate: AudioManagerDelegate?
    
    private var audioEngine: AVAudioEngine?
    private var inputNode: AVAudioInputNode?
    private var audioBuffer: AVAudioPCMBuffer?
    private var audioFormat: AVAudioFormat?
    private var recordedAudioData = Data()
    private var audioConverter: AVAudioConverter?
    
    // Meeting mode: timestamped audio chunks for chronological mixing
    private struct TimestampedAudioChunk {
        let audioData: Data
        let timestamp: TimeInterval
        let source: AudioSource
    }
    
    private enum AudioSource {
        case microphone
        case system
    }
    
    private var timestampedAudioChunks: [TimestampedAudioChunk] = []
    private var recordingStartTime: TimeInterval = 0
    
    // ScreenCaptureKit integration for meeting mode
    private lazy var screenAudioRecorder: ScreenAudioRecorder = {
        let recorder = ScreenAudioRecorder()
        recorder.delegate = self
        return recorder
    }()
    
    @Published var isRecording = false
    @Published var recordingPermissionGranted = false
    @Published var recordingMode: RecordingMode = .microphoneOnly
    
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
    
    func startRecording(mode: RecordingMode? = nil) {
        let actualMode = mode ?? recordingMode
        currentRecordingMode = actualMode
        Logger.audio.info("🎤 startRecording() called - mode: \(actualMode)")
        
        if actualMode == .meetingMode {
            // Use ScreenCaptureKit for both microphone and system audio
            startMeetingModeRecording()
        } else {
            // Use AVAudioEngine for microphone-only recording
            startMicrophoneOnlyRecording()
        }
    }
    
    private func startMeetingModeRecording() {
        Logger.audio.info("🎤 Starting meeting mode recording with ScreenCaptureKit + AVAudioEngine")
        
        // Reset audio data and start timing
        timestampedAudioChunks = []
        recordedAudioData = Data()
        recordingStartTime = Date().timeIntervalSince1970
        
        // Start microphone capture using existing AVAudioEngine setup
        guard recordingPermissionGranted else {
            Logger.audio.error("Recording permission not granted for meeting mode")
            delegate?.audioManager(self, didFailWithError: AudioManagerError.permissionDenied)
            return
        }
        
        guard let audioEngine = audioEngine,
              let inputNode = inputNode else {
            Logger.audio.error("Audio engine setup failed for meeting mode")
            delegate?.audioManager(self, didFailWithError: AudioManagerError.setupFailed)
            return
        }
        
        // Setup microphone recording (reuse existing logic)
        let inputFormat = inputNode.inputFormat(forBus: 0)
        guard let targetFormat = audioFormat else {
            Logger.audio.error("Target audio format not available for meeting mode")
            delegate?.audioManager(self, didFailWithError: AudioManagerError.setupFailed)
            return
        }
        
        audioConverter = AVAudioConverter(from: inputFormat, to: targetFormat)
        guard audioConverter != nil else {
            Logger.audio.error("Failed to create audio converter for meeting mode")
            delegate?.audioManager(self, didFailWithError: AudioManagerError.setupFailed)
            return
        }
        
        // Install microphone tap
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] (buffer, time) in
            self?.processMicrophoneBuffer(buffer)
        }
        
        // Start both microphone and system audio capture
        do {
            try audioEngine.start()
            Logger.audio.success("Microphone engine started for meeting mode")
            
            // Now start system audio capture
            Task {
                do {
                    try await screenAudioRecorder.startCapture()
                    DispatchQueue.main.async {
                        self.isRecording = true
                        self.delegate?.audioManager(self, didStartRecording: true)
                    }
                } catch {
                    Logger.audio.error("Failed to start system audio capture: \(error)")
                    // Stop microphone if system audio fails
                    audioEngine.stop()
                    inputNode.removeTap(onBus: 0)
                    DispatchQueue.main.async {
                        self.delegate?.audioManager(self, didFailWithError: error)
                    }
                }
            }
        } catch {
            Logger.audio.error("Failed to start microphone engine for meeting mode: \(error)")
            delegate?.audioManager(self, didFailWithError: error)
        }
    }
    
    private func startMicrophoneOnlyRecording() {
        Logger.audio.info("🎤 Starting microphone-only recording with AVAudioEngine")
        
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
    
    private var currentRecordingMode: RecordingMode = .microphoneOnly
    
    func stopRecording() {
        Logger.audio.info("🛑 stopRecording() called - mode: \(currentRecordingMode)")
        
        if currentRecordingMode == .meetingMode {
            // Stop ScreenCaptureKit-based recording
            stopMeetingModeRecording()
        } else {
            // Stop AVAudioEngine-based recording
            stopMicrophoneOnlyRecording()
        }
    }
    
    private func stopMeetingModeRecording() {
        Logger.audio.info("🛑 Stopping meeting mode recording")
        
        // Stop microphone first
        guard let audioEngine = audioEngine,
              let inputNode = inputNode else {
            Logger.audio.warning("Audio engine or input node is nil during meeting mode stop")
            return
        }
        
        inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        Logger.audio.info("Microphone engine stopped for meeting mode")
        
        // Stop system audio capture
        Task {
            let systemAudioData = await screenAudioRecorder.stopCapture()
            DispatchQueue.main.async {
                self.processMeetingModeRecording(systemAudio: systemAudioData)
            }
        }
    }
    
    private func stopMicrophoneOnlyRecording() {
        Logger.audio.info("🛑 Stopping microphone-only recording")
        
        guard let audioEngine = audioEngine,
              let inputNode = inputNode else {
            Logger.audio.warning("stopRecording() - audio engine or input node is nil")
            return
        }
        
        Logger.audio.info("🔧 Stopping audio engine...")
        inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        
        DispatchQueue.main.async {
            self.processMicrophoneOnlyRecording()
        }
    }
    
    private func processMicrophoneOnlyRecording() {
        isRecording = false
        
        Logger.audio.info("🔄 Converting microphone audio to WAV format...")
        if let wavData = convertToWAV() {
            Logger.audio.success("Microphone audio conversion successful, size: \(wavData.count) bytes")
            delegate?.audioManager(self, didFinishRecording: wavData)
        } else {
            Logger.audio.error("Microphone audio conversion failed")
            delegate?.audioManager(self, didFailWithError: AudioManagerError.recordingFailed)
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
    
    private func processMicrophoneBuffer(_ buffer: AVAudioPCMBuffer) {
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
        
        // Create timestamped chunk for microphone data
        let currentTime = Date().timeIntervalSince1970
        let relativeTime = currentTime - recordingStartTime
        
        for channel in 0..<channelCount {
            let channelData = floatChannelData[channel]
            let data = Data(bytes: channelData, count: frameLength * MemoryLayout<Float>.size)
            
            let chunk = TimestampedAudioChunk(
                audioData: data,
                timestamp: relativeTime,
                source: .microphone
            )
            
            timestampedAudioChunks.append(chunk)
            Logger.audio.debug("Added microphone chunk at \(String(format: "%.2f", relativeTime))s, size: \(data.count) bytes")
        }
    }
    
    private func processMeetingModeRecording(systemAudio: Data?) {
        isRecording = false
        
        Logger.audio.info("🔄 Processing meeting mode audio")
        
        let micChunks = timestampedAudioChunks.filter { $0.source == .microphone }
        let sysChunks = timestampedAudioChunks.filter { $0.source == .system }
        
        Logger.audio.info("Total chunks - Microphone: \(micChunks.count), System: \(sysChunks.count)")
        Logger.audio.info("Total timestamped chunks: \(timestampedAudioChunks.count)")
        
        // Log first few chunks for debugging
        let sortedForDebug = timestampedAudioChunks.sorted { $0.timestamp < $1.timestamp }.prefix(10)
        for (index, chunk) in sortedForDebug.enumerated() {
            let sourceType = chunk.source == .microphone ? "MIC" : "SYS"
            Logger.audio.info("Chunk \(index): \(sourceType) at \(String(format: "%.2f", chunk.timestamp))s, \(chunk.audioData.count) bytes")
        }
        
        // Mix both audio streams chronologically
        let mixedAudioData = mixAudioStreamsChronologically()
        
        if !mixedAudioData.isEmpty {
            // Convert to WAV format
            if let wavData = convertMeetingModeToWAV(audioData: mixedAudioData) {
                Logger.audio.success("Meeting mode audio mixing successful, size: \(wavData.count) bytes")
                delegate?.audioManager(self, didFinishRecording: wavData)
            } else {
                Logger.audio.error("Meeting mode audio conversion failed")
                delegate?.audioManager(self, didFailWithError: AudioManagerError.recordingFailed)
            }
        } else {
            Logger.audio.error("No audio data available from either source")
            delegate?.audioManager(self, didFailWithError: AudioManagerError.recordingFailed)
        }
    }
    
    private func mixAudioStreamsChronologically() -> Data {
        // Sort ALL chunks (both microphone and system) by timestamp
        let sortedChunks = timestampedAudioChunks.sorted { $0.timestamp < $1.timestamp }
        
        var mixedData = Data()
        
        let micCount = sortedChunks.filter { $0.source == .microphone }.count
        let sysCount = sortedChunks.filter { $0.source == .system }.count
        Logger.audio.info("Mixing chunks - Microphone: \(micCount), System: \(sysCount)")
        
        for chunk in sortedChunks {
            let sourceType = chunk.source == .microphone ? "MIC" : "SYS"
            Logger.audio.debug("Adding \(sourceType) chunk at \(String(format: "%.2f", chunk.timestamp))s, size: \(chunk.audioData.count) bytes")
            mixedData.append(chunk.audioData)
        }
        
        Logger.audio.info("Mixed all audio streams chronologically: \(mixedData.count) bytes total")
        return mixedData
    }
    
    private func convertMeetingModeToWAV(audioData: Data) -> Data? {
        guard !audioData.isEmpty else { return nil }
        
        let sampleRate: UInt32 = 16000
        let channels: UInt16 = 1
        let bitsPerSample: UInt16 = 32 // Float32
        
        let dataSize = UInt32(audioData.count)
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
        
        return header + audioData
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

// MARK: - ScreenAudioRecorderDelegate
extension AudioManager: ScreenAudioRecorderDelegate {
    func screenAudioRecorder(_ recorder: ScreenAudioRecorder, didStartRecording: Bool) {
        Logger.audio.info("ScreenCaptureKit system audio capture started")
        // Don't call delegate here - we already called it in startMeetingModeRecording
    }
    
    func screenAudioRecorder(_ recorder: ScreenAudioRecorder, didFailWithError error: Error) {
        Logger.audio.error("ScreenCaptureKit system audio capture failed: \(error)")
        DispatchQueue.main.async {
            self.isRecording = false
            self.delegate?.audioManager(self, didFailWithError: error)
        }
    }
    
    func screenAudioRecorder(_ recorder: ScreenAudioRecorder, didReceiveAudioChunk data: Data, timestamp: TimeInterval) {
        // Add system audio chunks in real-time for chronological mixing
        let chunk = TimestampedAudioChunk(
            audioData: data,
            timestamp: timestamp,
            source: .system
        )
        timestampedAudioChunks.append(chunk)
        Logger.audio.debug("Added system audio chunk at \(String(format: "%.2f", timestamp))s, size: \(data.count) bytes")
    }
}

// MARK: - Audio Manager Errors
enum AudioManagerError: Error, LocalizedError {
    case permissionDenied
    case screenRecordingPermissionDenied
    case setupFailed
    case recordingFailed
    case unsupportedVersion
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Microphone permission denied"
        case .screenRecordingPermissionDenied:
            return "Screen recording permission denied (required for meeting mode)"
        case .setupFailed:
            return "Failed to setup audio engine"
        case .recordingFailed:
            return "Recording failed"
        case .unsupportedVersion:
            return "Meeting mode requires macOS 13.0 or later"
        }
    }
}