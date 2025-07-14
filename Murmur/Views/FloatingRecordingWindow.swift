import SwiftUI
import AppKit

class FloatingRecordingWindow: NSWindow {
    override var canBecomeKey: Bool { false }
    override var canBecomeMain: Bool { false }
    
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 240, height: 40),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        
        // Configure window properties
        self.backgroundColor = NSColor.clear
        self.isOpaque = false
        self.level = .floating
        self.ignoresMouseEvents = true
        self.isMovable = false
        
        // Position at bottom center of screen
        positionAtBottomCenter()
        
        // Set up SwiftUI content
        let hostingView = NSHostingView(rootView: FloatingRecordingIndicator())
        self.contentView = hostingView
    }
    
    private func positionAtBottomCenter() {
        print("🚀 positionAtBottomCenter() called")
        let currentScreen = screenWithActiveWindow()
        let screenFrame = currentScreen.visibleFrame
        let windowSize = self.frame.size
        
        let x = screenFrame.midX - (windowSize.width / 2)
        let y = screenFrame.minY + 60 // 60 points from bottom
        
        print("🎯 Final position: x=\(x), y=\(y) on screen \(screenFrame)")
        self.setFrameOrigin(NSPoint(x: x, y: y))
    }
    
    func refreshPosition() {
        print("🔄 refreshPosition() called - detecting active window")
        positionAtBottomCenter()
    }
    
    private func screenWithActiveWindow() -> NSScreen {
        print("🔍 screenWithActiveWindow() called")
        
        // Get the active window frame
        guard let activeWindowFrame = getActiveWindowFrame() else {
            print("⚠️ No active window found, using main screen")
            return NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
        }
        
        // Find which screen contains the center of the active window
        let windowCenter = NSPoint(
            x: activeWindowFrame.midX,
            y: activeWindowFrame.midY
        )
        
        for screen in NSScreen.screens {
            if screen.frame.contains(windowCenter) {
                print("✅ Found screen containing active window: \(screen.frame)")
                return screen
            }
        }
        
        // If no screen contains the center, find the screen with the most overlap
        var bestScreen = NSScreen.main ?? NSScreen.screens.first ?? NSScreen()
        var maxOverlap: CGFloat = 0
        
        for screen in NSScreen.screens {
            let intersection = screen.frame.intersection(activeWindowFrame)
            let overlapArea = intersection.width * intersection.height
            
            if overlapArea > maxOverlap {
                maxOverlap = overlapArea
                bestScreen = screen
            }
        }
        
        print("✅ Using screen with most overlap: \(bestScreen.frame)")
        return bestScreen
    }
    
    private func getActiveWindowFrame() -> CGRect? {
        // Get the frontmost application
        let workspace = NSWorkspace.shared
        guard let frontmostApp = workspace.frontmostApplication else {
            print("❌ No frontmost application")
            return nil
        }
        
        print("🎯 Frontmost app: \(frontmostApp.localizedName ?? "Unknown") (\(frontmostApp.bundleIdentifier ?? "no bundle ID"))")
        
        // Use CGWindowListCopyWindowInfo to get window information
        let windowListInfo = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]]
        
        guard let windowList = windowListInfo else {
            print("❌ Could not get window list")
            return nil
        }
        
        // Find the frontmost window of the frontmost application
        for windowInfo in windowList {
            guard let ownerPID = windowInfo[kCGWindowOwnerPID as String] as? Int32,
                  ownerPID == frontmostApp.processIdentifier,
                  let boundsDict = windowInfo[kCGWindowBounds as String] as? [String: Any],
                  let layer = windowInfo[kCGWindowLayer as String] as? Int,
                  layer == 0 else { // layer 0 is normal window layer
                continue
            }
            
            // Extract window bounds
            if let x = boundsDict["X"] as? CGFloat,
               let y = boundsDict["Y"] as? CGFloat,
               let width = boundsDict["Width"] as? CGFloat,
               let height = boundsDict["Height"] as? CGFloat {
                
                let windowFrame = CGRect(x: x, y: y, width: width, height: height)
                print("✅ Found active window: \(windowFrame)")
                return windowFrame
            }
        }
        
        print("❌ Could not find active window bounds")
        return nil
    }
}

class FloatingRecordingWindowController: NSWindowController {
    convenience init() {
        let window = FloatingRecordingWindow()
        self.init(window: window)
    }
    
    func show() {
        (window as? FloatingRecordingWindow)?.refreshPosition()
        window?.orderFront(nil)
    }
    
    func hide() {
        window?.orderOut(nil)
    }
}