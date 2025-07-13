import Foundation
import AppKit
import ApplicationServices

class TextInjector: NSObject, ObservableObject {
    @Published var hasAccessibilityPermission = false
    
    override init() {
        super.init()
        checkAccessibilityPermission()
    }
    
    private func checkAccessibilityPermission() {
        let trusted = AXIsProcessTrusted()
        hasAccessibilityPermission = trusted
        Logger.textInjector.info("🔍 Accessibility permission check: \(trusted ? "✅ GRANTED" : "❌ NOT GRANTED")")
    }
    
    func pollAccessibilityPermission() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            let trusted = AXIsProcessTrusted()
            self.hasAccessibilityPermission = trusted
            Logger.textInjector.debug("🔍 Polling accessibility permission: \(trusted ? "✅ GRANTED" : "❌ NOT GRANTED")")

            if !self.hasAccessibilityPermission {
                self.pollAccessibilityPermission()
            } else {
                Logger.textInjector.success("✅ Accessibility permission polling stopped - permission granted!")
            }
        }
    }
    
    static func requestAccessibilityPermission() {
        let options: NSDictionary = [kAXTrustedCheckOptionPrompt.takeRetainedValue() as NSString: true]
        let _ = AXIsProcessTrustedWithOptions(options)
    }
    
    func injectText(_ text: String) {
        Logger.textInjector.debug("🔍 TextInjector.injectText called with: \"\(text)\"")
        Logger.textInjector.debug("🔍 Current accessibility permission status: \(hasAccessibilityPermission)")
        
        guard hasAccessibilityPermission else {
            Logger.textInjector.warning("❌ Accessibility permission not granted - requesting permission...")
            TextInjector.requestAccessibilityPermission()
            return
        }
        
        guard !text.isEmpty else {
            Logger.textInjector.warning("❌ Empty text to inject")
            return
        }
        
        // Method 1: Use pasteboard + Cmd+V (most reliable)
        injectTextViaPasteboard(text)
    }
    
    private func injectTextViaPasteboard(_ text: String) {
        // Save current pasteboard content
        let pasteboard = NSPasteboard.general
        let originalContent = pasteboard.string(forType: .string)
        
        // Set new content
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        
        // Send Cmd+V
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.simulateKeyPress(key: CGKeyCode(9), modifiers: .maskCommand) // Cmd+V
            
            // Restore original pasteboard content after a delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                pasteboard.clearContents()
                if let originalContent = originalContent {
                    pasteboard.setString(originalContent, forType: .string)
                }
            }
        }
    }
    
    private func simulateKeyPress(key: CGKeyCode, modifiers: CGEventFlags) {
        guard let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: true),
              let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: key, keyDown: false) else {
            return
        }
        
        keyDownEvent.flags = modifiers
        keyUpEvent.flags = modifiers
        
        keyDownEvent.post(tap: .cghidEventTap)
        keyUpEvent.post(tap: .cghidEventTap)
    }
    
    // Alternative method: Direct text insertion via Accessibility API
    private func injectTextViaAccessibility(_ text: String) {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            Logger.textInjector.warning("No frontmost application")
            return
        }
        
        let pid = frontmostApp.processIdentifier
        let appRef = AXUIElementCreateApplication(pid)
        
        // Get focused element
        var focusedElement: AnyObject?
        let result = AXUIElementCopyAttributeValue(appRef, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        guard result == .success, let element = focusedElement else {
            Logger.textInjector.warning("Failed to get focused element")
            return
        }
        
        // Insert text
        let elementRef = element as! AXUIElement
        let cfText = text as CFString
        AXUIElementSetAttributeValue(elementRef, kAXValueAttribute as CFString, cfText)
    }
    
    // Method 3: Type characters individually (slower but more compatible)
    private func injectTextByTyping(_ text: String) {
        for char in text {
            if let keyCode = getKeyCode(for: char) {
                simulateKeyPress(key: keyCode, modifiers: [])
            }
        }
    }
    
    private func getKeyCode(for character: Character) -> CGKeyCode? {
        // Map characters to key codes
        let keyMap: [Character: CGKeyCode] = [
            "a": 0, "b": 11, "c": 8, "d": 2, "e": 14, "f": 3, "g": 5, "h": 4, "i": 34,
            "j": 38, "k": 40, "l": 37, "m": 46, "n": 45, "o": 31, "p": 35, "q": 12,
            "r": 15, "s": 1, "t": 17, "u": 32, "v": 9, "w": 13, "x": 7, "y": 16, "z": 6,
            " ": 49, // Space
            "1": 18, "2": 19, "3": 20, "4": 21, "5": 23, "6": 22, "7": 26, "8": 28, "9": 25, "0": 29,
            ".": 47, ",": 43, "?": 44, "!": 18, // ! requires shift+1
            "-": 27, "=": 24, "[": 33, "]": 30, "\\": 42, ";": 41, "'": 39, "/": 44
        ]
        
        return keyMap[Character(character.lowercased())]
    }
    
    // Check if current application has text input capability
    func canInjectText() -> Bool {
        guard hasAccessibilityPermission else { return false }
        
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return false
        }
        
        let pid = frontmostApp.processIdentifier
        let appRef = AXUIElementCreateApplication(pid)
        
        var focusedElement: AnyObject?
        let result = AXUIElementCopyAttributeValue(appRef, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        guard result == .success, let element = focusedElement else {
            return false
        }
        
        // Check if the focused element supports text input
        let elementRef = element as! AXUIElement
        var role: AnyObject?
        AXUIElementCopyAttributeValue(elementRef, kAXRoleAttribute as CFString, &role)
        
        if let roleString = role as? String {
            let textInputRoles = [
                kAXTextFieldRole,
                kAXTextAreaRole,
                kAXComboBoxRole,
                kAXStaticTextRole
            ]
            
            return textInputRoles.contains(roleString)
        }
        
        return false
    }
    
    // Get information about the current focused element
    func getCurrentFocusInfo() -> String {
        guard hasAccessibilityPermission else {
            return "No accessibility permission"
        }
        
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return "No frontmost application"
        }
        
        let pid = frontmostApp.processIdentifier
        let appRef = AXUIElementCreateApplication(pid)
        
        var focusedElement: AnyObject?
        let result = AXUIElementCopyAttributeValue(appRef, kAXFocusedUIElementAttribute as CFString, &focusedElement)
        
        guard result == .success, let element = focusedElement else {
            return "No focused element"
        }
        
        let elementRef = element as! AXUIElement
        var role: AnyObject?
        var title: AnyObject?
        
        AXUIElementCopyAttributeValue(elementRef, kAXRoleAttribute as CFString, &role)
        AXUIElementCopyAttributeValue(elementRef, kAXTitleAttribute as CFString, &title)
        
        let roleString = role as? String ?? "Unknown"
        let titleString = title as? String ?? "No title"
        
        return "App: \(frontmostApp.localizedName ?? "Unknown"), Role: \(roleString), Title: \(titleString)"
    }
}
