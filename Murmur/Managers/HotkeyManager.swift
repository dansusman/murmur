import Foundation
import Carbon
import AppKit

class HotkeyManager: ObservableObject {
    weak var delegate: HotkeyManagerDelegate?
    
    private var normalHotKeyRef: EventHotKeyRef?
    private var meetingModeHotKeyRef: EventHotKeyRef?
    private var eventHandler: EventHandlerRef?
    private var currentNormalKeyCode: UInt32 = 63 // FN key default
    private var currentMeetingModeKeyCode: UInt32 = 64 // F17 key default
    private var isNormalHotkeyPressed = false
    private var isMeetingModeRecording = false
    
    init() {
        Logger.hotkey.info("🚀 Initializing HotkeyManager")
        setupEventHandler()
    }
    
    deinit {
        unregisterAllHotkeys()
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
        let eventClass = GetEventClass(event)
        let eventKindValue = GetEventKind(event)
        
        // Get the hotkey ID to determine which hotkey was triggered
        var hotKeyID = EventHotKeyID()
        let getIDResult = GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil, MemoryLayout<EventHotKeyID>.size, nil, &hotKeyID)
        
        Logger.hotkey.debug("handleHotkeyEvent: eventClass=\(eventClass), eventKind=\(eventKindValue), hotKeyID=\(hotKeyID.id)")
        
        if eventClass == OSType(kEventClassKeyboard) && getIDResult == noErr {
            if hotKeyID.id == 1 { // Normal hotkey
                handleNormalHotkeyEvent(eventKind: eventKindValue)
            } else if hotKeyID.id == 2 { // Meeting mode hotkey
                handleMeetingModeHotkeyEvent(eventKind: eventKindValue)
            }
        } else {
            Logger.hotkey.debug("Event ignored - not keyboard event or failed to get hotkey ID")
        }
        
        return noErr
    }
    
    private func handleNormalHotkeyEvent(eventKind: UInt32) {
        if eventKind == OSType(kEventHotKeyPressed) && !isNormalHotkeyPressed {
            isNormalHotkeyPressed = true
            let keyName = Self.getKeyName(for: currentNormalKeyCode) ?? "Unknown"
            Logger.hotkey.info("🔥 Normal hotkey pressed: \(keyName) (code: \(currentNormalKeyCode))")
            DispatchQueue.main.async {
                self.delegate?.normalHotkeyPressed()
            }
        } else if eventKind == OSType(kEventHotKeyReleased) && isNormalHotkeyPressed {
            isNormalHotkeyPressed = false
            let keyName = Self.getKeyName(for: currentNormalKeyCode) ?? "Unknown"
            Logger.hotkey.info("🔥 Normal hotkey released: \(keyName) (code: \(currentNormalKeyCode))")
            DispatchQueue.main.async {
                self.delegate?.normalHotkeyReleased()
            }
        }
    }
    
    private func handleMeetingModeHotkeyEvent(eventKind: UInt32) {
        if eventKind == OSType(kEventHotKeyPressed) {
            let keyName = Self.getKeyName(for: currentMeetingModeKeyCode) ?? "Unknown"
            Logger.hotkey.info("🔥 Meeting mode hotkey pressed: \(keyName) (code: \(currentMeetingModeKeyCode))")
            
            // Toggle meeting mode recording
            isMeetingModeRecording.toggle()
            
            DispatchQueue.main.async {
                if self.isMeetingModeRecording {
                    self.delegate?.meetingModeHotkeyStartRecording()
                } else {
                    self.delegate?.meetingModeHotkeyStopRecording()
                }
            }
        }
    }
    
    func registerNormalHotkey(keyCode: UInt32) {
        // Unregister previous normal hotkey
        unregisterNormalHotkey()
        
        currentNormalKeyCode = keyCode
        let keyName = Self.getKeyName(for: keyCode) ?? "Unknown"
        
        Logger.hotkey.info("🔧 Registering normal hotkey: \(keyName) (code: \(keyCode))")
        
        let hotKeyID = EventHotKeyID(signature: OSType(0x4D554D52), id: UInt32(1)) // 'MUMR' ID 1
        
        let status = RegisterEventHotKey(
            currentNormalKeyCode,
            0, // No modifiers needed
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &normalHotKeyRef
        )
        
        if status != noErr {
            Logger.hotkey.error("Failed to register normal hotkey \(keyName) (code: \(keyCode)), status: \(status)")
        } else {
            Logger.hotkey.success("Successfully registered normal hotkey \(keyName) (code: \(keyCode))")
        }
    }
    
    func registerMeetingModeHotkey(keyCode: UInt32) {
        // Unregister previous meeting mode hotkey
        unregisterMeetingModeHotkey()
        
        currentMeetingModeKeyCode = keyCode
        let keyName = Self.getKeyName(for: keyCode) ?? "Unknown"
        
        Logger.hotkey.info("🔧 Registering meeting mode hotkey: \(keyName) (code: \(keyCode))")
        
        let hotKeyID = EventHotKeyID(signature: OSType(0x4D554D52), id: UInt32(2)) // 'MUMR' ID 2
        
        let status = RegisterEventHotKey(
            currentMeetingModeKeyCode,
            0, // No modifiers needed
            hotKeyID,
            GetEventDispatcherTarget(),
            0,
            &meetingModeHotKeyRef
        )
        
        if status != noErr {
            Logger.hotkey.error("Failed to register meeting mode hotkey \(keyName) (code: \(keyCode)), status: \(status)")
        } else {
            Logger.hotkey.success("Successfully registered meeting mode hotkey \(keyName) (code: \(keyCode))")
        }
    }
    
    private func unregisterNormalHotkey() {
        if let normalHotKeyRef = normalHotKeyRef {
            UnregisterEventHotKey(normalHotKeyRef)
            self.normalHotKeyRef = nil
        }
    }
    
    private func unregisterMeetingModeHotkey() {
        if let meetingModeHotKeyRef = meetingModeHotKeyRef {
            UnregisterEventHotKey(meetingModeHotKeyRef)
            self.meetingModeHotKeyRef = nil
        }
    }
    
    private func unregisterAllHotkeys() {
        unregisterNormalHotkey()
        unregisterMeetingModeHotkey()
    }
    
    func updateNormalHotkey(keyCode: UInt32) {
        registerNormalHotkey(keyCode: keyCode)
    }
    
    func updateMeetingModeHotkey(keyCode: UInt32) {
        registerMeetingModeHotkey(keyCode: keyCode)
    }
    
    func resetMeetingModeRecordingState() {
        isMeetingModeRecording = false
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
