import Foundation
@testable import Murmur

class MockHotkeyManager: HotkeyManager {
    var shouldFailRegistration = false
    var registeredKeyCode: UInt32?
    var registrationCallCount = 0
    var unregistrationCallCount = 0
    
    override init() {
        super.init()
    }
    
    override func registerHotkey(keyCode: UInt32) {
        registrationCallCount += 1
        
        if shouldFailRegistration {
            // In a real implementation, this would trigger an error callback
            return
        }
        
        registeredKeyCode = keyCode
        // Don't call super to avoid actual Carbon framework calls
    }
    
    override func updateHotkey(keyCode: UInt32) {
        unregistrationCallCount += 1
        registrationCallCount += 1
        
        if !shouldFailRegistration {
            registeredKeyCode = keyCode
        }
    }
    
    func simulateHotkeyPressed() {
        delegate?.hotkeyPressed()
    }
    
    func simulateHotkeyReleased() {
        delegate?.hotkeyReleased()
    }
    
    func simulateRegistrationFailure() {
        shouldFailRegistration = true
    }
    
    func simulateRegistrationSuccess() {
        shouldFailRegistration = false
    }
    
    func getRegisteredKeyCode() -> UInt32? {
        return registeredKeyCode
    }
    
    func getRegistrationCallCount() -> Int {
        return registrationCallCount
    }
    
    func getUnregistrationCallCount() -> Int {
        return unregistrationCallCount
    }
    
    func reset() {
        shouldFailRegistration = false
        registeredKeyCode = nil
        registrationCallCount = 0
        unregistrationCallCount = 0
    }
}