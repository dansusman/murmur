import Foundation
import AVFoundation
import ScreenCaptureKit
import OSLog
import Combine

protocol ScreenAudioRecorderDelegate: AnyObject {
    func screenAudioRecorder(_ recorder: ScreenAudioRecorder, didStartRecording: Bool)
    func screenAudioRecorder(_ recorder: ScreenAudioRecorder, didFailWithError error: Error)
    func screenAudioRecorder(_ recorder: ScreenAudioRecorder, didReceiveAudioChunk data: Data, timestamp: TimeInterval)
}

class ScreenAudioRecorder: NSObject, ObservableObject {
    weak var delegate: ScreenAudioRecorderDelegate?
    
    private let logger = Logger.screenCapture
    
    @Published var isRunning = false
    @Published var canRecord = false
    
    private var stream: SCStream?
    private var streamOutput: ScreenAudioStreamOutput?
    private let audioSampleBufferQueue = DispatchQueue(label: "com.murmur.AudioSampleBufferQueue")
    
    private struct TimestampedAudioData {
        let data: Data
        let timestamp: TimeInterval
    }
    
    private var recordedAudioChunks: [TimestampedAudioData] = []
    private let audioDataQueue = DispatchQueue(label: "com.murmur.AudioDataQueue")
    private var audioConverter: AVAudioConverter?
    private let targetFormat: AVAudioFormat
    
    override init() {
        // Configure audio format for Whisper (16kHz, mono, 32-bit float)
        targetFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: 16000,
            channels: 1,
            interleaved: false
        )!
        
        super.init()
        
        Task {
            await checkRecordingPermission()
        }
    }
    
    private func checkRecordingPermission() async {
        do {
            try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            await MainActor.run {
                self.canRecord = true
                self.logger.info("Screen recording permission granted")
            }
        } catch {
            await MainActor.run {
                self.canRecord = false
                self.logger.warning("Screen recording permission not granted: \(error)")
            }
        }
    }
    
    func startCapture() async throws {
        guard !isRunning else {
            logger.warning("Already recording")
            return
        }
        
        logger.info("Starting screen audio capture")
        
        // Ensure we clean up any existing stream first
        if let existingStream = stream {
            logger.info("Cleaning up existing stream before starting new one")
            try? await existingStream.stopCapture()
            stream = nil
        }
        streamOutput = nil
        
        // Check permissions in real-time and get available content
        let availableContent: SCShareableContent
        do {
            availableContent = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
            // Update permission status
            await MainActor.run {
                self.canRecord = true
            }
            logger.info("Screen recording permission verified")
        } catch {
            await MainActor.run {
                self.canRecord = false
            }
            logger.error("Screen recording permission denied: \(error)")
            throw ScreenAudioRecorderError.permissionDenied
        }
        guard let display = availableContent.displays.first else {
            throw ScreenAudioRecorderError.noDisplayAvailable
        }
        
        // Create content filter - exclude this app
        let excludedApps = availableContent.applications.filter { app in
            Bundle.main.bundleIdentifier == app.bundleIdentifier
        }
        let contentFilter = SCContentFilter(display: display, excludingApplications: excludedApps, exceptingWindows: [])
        
        // Configure stream for audio-only capture (system audio only)
        let streamConfig = SCStreamConfiguration()
        streamConfig.capturesAudio = true
        streamConfig.captureMicrophone = false

        // Audio settings - match Whisper's native format to avoid any conversion
        streamConfig.channelCount = 1
        streamConfig.sampleRate = 16000
        
        // Use minimal dimensions - zero might cause issues
        streamConfig.width = 2
        streamConfig.height = 2

        // Set very slow frame rate and disable cursor to minimize video processing
        streamConfig.minimumFrameInterval = CMTime(value: 1, timescale: .max)
        streamConfig.showsCursor = true

        // Reset recorded data and set start time
        audioDataQueue.sync {
            recordedAudioChunks = []
        }
        
        // Create stream output with stronger reference
        let newStreamOutput = ScreenAudioStreamOutput()
        newStreamOutput.startTime = Date().timeIntervalSince1970
        newStreamOutput.audioDataHandler = { [weak self] audioData, timestamp in
            self?.processAudioData(audioData, timestamp: timestamp)
        }
        newStreamOutput.errorHandler = { [weak self] error in
            self?.handleStreamError(error)
        }
        self.streamOutput = newStreamOutput
        
        // Debug logging
        logger.info("Creating SCStream with display: \(display.displayID), excluded apps: \(excludedApps.count)")
        logger.info("Stream config - audio: \(streamConfig.capturesAudio), size: \(streamConfig.width)x\(streamConfig.height)")
        
        // Create stream with explicit delegate assignment
        let newStream = SCStream(filter: contentFilter, configuration: streamConfig, delegate: newStreamOutput)

        // Store strong reference immediately
        self.stream = newStream
        logger.info("SCStream created successfully: \(newStream)")
        
        // Add stream output for system audio only
        logger.info("Adding audio stream output...")
        try newStream.addStreamOutput(newStreamOutput, type: .audio, sampleHandlerQueue: audioSampleBufferQueue)

        // Add screen output to prevent errors, but we'll ignore the frames in the handler
        logger.info("Adding screen output to prevent frame dropping errors...")
        try newStream.addStreamOutput(newStreamOutput, type: .screen, sampleHandlerQueue: DispatchQueue(label: "com.murmur.ScreenSampleBufferQueue"))
        
        // Start capture using synchronous version like Apple sample
        logger.info("Starting stream capture...")
        try await newStream.startCapture()
        logger.info("SCStream startCapture called successfully")

        await MainActor.run {
            self.isRunning = true
            self.delegate?.screenAudioRecorder(self, didStartRecording: true)
        }
        
        logger.success("Screen audio capture started successfully")
    }
    
    func stopCapture() async -> Data? {
        guard isRunning else {
            logger.warning("Not currently recording")
            return nil
        }
        
        logger.info("Stopping screen audio capture")
        
        do {
            try await stream?.stopCapture()
        } catch {
            logger.error("Error stopping stream: \(error)")
        }
        
        stream = nil
        streamOutput = nil
        
        await MainActor.run {
            self.isRunning = false
        }
        
        // Convert recorded audio to WAV format with chronological ordering
        let audioData = convertToWAV()
        logger.info("Screen audio capture stopped, chunks: \(recordedAudioChunks.count), data size: \(audioData?.count ?? 0) bytes")
        
        
        return audioData
    }
    
    private func processAudioData(_ audioData: Data, timestamp: TimeInterval) {
        audioDataQueue.async { [weak self] in
            let timestampedData = TimestampedAudioData(data: audioData, timestamp: timestamp)
            self?.recordedAudioChunks.append(timestampedData)
            
            // Also notify delegate immediately for real-time mixing
            DispatchQueue.main.async {
                self?.delegate?.screenAudioRecorder(self!, didReceiveAudioChunk: audioData, timestamp: timestamp)
            }
        }
    }
    
    private func handleStreamError(_ error: Error) {
        logger.error("Stream error: \(error)")
        Task { @MainActor in
            self.isRunning = false
            self.delegate?.screenAudioRecorder(self, didFailWithError: error)
        }
    }
    
    private func convertToWAV() -> Data? {
        let chunks = audioDataQueue.sync { recordedAudioChunks }
        guard !chunks.isEmpty else { 
            logger.warning("No audio chunks to convert")
            return nil 
        }
        
        // Sort chunks chronologically and combine
        let sortedChunks = chunks.sorted { $0.timestamp < $1.timestamp }
        var audioData = Data()
        for chunk in sortedChunks {
            audioData.append(chunk.data)
        }
        
        let sampleRate: UInt32 = 16000  // Match capture sample rate
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
        header.append(withUnsafeBytes(of: UInt32(16).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: UInt16(3).littleEndian) { Data($0) }) // IEEE float
        header.append(withUnsafeBytes(of: channels.littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: sampleRate.littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: (sampleRate * UInt32(channels * bitsPerSample / 8)).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: (channels * bitsPerSample / 8).littleEndian) { Data($0) })
        header.append(withUnsafeBytes(of: bitsPerSample.littleEndian) { Data($0) })
        
        // data chunk
        header.append("data".data(using: .ascii)!)
        header.append(withUnsafeBytes(of: dataSize.littleEndian) { Data($0) })
        
        logger.info("Converted audio data to WAV format: \(header.count + audioData.count) bytes")
        return header + audioData
    }
    
}

private class ScreenAudioStreamOutput: NSObject, SCStreamOutput, SCStreamDelegate {
    var audioDataHandler: ((Data, TimeInterval) -> Void)?
    var errorHandler: ((Error) -> Void)?
    
    var startTime: TimeInterval = 0
    
    private let logger = Logger.screenCapture
    
    func stream(_ stream: SCStream, didOutputSampleBuffer sampleBuffer: CMSampleBuffer, of outputType: SCStreamOutputType) {
        guard sampleBuffer.isValid else { return }
        
        switch outputType {
        case .audio:
            handleSystemAudio(for: sampleBuffer)
        case .microphone:
            // Ignore microphone from SCStream like QuickRecorder does
            break
        case .screen:
            break // We don't need video
        @unknown default:
            logger.warning("Unknown stream output type: \(outputType)")
        }
    }
    
    private func handleSystemAudio(for sampleBuffer: CMSampleBuffer) {
        do {
            try sampleBuffer.withAudioBufferList { audioBufferList, blockBuffer in
                guard let description = sampleBuffer.formatDescription?.audioStreamBasicDescription else { return }
                
                logger.info("System audio format - Rate: \(description.mSampleRate), Channels: \(description.mChannelsPerFrame), Format: \(description.mFormatID)")
                
                // Check if we're actually getting 16kHz as configured
                if description.mSampleRate != 16000 {
                    logger.warning("System audio sample rate mismatch! Expected 16000, got \(description.mSampleRate)")
                }
                
                // Direct extraction - no conversion needed since we're capturing at target format
                guard let inputBuffer = AVAudioPCMBuffer(pcmFormat: AVAudioFormat(standardFormatWithSampleRate: description.mSampleRate, channels: description.mChannelsPerFrame)!, 
                                                       bufferListNoCopy: audioBufferList.unsafePointer) else { return }
                
                let frameLength = Int(inputBuffer.frameLength)
                if let channelData = inputBuffer.floatChannelData?[0] {
                    let audioData = Data(bytes: channelData, count: frameLength * MemoryLayout<Float>.size)
                    let currentTime = Date().timeIntervalSince1970
                    let relativeTime = currentTime - startTime
                    
                    logger.debug("System audio chunk: \(frameLength) frames, \(audioData.count) bytes at \(String(format: "%.2f", relativeTime))s")
                    audioDataHandler?(audioData, relativeTime)
                }
            }
        } catch {
            logger.error("Error processing system audio buffer: \(error)")
        }
    }
    
    func stream(_ stream: SCStream, didStopWithError error: Error) {
        logger.error("Stream stopped with error: \(error)")
        errorHandler?(error)
    }
}

enum ScreenAudioRecorderError: Error, LocalizedError {
    case permissionDenied
    case noDisplayAvailable
    case setupFailed
    
    var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Screen recording permission denied"
        case .noDisplayAvailable:
            return "No display available for capture"
        case .setupFailed:
            return "Failed to setup screen audio capture"
        }
    }
}
