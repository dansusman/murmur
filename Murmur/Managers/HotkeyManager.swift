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
        setupEventHandler()
    }
    
    deinit {
        unregisterHotkey()
        if let eventHandler = eventHandler {
            RemoveEventHandler(eventHandler)
        }
    }
    
    private func setupEventHandler() {
        let eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyPressed))
        let eventTypeReleased = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: OSType(kEventHotKeyReleased))
        
        let eventTypes = [eventType, eventTypeReleased]
        
        InstallEventHandler(
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
    }
    
    private func handleHotkeyEvent(event: EventRef) -> OSStatus {
        guard event != nil else { return OSStatus(eventNotHandledErr) }
        
        let eventClass = GetEventClass(event)
        let eventKindValue = GetEventKind(event)
        
        if eventClass == OSType(kEventClassKeyboard) {
            if eventKindValue == OSType(kEventHotKeyPressed) && !isHotkeyPressed {
                isHotkeyPressed = true
                DispatchQueue.main.async {
                    self.delegate?.hotkeyPressed()
                }
            } else if eventKindValue == OSType(kEventHotKeyReleased) && isHotkeyPressed {
                isHotkeyPressed = false
                DispatchQueue.main.async {
                    self.delegate?.hotkeyReleased()
                }
            }
        }
        
        return noErr
    }
    
    func registerHotkey(keyCode: UInt32) {
        // Unregister previous hotkey
        unregisterHotkey()
        
        currentKeyCode = keyCode
        
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
            print("Failed to register hotkey with code: \(keyCode), status: \(status)")
        } else {
            print("Successfully registered hotkey with code: \(keyCode)")
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
