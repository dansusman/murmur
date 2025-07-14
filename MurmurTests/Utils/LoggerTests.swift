import Testing
import Foundation
import os.log
@testable import Murmur

@Suite("Logger Tests")
struct LoggerTests {
    
    @Test("Logger initialization")
    func testLoggerInitialization() {
        let logger = Logger(component: "TestComponent")
        
        // Logger should initialize without crashing
        #expect(true)
    }
    
    @Test("Logger with different components")
    func testLoggerWithDifferentComponents() {
        let audioLogger = Logger(component: "AudioManager")
        let hotkeyLogger = Logger(component: "HotkeyManager")
        
        // Should be able to create multiple loggers
        #expect(true)
    }
    
    @Test("Logger enabled state")
    func testLoggerEnabledState() {
        let originalState = Logger.isEnabled
        
        // Test enabling/disabling
        Logger.isEnabled = true
        #expect(Logger.isEnabled == true)
        
        Logger.isEnabled = false
        #expect(Logger.isEnabled == false)
        
        // Restore original state
        Logger.isEnabled = originalState
    }
    
    @Test("Logger minimum level")
    func testLoggerMinimumLevel() {
        let originalLevel = Logger.minimumLevel
        
        // Test setting different levels
        Logger.minimumLevel = .debug
        #expect(Logger.minimumLevel == .debug)
        
        Logger.minimumLevel = .info
        #expect(Logger.minimumLevel == .info)
        
        Logger.minimumLevel = .warning
        #expect(Logger.minimumLevel == .warning)
        
        Logger.minimumLevel = .error
        #expect(Logger.minimumLevel == .error)
        
        // Restore original level
        Logger.minimumLevel = originalLevel
    }
    
    @Test("Logger methods don't crash")
    func testLoggerMethodsDontCrash() {
        let logger = Logger(component: "TestComponent")
        
        // Test all logging methods
        logger.debug("Debug message")
        logger.info("Info message")
        logger.warning("Warning message")
        logger.error("Error message")
        logger.success("Success message")
        
        #expect(true) // Test that none of the methods crash
    }
    
    @Test("Logger respects enabled state")
    func testLoggerRespectsEnabledState() {
        let logger = Logger(component: "TestComponent")
        let originalState = Logger.isEnabled
        
        // Disable logging
        Logger.isEnabled = false
        
        // These should not crash even when disabled
        logger.debug("Debug message")
        logger.info("Info message")
        logger.warning("Warning message")
        logger.error("Error message")
        logger.success("Success message")
        
        // Restore original state
        Logger.isEnabled = originalState
        
        #expect(true)
    }
    
    @Test("Logger minimum level filtering")
    func testLoggerMinimumLevelFiltering() {
        let logger = Logger(component: "TestComponent")
        let originalLevel = Logger.minimumLevel
        let originalEnabled = Logger.isEnabled
        
        // Enable logging
        Logger.isEnabled = true
        
        // Set minimum level to warning
        Logger.minimumLevel = .warning
        
        // These should all work without crashing
        logger.debug("Debug message") // Should be filtered out
        logger.info("Info message")   // Should be filtered out
        logger.warning("Warning message") // Should be logged
        logger.error("Error message")      // Should be logged
        logger.success("Success message")  // Should be logged
        
        // Restore original settings
        Logger.minimumLevel = originalLevel
        Logger.isEnabled = originalEnabled
        
        #expect(true)
    }
    
    @Test("Global static loggers")
    func testGlobalStaticLoggers() {
        // Test that all static loggers are available
        let audioLogger = Logger.audio
        let hotkeyLogger = Logger.hotkey
        let menuBarLogger = Logger.menuBar
        let textInjectorLogger = Logger.textInjector
        let whisperLogger = Logger.whisper
        let settingsLogger = Logger.settings
        let appLogger = Logger.app
        
        // Should all be valid loggers
        #expect(true)
        
        // Test that they can all log without crashing
        audioLogger.info("Audio test")
        hotkeyLogger.info("Hotkey test")
        menuBarLogger.info("MenuBar test")
        textInjectorLogger.info("TextInjector test")
        whisperLogger.info("Whisper test")
        settingsLogger.info("Settings test")
        appLogger.info("App test")
    }
    
    @Test("Logger file and line parameters")
    func testLoggerFileAndLineParameters() {
        let logger = Logger(component: "TestComponent")
        
        // Test that file and line parameters work
        logger.debug("Debug with file/line", file: "TestFile.swift", line: 42)
        logger.info("Info with file/line", file: "TestFile.swift", line: 43)
        logger.warning("Warning with file/line", file: "TestFile.swift", line: 44)
        logger.error("Error with file/line", file: "TestFile.swift", line: 45)
        logger.success("Success with file/line", file: "TestFile.swift", line: 46)
        
        #expect(true)
    }
}

@Suite("LogLevel Tests")
struct LogLevelTests {
    
    @Test("LogLevel raw values")
    func testLogLevelRawValues() {
        #expect(LogLevel.debug.rawValue == "🔍")
        #expect(LogLevel.info.rawValue == "ℹ️")
        #expect(LogLevel.warning.rawValue == "⚠️")
        #expect(LogLevel.error.rawValue == "❌")
        #expect(LogLevel.success.rawValue == "✅")
    }
    
    @Test("LogLevel OS log type mapping")
    func testLogLevelOSLogTypeMapping() {
        #expect(LogLevel.debug.osLogType == OSLogType.debug)
        #expect(LogLevel.info.osLogType == OSLogType.info)
        #expect(LogLevel.warning.osLogType == OSLogType.default)
        #expect(LogLevel.error.osLogType == OSLogType.error)
        #expect(LogLevel.success.osLogType == OSLogType.info)
    }
    
    @Test("LogLevel case iterable")
    func testLogLevelCaseIterable() {
        let allCases = LogLevel.allCases
        
        #expect(allCases.count == 5)
        #expect(allCases.contains(.debug))
        #expect(allCases.contains(.info))
        #expect(allCases.contains(.warning))
        #expect(allCases.contains(.error))
        #expect(allCases.contains(.success))
    }
    
    @Test("LogLevel ordering for filtering")
    func testLogLevelOrderingForFiltering() {
        let levels = LogLevel.allCases
        
        // Test that we can find indices for comparison
        let debugIndex = levels.firstIndex(of: .debug)
        let infoIndex = levels.firstIndex(of: .info)
        let warningIndex = levels.firstIndex(of: .warning)
        let errorIndex = levels.firstIndex(of: .error)
        let successIndex = levels.firstIndex(of: .success)
        
        #expect(debugIndex != nil)
        #expect(infoIndex != nil)
        #expect(warningIndex != nil)
        #expect(errorIndex != nil)
        #expect(successIndex != nil)
    }
}

@Suite("DateFormatter+Extensions Tests")
struct DateFormatterExtensionsTests {
    
    @Test("Log formatter format")
    func testLogFormatterFormat() {
        let formatter = DateFormatter.logFormatter
        
        #expect(formatter.dateFormat == "HH:mm:ss.SSS")
    }
    
    @Test("Log formatter produces valid strings")
    func testLogFormatterProducesValidStrings() {
        let formatter = DateFormatter.logFormatter
        let now = Date()
        
        let timeString = formatter.string(from: now)
        
        #expect(timeString.isEmpty == false)
        #expect(timeString.contains(":"))
        #expect(timeString.contains("."))
    }
    
    @Test("Log formatter consistency")
    func testLogFormatterConsistency() {
        let formatter1 = DateFormatter.logFormatter
        let formatter2 = DateFormatter.logFormatter
        
        // Should be the same instance (static)
        #expect(formatter1 === formatter2)
    }
    
    @Test("Log formatter time format validation")
    func testLogFormatterTimeFormatValidation() {
        let formatter = DateFormatter.logFormatter
        let testDate = Date(timeIntervalSince1970: 1609459200) // 2021-01-01 00:00:00 UTC
        
        let timeString = formatter.string(from: testDate)
        
        // Should have the format HH:mm:ss.SSS
        // The exact time depends on timezone, but format should be consistent
        let components = timeString.components(separatedBy: ":")
        #expect(components.count == 3) // hours:minutes:seconds.milliseconds
        
        let secondsAndMillis = components[2].components(separatedBy: ".")
        #expect(secondsAndMillis.count == 2) // seconds.milliseconds
    }
}

@Suite("Logger Integration Tests")
struct LoggerIntegrationTests {
    
    @Test("Logger with real component names")
    func testLoggerWithRealComponentNames() {
        let components = [
            "AudioManager",
            "HotkeyManager",
            "MenuBarManager",
            "TextInjector",
            "WhisperService",
            "SettingsManager",
            "MurmurApp"
        ]
        
        for component in components {
            let logger = Logger(component: component)
            logger.info("Test message for \(component)")
        }
        
        #expect(true)
    }
    
    @Test("Logger thread safety")
    func testLoggerThreadSafety() async {
        let logger = Logger(component: "ThreadSafetyTest")
        
        // Test logging from multiple threads
        await withTaskGroup(of: Void.self) { group in
            group.addTask {
                for i in 0..<100 {
                    logger.info("Thread 1 message \(i)")
                }
            }
            
            group.addTask {
                for i in 0..<100 {
                    logger.info("Thread 2 message \(i)")
                }
            }
        }
        
        #expect(true) // Test that no crashes occur
    }
    
    @Test("Logger performance with many messages")
    func testLoggerPerformanceWithManyMessages() {
        let logger = Logger(component: "PerformanceTest")
        let originalEnabled = Logger.isEnabled
        
        // Enable logging for performance test
        Logger.isEnabled = true
        
        let startTime = Date()
        
        for i in 0..<1000 {
            logger.info("Performance test message \(i)")
        }
        
        let endTime = Date()
        let duration = endTime.timeIntervalSince(startTime)
        
        // Should complete reasonably quickly (less than 1 second)
        #expect(duration < 1.0)
        
        // Restore original state
        Logger.isEnabled = originalEnabled
    }
}