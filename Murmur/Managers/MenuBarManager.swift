import SwiftUI
import AppKit

class MenuBarManager: ObservableObject {
    private var statusItem: NSStatusItem?
    private var hotkeyManager: HotkeyManager?
    private var audioManager: AudioManager?
    private var whisperService: WhisperService?
    private var textInjector: TextInjector?
    private var settingsManager: SettingsManager?
    
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
        settingsManager = SettingsManager()
        audioManager = AudioManager()
        whisperService = WhisperService()
        textInjector = TextInjector()
        
        audioManager?.delegate = self
        whisperService?.delegate = self
    }
    
    private func setupHotkeys() {
        hotkeyManager = HotkeyManager()
        hotkeyManager?.delegate = self
        
        // Register default hotkey (FN key)
        hotkeyManager?.registerHotkey(keyCode: 63) // FN key
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
}

// MARK: - HotkeyManagerDelegate
extension MenuBarManager: HotkeyManagerDelegate {
    func hotkeyPressed() {
        startRecording()
    }
    
    func hotkeyReleased() {
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
        
        print("Audio recording failed: \(error.localizedDescription)")
    }
}

// MARK: - WhisperServiceDelegate
extension MenuBarManager: WhisperServiceDelegate {
    func whisperService(_ service: WhisperService, didTranscribe text: String) {
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
        
        print("Transcription failed: \(error.localizedDescription)")
    }
}

// MARK: - Recording Control
extension MenuBarManager {
    private func startRecording() {
        guard !isRecording && !isTranscribing else { return }
        audioManager?.startRecording()
    }
    
    private func stopRecording() {
        guard isRecording else { return }
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
