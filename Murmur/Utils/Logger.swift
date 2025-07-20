import Foundation
import os.log

enum LogLevel: String, CaseIterable {
    case debug = "🔍"
    case info = "ℹ️"
    case warning = "⚠️"
    case error = "❌"
    case success = "✅"
    
    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        case .success: return .info
        }
    }
}

class Logger {
    private let subsystem = Bundle.main.bundleIdentifier ?? "com.murmur"
    private let component: String
    private let osLog: OSLog
    
    static var isEnabled: Bool = true
    static var minimumLevel: LogLevel = .info
    
    init(component: String) {
        self.component = component
        self.osLog = OSLog(subsystem: subsystem, category: component)
    }
    
    private func shouldLog(_ level: LogLevel) -> Bool {
        guard Logger.isEnabled else { return false }
        
        let levels = LogLevel.allCases
        guard let currentIndex = levels.firstIndex(of: Logger.minimumLevel),
              let messageIndex = levels.firstIndex(of: level) else { return true }
        
        return messageIndex >= currentIndex
    }
    

    private func log(_ level: LogLevel, _ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        guard shouldLog(level) else { return }
        
        let timestamp = DateFormatter.logFormatter.string(from: Date())
        let fileName = URL(fileURLWithPath: file).lastPathComponent
        let logMessage = "[\(component)] \(level.rawValue) \(fileName):\(line) \(message)"
        
        os_log("%{public}@", log: osLog, type: level.osLogType, logMessage)
#if DEBUG
        print("\(timestamp) \(logMessage)")
#endif
    }
    
    func debug(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.debug, message, file: file, function: function, line: line)
    }
    
    func info(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.info, message, file: file, function: function, line: line)
    }
    
    func warning(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.warning, message, file: file, function: function, line: line)
    }
    
    func error(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.error, message, file: file, function: function, line: line)
    }
    
    func success(_ message: String, file: String = #file, function: String = #function, line: Int = #line) {
        log(.success, message, file: file, function: function, line: line)
    }
}

extension DateFormatter {
    static let logFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter
    }()
}

// MARK: - Global Static Loggers
extension Logger {
    static let audio = Logger(component: "AudioManager")
    static let hotkey = Logger(component: "HotkeyManager")
    static let menuBar = Logger(component: "MenuBarManager")
    static let textInjector = Logger(component: "TextInjector")
    static let whisper = Logger(component: "WhisperService")
    static let settings = Logger(component: "SettingsManager")
    static let screenCapture = Logger(component: "ScreenCapture")
    static let app = Logger(component: "MurmurApp")
}
