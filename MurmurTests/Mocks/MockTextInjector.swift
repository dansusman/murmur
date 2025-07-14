import Foundation
@testable import Murmur

class MockTextInjector: TextInjector {
    var shouldFailInjection = false
    var shouldFailPermission = false
    var injectedText: String?
    var injectionCallCount = 0
    var permissionCheckCallCount = 0
    
    override init() {
        super.init()
        // Override the published property with our mock value
        hasAccessibilityPermission = true
    }
    
    override func injectText(_ text: String) {
        injectionCallCount += 1
        
        if shouldFailPermission {
            return
        }
        
        if shouldFailInjection {
            return
        }
        
        injectedText = text
    }
    
    override func canInjectText() -> Bool {
        return !shouldFailPermission && !shouldFailInjection
    }
    
    override func getCurrentFocusInfo() -> String {
        if shouldFailPermission {
            return "No accessibility permission"
        }
        return "Mock focus info"
    }
    
    func simulateAccessibilityPermissionGranted() {
        shouldFailPermission = false
        hasAccessibilityPermission = true
    }
    
    func simulateAccessibilityPermissionDenied() {
        shouldFailPermission = true
        hasAccessibilityPermission = false
    }
    
    func simulateInjectionSuccess() {
        shouldFailInjection = false
    }
    
    func simulateInjectionFailure() {
        shouldFailInjection = true
    }
    
    func getInjectedText() -> String? {
        return injectedText
    }
    
    func getInjectionCallCount() -> Int {
        return injectionCallCount
    }
    
    func getPermissionCheckCallCount() -> Int {
        return permissionCheckCallCount
    }
    
    func reset() {
        shouldFailInjection = false
        shouldFailPermission = false
        injectedText = nil
        injectionCallCount = 0
        permissionCheckCallCount = 0
        hasAccessibilityPermission = true
    }
}