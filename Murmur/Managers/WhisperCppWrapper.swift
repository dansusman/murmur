import Foundation
import AVFoundation

class WhisperCppWrapper: NSObject, ObservableObject {
    private let whisperBinaryPath: String
    private let modelsDirectory: String
    
    @Published var isTranscribing = false
    @Published var availableModels: [WhisperModel] = []
    
    override init() {
        // Get paths to bundled resources
        if let binaryPath = Bundle.main.path(forResource: "whisper", ofType: nil) {
            whisperBinaryPath = binaryPath
        } else {
            whisperBinaryPath = ""
        }
        
        // Since the models are in the root of Resources, look for them there
        if let resourcesPath = Bundle.main.resourcePath {
            modelsDirectory = resourcesPath
        } else {
            modelsDirectory = ""
        }
        
        super.init()
        loadAvailableModels()
    }
    
    private func loadAvailableModels() {
        guard !modelsDirectory.isEmpty else { return }
        
        let fileManager = FileManager.default
        
        do {
            let files = try fileManager.contentsOfDirectory(atPath: modelsDirectory)
            availableModels = files.compactMap { filename in
                guard filename.hasPrefix("ggml-") && filename.hasSuffix(".bin") else { return nil }
                
                let modelName = filename
                    .replacingOccurrences(of: "ggml-", with: "")
                    .replacingOccurrences(of: ".bin", with: "")
                
                let modelPath = "\(modelsDirectory)/\(filename)"
                
                return WhisperModel(
                    name: modelName,
                    filename: filename,
                    path: modelPath,
                    size: getFileSize(at: modelPath)
                )
            }
        } catch {
            Logger.whisper.error("Failed to load available models: \(error)")
        }
    }
    
    private func getFileSize(at path: String) -> String {
        guard let attributes = try? FileManager.default.attributesOfItem(atPath: path),
              let fileSize = attributes[.size] as? NSNumber else {
            return "Unknown"
        }
        
        let sizeInMB = Double(fileSize.int64Value) / (1024 * 1024)
        return String(format: "%.0fMB", sizeInMB)
    }
    
    func transcribe(audioData: Data, using modelType: WhisperModelType, language: String = "en") async throws -> String {
        guard !whisperBinaryPath.isEmpty else {
            throw WhisperError.missingBinary
        }
        
        guard let model = availableModels.first(where: { $0.name == modelType.rawValue }) else {
            throw WhisperError.modelNotFound(modelType.rawValue)
        }
        
        isTranscribing = true
        defer { isTranscribing = false }
        
        // Create temporary audio file
        let tempDirectory = FileManager.default.temporaryDirectory
        let audioFile = tempDirectory.appendingPathComponent("temp_audio.wav")
        
        do {
            try audioData.write(to: audioFile)
            
            // Run whisper.cpp
            let result = try await runWhisperProcess(
                audioFile: audioFile,
                modelPath: model.path,
                language: language
            )
            
            // Clean up temporary file
            try? FileManager.default.removeItem(at: audioFile)
            
            return result
        } catch {
            // Clean up on error
            try? FileManager.default.removeItem(at: audioFile)
            throw error
        }
    }
    
    private func runWhisperProcess(audioFile: URL, modelPath: String, language: String) async throws -> String {
        return try await withCheckedThrowingContinuation { continuation in
            let process = Process()
            process.executableURL = URL(fileURLWithPath: whisperBinaryPath)
            
            // Configure whisper.cpp arguments
            process.arguments = [
                "-m", modelPath,           // Model path
                "-f", audioFile.path,      // Audio file
                "-l", language,            // Language
                "-np",                     // No print progress
                "-nt",                     // No timestamps
                "-of", "txt",              // Output format: text only
                "-pc",                     // Print colors off
                "-pp",                     // Print progress off
                "--output-file", "",       // Output to stdout
                "-t", "4"                  // Use 4 threads
            ]
            
            let outputPipe = Pipe()
            let errorPipe = Pipe()
            
            process.standardOutput = outputPipe
            process.standardError = errorPipe
            
            process.terminationHandler = { process in
                let outputData = outputPipe.fileHandleForReading.readDataToEndOfFile()
                let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
                
                if process.terminationStatus == 0 {
                    let output = String(data: outputData, encoding: .utf8) ?? ""
                    let cleanedOutput = self.cleanWhisperOutput(output)
                    continuation.resume(returning: cleanedOutput)
                } else {
                    let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown error"
                    continuation.resume(throwing: WhisperError.processError(errorMessage))
                }
            }
            
            do {
                try process.run()
            } catch {
                continuation.resume(throwing: WhisperError.processError(error.localizedDescription))
            }
        }
    }
    
    private func cleanWhisperOutput(_ output: String) -> String {
        // Remove whisper.cpp specific output formatting
        let lines = output.components(separatedBy: .newlines)
        
        // Filter out whisper.cpp metadata lines
        let filteredLines = lines.filter { line in
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            
            // Skip empty lines
            guard !trimmed.isEmpty else { return false }
            
            // Skip whisper.cpp info lines
            if trimmed.starts(with: "whisper_") ||
               trimmed.starts(with: "system_info:") ||
               trimmed.starts(with: "main:") ||
               trimmed.contains("processing") ||
               trimmed.contains("sample_rate") ||
               trimmed.contains("n_threads") {
                return false
            }
            
            return true
        }
        
        let joinedOutput = filteredLines.joined(separator: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Remove ANSI escape codes (color formatting)
        let cleanedOutput = removeAnsiEscapeCodes(joinedOutput)
        
        // Handle BLANK_AUDIO token - treat as empty to trigger silent exit
        if cleanedOutput.contains("[BLANK_AUDIO]") {
            return ""
        }
        
        return cleanedOutput
    }
    
    private func removeAnsiEscapeCodes(_ text: String) -> String {
        // Regular expression to match ANSI escape sequences
        let ansiRegex = try! NSRegularExpression(pattern: "\\x1B\\[[0-?]*[ -/]*[@-~]", options: [])
        let range = NSRange(location: 0, length: text.utf16.count)
        return ansiRegex.stringByReplacingMatches(in: text, options: [], range: range, withTemplate: "")
    }
    
    func getModelInfo(for modelType: WhisperModelType) -> WhisperModel? {
        return availableModels.first { $0.name == modelType.rawValue }
    }
    
    func isModelAvailable(_ modelType: WhisperModelType) -> Bool {
        return availableModels.contains { $0.name == modelType.rawValue }
    }
    
    func getRecommendedModel() -> WhisperModelType {
        // Recommend based on available models and system performance
        if isModelAvailable(.tiny) {
            return .tiny
        } else if isModelAvailable(.base) {
            return .base
        } else if isModelAvailable(.small) {
            return .small
        } else {
            return .tiny // Default fallback
        }
    }
}

// MARK: - WhisperModel
struct WhisperModel {
    let name: String
    let filename: String
    let path: String
    let size: String
    
    var displayName: String {
        switch name {
        case "tiny": return "Tiny (\(size))"
        case "base": return "Base (\(size))"
        case "small": return "Small (\(size))"
        case "medium": return "Medium (\(size))"
        case "large": return "Large (\(size))"
        default: return "\(name.capitalized) (\(size))"
        }
    }
}

// MARK: - WhisperError
enum WhisperError: Error, LocalizedError {
    case missingBinary
    case modelNotFound(String)
    case processError(String)
    case audioConversionError
    case unsupportedFormat
    
    var errorDescription: String? {
        switch self {
        case .missingBinary:
            return "Whisper binary not found in app bundle"
        case .modelNotFound(let model):
            return "Model '\(model)' not found"
        case .processError(let message):
            return "Whisper process error: \(message)"
        case .audioConversionError:
            return "Failed to convert audio to required format"
        case .unsupportedFormat:
            return "Unsupported audio format"
        }
    }
}

// MARK: - Audio Format Utilities
extension WhisperCppWrapper {
    func convertAudioForWhisper(_ audioData: Data) throws -> Data {
        // whisper.cpp expects 16kHz mono WAV files
        // The AudioManager should already provide this format
        return audioData
    }
    
    func validateAudioFormat(_ audioData: Data) -> Bool {
        // Basic validation - check if it's a valid WAV file
        guard audioData.count > 44 else { return false } // WAV header is 44 bytes
        
        // Check WAV header
        let header = audioData.prefix(4)
        return header.starts(with: "RIFF".data(using: .ascii) ?? Data())
    }
}