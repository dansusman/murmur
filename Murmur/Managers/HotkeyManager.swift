import Foundation
import Carbon
import AppKit

class HotkeyManager: ObservableObject {
    weak var delegate: HotkeyManagerDelegate?
    
    private var hotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var currentKeyCode: UInt32 = 63 // FN key default
    private var isHotkeyPressed = false
    
    init() {
        Logger.hotkey.info("🚀 Initializing HotkeyManager")
        setupEventHandler()
    }
    
    deinit {
        unregisterHotkey()
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
    
    private func setupEventHandler() {
        Logger.hotkey.info("🔧 Setting up event handler")
        let eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        let eventTypeReleased = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyReleased))
        
        let eventTypes = [eventType, eventTypeReleased]
        
        let result = InstallEventHandler(
            GetEventDispatcherTarget(),
            { (nextHandler, event, userData) -> OSStatus in
                guard let userData, let event else { return OSStatus(eventNotHandledErr) }
                let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
                return manager.handleHotkeyEvent(event: event)
            },
            2,
            eventTypes,
            UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            &eventHandler
        )
        
        if result != noErr {
            Logger.hotkey.error("Failed to install event handler, status: \(result)")
        } else {
            Logger.hotkey.success("Event handler installed successfully")
        }
    }
    
    private func handleHotkeyEvent(event: EventRef) -> OSStatus {
        guard event != nil else { 
            Logger.hotkey.warning("handleHotkeyEvent: event is nil")
            return OSStatus(eventNotHandledErr) 
        }
        
        let eventClass = GetEventClass(event)
        let eventKindValue = GetEventKind(event)
        
        Logger.hotkey.debug("handleHotkeyEvent: eventClass=\(eventClass), eventKind=\(eventKindValue)")
        
        if eventClass == OSType(kEventClassKeyboard) {
            if eventKindValue == OSType(kEventHotKeyPressed) && !isHotkeyPressed {
                isHotkeyPressed = true
                let keyName = Self.getKeyName(for: currentKeyCode) ?? "Unknown"
                Logger.hotkey.info("🔥 Hotkey pressed: \(keyName) (code: \(currentKeyCode))")
                Logger.hotkey.debug("Calling delegate.hotkeyPressed()")
                DispatchQueue.main.async {
                    self.delegate?.hotkeyPressed()
                }
            } else if eventKindValue == OSType(kEventHotKeyReleased) && isHotkeyPressed {
                isHotkeyPressed = false
                let keyName = Self.getKeyName(for: currentKeyCode) ?? "Unknown"
                Logger.hotkey.info("🔥 Hotkey released: \(keyName) (code: \(currentKeyCode))")
                Logger.hotkey.debug("Calling delegate.hotkeyReleased()")
                DispatchQueue.main.async {
                    self.delegate?.hotkeyReleased()
                }
            } else {
                Logger.hotkey.debug("Event ignored - eventKind=\(eventKindValue), isHotkeyPressed=\(isHotkeyPressed)")
            }
        } else {
            Logger.hotkey.debug("Event ignored - not keyboard event (eventClass=\(eventClass))")
        }
        
        return noErr
    }
    
    func registerHotkey(keyCode: UInt32) {
        // Unregister previous hotkey
        unregisterHotkey()
        
        currentKeyCode = keyCode
        let keyName = Self.getKeyName(for: keyCode) ?? "Unknown"
        
        Logger.hotkey.info("🔧 Registering hotkey: \(keyName) (code: \(keyCode))")
        
        // Register new hotkey
        let hotKeyID = EventHotKeyID(signature: OSType(0x4D554D52), id: UInt32(1)) // 'MUMR'
        
        let status = RegisterEventHotKey(
            currentKeyCode,
            0, // No modifiers needed for FN key
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &hotKeyRef
        )
        
        if status != noErr {
            Logger.hotkey.error("Failed to register hotkey \(keyName) (code: \(keyCode)), status: \(status)")
        } else {
            Logger.hotkey.success("Successfully registered hotkey \(keyName) (code: \(keyCode))")
        }
    }
    
    private func unregisterHotkey() {
        if let hotKeyRef = hotKeyRef {
            UnregisterEventHotKey(hotKeyRef)
            self.hotKeyRef = nil
        }
    }
    
    func updateHotkey(keyCode: UInt32) {
        registerHotkey(keyCode: keyCode)
    }
    
    // Helper method to get key code from key event
    static func getKeyCode(from event: NSEvent) -> UInt32? {
        return UInt32(event.keyCode)
    }
}

// MARK: - Key Code Constants
extension HotkeyManager {
    static let keyCodeMap: [String: UInt32] = [
        "F1": 122,
        "F2": 120,
        "F3": 99,
        "F4": 118,
        "F5": 96,
        "F6": 97,
        "F7": 98,
        "F8": 100,
        "F9": 101,
        "F10": 109,
        "F11": 103,
        "F12": 111,
        "F13": 105,
        "F14": 107,
        "F15": 113,
        "F16": 106,
        "F17": 64,
        "F18": 79,
        "F19": 80,
        "F20": 90,
        "FN": 63,
        "Command": 55,
        "Option": 58,
        "Control": 59,
        "Shift": 56,
        "Space": 49,
        "Tab": 48,
        "Return": 36,
        "Delete": 51,
        "Escape": 53
    ]
    
    static func getKeyName(for keyCode: UInt32) -> String? {
        return keyCodeMap.first(where: { $0.value == keyCode })?.key
    }
}
