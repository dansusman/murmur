import AppKit
import ApplicationServices

class RecordingIndicatorManager {
    private var borderWindow: RecordingBorderWindow?
    private var targetWindowBounds: CGRect?
    private var borderSettings: BorderSettings
    
    init(borderSettings: BorderSettings = .default) {
        self.borderSettings = borderSettings
    }
    
    func updateSettings(_ settings: BorderSettings) {
        self.borderSettings = settings
        
        if let borderWindow = borderWindow {
            borderWindow.updateBorder(color: settings.color, width: settings.thickness)
        }
    }
    
    func showRecordingBorder() {
        guard borderSettings.isEnabled else { return }
        
        guard checkAccessibilityPermission() else {
            Logger.border.warning("Accessibility permission not granted - skipping border display")
            return
        }
        
        guard let bounds = captureActiveWindowBounds() else {
            Logger.border.warning("Could not capture active window bounds - skipping border display")
            return
        }
        
        createAndShowBorderWindow(for: bounds)
    }
    
    func hideRecordingBorder() {
        borderWindow?.orderOut(nil)
        borderWindow = nil
        targetWindowBounds = nil
    }
    
    private func checkAccessibilityPermission() -> Bool {
        return AXIsProcessTrusted()
    }
    
    private func captureActiveWindowBounds() -> CGRect? {
        guard let frontmostApp = NSWorkspace.shared.frontmostApplication else {
            return nil
        }
        
        if let bounds = getWindowBoundsUsingAccessibility(app: frontmostApp) {
            return bounds
        }
        
        return getWindowBoundsUsingCoreGraphics(app: frontmostApp)
    }
    
    private func getWindowBoundsUsingAccessibility(app: NSRunningApplication) -> CGRect? {
        let appElement = AXUIElementCreateApplication(app.processIdentifier)
        
        var focusedWindow: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXFocusedWindowAttribute as CFString, &focusedWindow)
        
        guard result == .success, let window = focusedWindow else {
            return nil
        }
        
        var position: CFTypeRef?
        var size: CFTypeRef?
        
        let positionResult = AXUIElementCopyAttributeValue(window as! AXUIElement, kAXPositionAttribute as CFString, &position)
        let sizeResult = AXUIElementCopyAttributeValue(window as! AXUIElement, kAXSizeAttribute as CFString, &size)
        
        guard positionResult == .success, sizeResult == .success,
              let positionValue = position, let sizeValue = size else {
            return nil
        }
        
        var point = CGPoint.zero
        var rect = CGSize.zero
        
        guard AXValueGetValue(positionValue as! AXValue, .cgPoint, &point),
              AXValueGetValue(sizeValue as! AXValue, .cgSize, &rect) else {
            return nil
        }
        
        return CGRect(x: point.x, y: point.y, width: rect.width, height: rect.height)
    }
    
    private func getWindowBoundsUsingCoreGraphics(app: NSRunningApplication) -> CGRect? {
        guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
            return nil
        }
        
        for windowInfo in windowList {
            guard let windowOwnerPID = windowInfo[kCGWindowOwnerPID as String] as? Int32,
                  windowOwnerPID == app.processIdentifier,
                  let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: CGFloat],
                  let x = boundsDict["X"],
                  let y = boundsDict["Y"],
                  let width = boundsDict["Width"],
                  let height = boundsDict["Height"],
                  width > 0, height > 0 else {
                continue
            }
            
            return CGRect(x: x, y: y, width: width, height: height)
        }
        
        return nil
    }
    
    private func createAndShowBorderWindow(for bounds: CGRect) {
        hideRecordingBorder()
        
        guard bounds.width > 0 && bounds.height > 0 else { return }
        
        let adjustedBounds = validateAndAdjustBounds(bounds)
        
        borderWindow = RecordingBorderWindow(
            contentRect: adjustedBounds,
            borderColor: borderSettings.color,
            borderWidth: borderSettings.thickness
        )
        
        borderWindow?.makeKeyAndOrderFront(nil)
        targetWindowBounds = adjustedBounds
    }
    
    private func validateAndAdjustBounds(_ bounds: CGRect) -> CGRect {
        var adjustedBounds = bounds
        
        if let screen = NSScreen.main {
            let screenFrame = screen.frame
            
            adjustedBounds.origin.x = max(adjustedBounds.origin.x, screenFrame.origin.x)
            adjustedBounds.origin.y = max(adjustedBounds.origin.y, screenFrame.origin.y)
            
            if adjustedBounds.maxX > screenFrame.maxX {
                adjustedBounds.size.width = screenFrame.maxX - adjustedBounds.origin.x
            }
            
            if adjustedBounds.maxY > screenFrame.maxY {
                adjustedBounds.size.height = screenFrame.maxY - adjustedBounds.origin.y
            }
        }
        
        adjustedBounds.size.width = max(adjustedBounds.size.width, 10)
        adjustedBounds.size.height = max(adjustedBounds.size.height, 10)
        
        return adjustedBounds
    }
}