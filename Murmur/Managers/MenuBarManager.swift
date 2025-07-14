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
                Logger.menuBar.info("🔄 Hotkey changed to: \(keyCode)")
                self?.updateHotkey(keyCode: keyCode)
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
    }
    
    private func setupHotkeys() {
        Logger.menuBar.info("🔧 Setting up hotkeys")
        hotkeyManager = HotkeyManager()
        hotkeyManager?.delegate = self
        
        // Register hotkey from settings
        let keyCode = settingsManager?.hotkeyCode ?? 63
        Logger.menuBar.debug("Registering hotkey from settings: \(keyCode)")
        hotkeyManager?.registerHotkey(keyCode: keyCode)
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
    
    private func updateHotkey(keyCode: UInt32) {
        Logger.menuBar.info("🔄 Updating hotkey to: \(keyCode)")
        hotkeyManager?.updateHotkey(keyCode: keyCode)
    }
}

// MARK: - HotkeyManagerDelegate
extension MenuBarManager: HotkeyManagerDelegate {
    func hotkeyPressed() {
        Logger.menuBar.info("🔥 hotkeyPressed() called")
        startRecording()
    }
    
    func hotkeyReleased() {
        Logger.menuBar.info("🔥 hotkeyReleased() called")
        stopRecording()
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
        
        // Send audio to Whisper service
        whisperService?.transcribe(audioData: audioData)
    }
    
    func audioManager(_ manager: AudioManager, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isRecording = false
            self.isTranscribing = false
            self.updateMenuBarIcon()
        }
        
        Logger.menuBar.error("Audio recording failed: \(error.localizedDescription)")
    }
}

// MARK: - WhisperServiceDelegate
extension MenuBarManager: WhisperServiceDelegate {
    func whisperService(_ service: WhisperService, didTranscribe text: String) {
        Logger.menuBar.info("📝 About to inject transcribed text: \"\(text)\"")
        
        DispatchQueue.main.async {
            self.isTranscribing = false
            self.lastTranscription = text
            self.updateMenuBarIcon()
        }
        
        // Inject text into active application
        textInjector?.injectText(text)
    }
    
    func whisperService(_ service: WhisperService, didFailWithError error: Error) {
        DispatchQueue.main.async {
            self.isTranscribing = false
            self.updateMenuBarIcon()
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
        Logger.menuBar.debug("Calling audioManager.startRecording()")
        if settingsManager?.showFloatingIndicator == true {
            floatingIndicatorManager?.showRecordingIndicator()
        }
        audioManager?.startRecording()
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
}

// MARK: - Protocols
protocol HotkeyManagerDelegate: AnyObject {
    func hotkeyPressed()
    func hotkeyReleased()
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
