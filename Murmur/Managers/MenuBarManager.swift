import SwiftUI
import AppKit
import Combine

class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var hotkeyManager: HotkeyManager?
    private var audioManager: AudioManager?
    private var whisperService: WhisperService?
    private var textInjector: TextInjector?
    private var settingsManager: SettingsManager?
    private var floatingIndicatorManager: FloatingIndicatorManager?
    private var cancellables = Set<AnyCancellable>()
    
    @Published var isRecording = false
    @Published var isTranscribing = false
    @Published var lastTranscription = ""
    
    private var isMeetingModeRecording = false
    
    init() {
        setupServices()
        setupMenuBar()
        setupHotkeys()
    }
    
    private func setupMenuBar() {
        // Hide dock icon for menu bar only app
        NSApp.setActivationPolicy(.accessory)
        
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let statusButton = statusItem?.button {
            statusButton.image = NSImage(systemSymbolName: "mic", accessibilityDescription: "Murmur")
            statusButton.image?.size = NSSize(width: 16, height: 16)
        }
        
        updateMenuBarIcon()
        setupMenu()
    }
    
    private func setupServices() {
        settingsManager = SettingsManager.shared
        audioManager = AudioManager()
        whisperService = WhisperService()
        textInjector = TextInjector()
        floatingIndicatorManager = FloatingIndicatorManager()
        
        audioManager?.delegate = self
        whisperService?.delegate = self
        
        // Observe hotkey changes from settings
        settingsManager?.$hotkeyCode
            .sink { [weak self] keyCode in
                Logger.menuBar.info("🔄 Normal hotkey changed to: \(keyCode)")
                self?.updateNormalHotkey(keyCode: keyCode)
            }
            .store(in: &cancellables)
        
        // Observe meeting mode hotkey changes from settings
        settingsManager?.$meetingModeHotkeyCode
            .sink { [weak self] keyCode in
                Logger.menuBar.info("🔄 Meeting mode hotkey changed to: \(keyCode)")
                self?.updateMeetingModeHotkey(keyCode: keyCode)
            }
            .store(in: &cancellables)
        
        // Observe meeting mode changes from settings
        settingsManager?.$enableMeetingMode
            .sink { [weak self] enableMeetingMode in
                Logger.menuBar.info("🔄 Meeting mode changed to: \(enableMeetingMode)")
                self?.updateRecordingMode(enableMeetingMode: enableMeetingMode)
            }
            .store(in: &cancellables)
        
        // Request permissions if not already granted
        if let audioManager = audioManager, !audioManager.recordingPermissionGranted {
            AudioManager.requestMicrophonePermission()
            audioManager.pollMicrophonePermission()
        }
        
        if let textInjector = textInjector, !textInjector.hasAccessibilityPermission {
            TextInjector.requestAccessibilityPermission()
            textInjector.pollAccessibilityPermission()
        }
        
        // Screen recording permission will be handled by ScreenRecorder when needed

        // Set initial recording mode
        updateRecordingMode(enableMeetingMode: settingsManager?.enableMeetingMode ?? false)
    }
    
    private func setupHotkeys() {
        Logger.menuBar.info("🔧 Setting up hotkeys")
        hotkeyManager = HotkeyManager()
        hotkeyManager?.delegate = self
        
        // Register normal hotkey from settings
        let normalKeyCode = settingsManager?.hotkeyCode ?? 63
        Logger.menuBar.debug("Registering normal hotkey from settings: \(normalKeyCode)")
        hotkeyManager?.registerNormalHotkey(keyCode: normalKeyCode)
        
        // Register meeting mode hotkey from settings
        let meetingModeKeyCode = settingsManager?.meetingModeHotkeyCode ?? 64
        Logger.menuBar.debug("Registering meeting mode hotkey from settings: \(meetingModeKeyCode)")
        hotkeyManager?.registerMeetingModeHotkey(keyCode: meetingModeKeyCode)
    }
    
    private func setupMenu() {
        let menu = NSMenu()
        
        // Recording status
        let statusItem = NSMenuItem(title: "Ready", action: nil, keyEquivalent: "")
        statusItem.isEnabled = false
        menu.addItem(statusItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Settings
        let settingsItem = NSMenuItem(title: "Settings...", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)
        
        // Launch at login
        let launchAtLoginItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchAtLoginItem.target = self
        launchAtLoginItem.state = settingsManager?.launchAtLogin == true ? .on : .off
        menu.addItem(launchAtLoginItem)
        
        menu.addItem(NSMenuItem.separator())
        
        // Quit
        let quitItem = NSMenuItem(title: "Quit Murmur", action: #selector(quitApp), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
        
        self.statusItem?.menu = menu
    }
    
    private func updateMenuBarIcon() {
        DispatchQueue.main.async { [weak self] in
            guard let self, let statusButton = self.statusItem?.button else { return }
            
            let iconName: String
            if self.isRecording {
                iconName = "mic.fill"
            } else if self.isTranscribing {
                iconName = "waveform"
            } else {
                iconName = "mic"
            }
            
            statusButton.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "Murmur")
            statusButton.image?.size = NSSize(width: 16, height: 16)
        }
    }
    
    @objc private func openSettings() {
        NSApp.activate(ignoringOtherApps: true)
        
        // For SwiftUI apps, we need to use the main menu or key equivalent
        // Try the standard Settings menu shortcut
        let event = NSEvent.keyEvent(with: .keyDown, 
                                   location: NSZeroPoint, 
                                   modifierFlags: .command, 
                                   timestamp: 0, 
                                   windowNumber: 0, 
                                   context: nil, 
                                   characters: ",", 
                                   charactersIgnoringModifiers: ",", 
                                   isARepeat: false, 
                                   keyCode: 43)
        
        if let keyEvent = event {
            NSApp.sendEvent(keyEvent)
        }
    }
    
    @objc private func toggleLaunchAtLogin() {
        settingsManager?.launchAtLogin.toggle()
        setupMenu() // Refresh menu
    }
    
    @objc private func quitApp() {
        NSApp.terminate(nil)
    }
    
    private func updateNormalHotkey(keyCode: UInt32) {
        Logger.menuBar.info("🔄 Updating normal hotkey to: \(keyCode)")
        hotkeyManager?.updateNormalHotkey(keyCode: keyCode)
    }
    
    private func updateMeetingModeHotkey(keyCode: UInt32) {
        Logger.menuBar.info("🔄 Updating meeting mode hotkey to: \(keyCode)")
        hotkeyManager?.updateMeetingModeHotkey(keyCode: keyCode)
    }
    
    private func updateRecordingMode(enableMeetingMode: Bool) {
        Logger.menuBar.info("🔄 Updating recording mode - meeting mode: \(enableMeetingMode)")
        
        let recordingMode: RecordingMode = enableMeetingMode ? .meetingMode : .microphoneOnly
        audioManager?.recordingMode = recordingMode
        
        // Screen recording permission will be handled by ScreenRecorder when meeting mode is used
        
        Logger.menuBar.info("✅ Recording mode preference updated to: \(recordingMode) (actual mode determined per hotkey)")
    }
}

// MARK: - HotkeyManagerDelegate
extension MenuBarManager: HotkeyManagerDelegate {
    func normalHotkeyPressed() {
        Logger.menuBar.info("🔥 normalHotkeyPressed() called")
        startRecording()
    }
    
    func normalHotkeyReleased() {
        Logger.menuBar.info("🔥 normalHotkeyReleased() called")
        stopRecording()
    }
    
    func meetingModeHotkeyStartRecording() {
        Logger.menuBar.info("🔥 meetingModeHotkeyStartRecording() called")
        startMeetingModeRecording()
    }
    
    func meetingModeHotkeyStopRecording() {
        Logger.menuBar.info("🔥 meetingModeHotkeyStopRecording() called")
        stopMeetingModeRecording()
    }
}

// MARK: - AudioManagerDelegate
extension MenuBarManager: AudioManagerDelegate {
    func audioManager(_ manager: AudioManager, didStartRecording: Bool) {
        DispatchQueue.main.async {
            self.isRecording = didStartRecording
            self.updateMenuBarIcon()
        }
    }
    
    func audioManager(_ manager: AudioManager, didFinishRecording audioData: Data) {
        DispatchQueue.main.async {
            self.isRecording = false
            self.isTranscribing = true
            self.updateMenuBarIcon()
        }
        
        // Send audio to Whisper service - include timestamps for meeting mode
        Logger.menuBar.info("Transcribing with isMeetingModeRecording: \(isMeetingModeRecording)")
        whisperService?.transcribe(audioData: audioData, includeTimestamps: isMeetingModeRecording)
    }
    
    func audioManager(_ manager: AudioManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isRecording = false
            self.isTranscribing = false
            self.updateMenuBarIcon()
            
            // Hide floating indicator on error
            if self.settingsManager?.showFloatingIndicator == true {
                self.floatingIndicatorManager?.hideRecordingIndicator()
            }
        }
        
        Logger.menuBar.error("Audio recording failed: \(error.localizedDescription)")
    }
}

// MARK: - WhisperServiceDelegate
extension MenuBarManager: WhisperServiceDelegate {
    func whisperService(_ service: WhisperService, didTranscribe text: String) {
        Logger.menuBar.info("📝 Transcribed text: \"\(text)\"")
        
        DispatchQueue.main.async {
            self.isTranscribing = false
            self.lastTranscription = text
            self.updateMenuBarIcon()
        }
        
        if isMeetingModeRecording {
            // Save to file for meeting mode
            saveMeetingTranscript(text)
            // Reset meeting mode flag
            isMeetingModeRecording = false
        } else {
            // Inject text into active application for normal mode
            Logger.menuBar.info("📝 About to inject transcribed text: \"\(text)\"")
            textInjector?.injectText(text)
        }
    }
    
    func whisperService(_ service: WhisperService, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isTranscribing = false
            self.updateMenuBarIcon()
            
            // Hide floating indicator on transcription error
            if self.settingsManager?.showFloatingIndicator == true {
                self.floatingIndicatorManager?.hideRecordingIndicator()
            }
        }
        
        // Reset meeting mode flag if it was set
        if isMeetingModeRecording {
            isMeetingModeRecording = false
        }
        
        Logger.menuBar.error("Transcription failed: \(error.localizedDescription)")
    }
}

// MARK: - Recording Control
extension MenuBarManager {
    private func startRecording() {
        Logger.menuBar.info("🎤 startRecording() called - isRecording: \(isRecording), isTranscribing: \(isTranscribing)")
        guard !isRecording && !isTranscribing else { 
            Logger.menuBar.warning("startRecording() blocked - already recording or transcribing")
            return 
        }
        Logger.menuBar.debug("Calling audioManager.startRecording() with microphoneOnly mode")
        if settingsManager?.showFloatingIndicator == true {
            floatingIndicatorManager?.showRecordingIndicator()
        }
        audioManager?.startRecording(mode: .microphoneOnly)
    }
    
    private func stopRecording() {
        Logger.menuBar.info("🛑 stopRecording() called - isRecording: \(isRecording)")
        guard isRecording else { 
            Logger.menuBar.warning("stopRecording() blocked - not currently recording")
            return 
        }
        Logger.menuBar.debug("Calling audioManager.stopRecording()")
        if settingsManager?.showFloatingIndicator == true {
            floatingIndicatorManager?.hideRecordingIndicator()
        }
        audioManager?.stopRecording()
    }
    
    private func startMeetingModeRecording() {
        Logger.menuBar.info("🎤 startMeetingModeRecording() called - isRecording: \(isRecording), isTranscribing: \(isTranscribing)")
        guard !isRecording && !isTranscribing else { 
            Logger.menuBar.warning("startMeetingModeRecording() blocked - already recording or transcribing")
            return 
        }
        
        // Set meeting mode flag
        isMeetingModeRecording = true
        
        Logger.menuBar.debug("Calling audioManager.startRecording() with meetingMode mode")
        if settingsManager?.showFloatingIndicator == true {
            floatingIndicatorManager?.showRecordingIndicator()
        }
        audioManager?.startRecording(mode: .meetingMode)
    }
    
    private func stopMeetingModeRecording() {
        Logger.menuBar.info("🛑 stopMeetingModeRecording() called - isRecording: \(isRecording)")
        guard isRecording else { 
            Logger.menuBar.warning("stopMeetingModeRecording() blocked - not currently recording")
            return 
        }
        Logger.menuBar.debug("Calling audioManager.stopRecording()")
        if settingsManager?.showFloatingIndicator == true {
            floatingIndicatorManager?.hideRecordingIndicator()
        }
        audioManager?.stopRecording()
    }
    
    private func saveMeetingTranscript(_ text: String) {
        guard !text.isEmpty else {
            Logger.menuBar.warning("Not saving empty transcript")
            return
        }
        
        // Create logs directory if it doesn't exist
        let homeDirectory = FileManager.default.homeDirectoryForCurrentUser
        let logsDirectory = homeDirectory.appendingPathComponent(".murmur_logs")
        
        do {
            try FileManager.default.createDirectory(at: logsDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            Logger.menuBar.error("Failed to create logs directory: \(error)")
            return
        }
        
        // Create filename with date and timestamp
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let filename = "log_\(timestamp)_transcript.txt"
        let fileURL = logsDirectory.appendingPathComponent(filename)
        
        do {
            try text.write(to: fileURL, atomically: true, encoding: .utf8)
            Logger.menuBar.info("✅ Meeting transcript saved to: \(fileURL.path)")
        } catch {
            Logger.menuBar.error("Failed to save transcript: \(error)")
        }
    }
}

// MARK: - Protocols
protocol HotkeyManagerDelegate: AnyObject {
    func normalHotkeyPressed()
    func normalHotkeyReleased()
    func meetingModeHotkeyStartRecording()
    func meetingModeHotkeyStopRecording()
}

protocol AudioManagerDelegate: AnyObject {
    func audioManager(_ manager: AudioManager, didStartRecording: Bool)
    func audioManager(_ manager: AudioManager, didFinishRecording audioData: Data)
    func audioManager(_ manager: AudioManager, didFailWithError error: Error)
}

protocol WhisperServiceDelegate: AnyObject {
    func whisperService(_ service: WhisperService, didTranscribe text: String)
    func whisperService(_ service: WhisperService, didFailWithError error: Error)
}
