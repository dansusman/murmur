import Foundation
import AppKit

class FloatingIndicatorManager {
    private var windowController: FloatingRecordingWindowController?
    
    func showRecordingIndicator() {
        print("🎬 FloatingIndicatorManager.showRecordingIndicator() called")
        if windowController == nil {
            print("🏗️ Creating new FloatingRecordingWindowController")
            windowController = FloatingRecordingWindowController()
        }
        print("👁️ Calling windowController.show()")
        windowController?.show()
    }
    
    func hideRecordingIndicator() {
        windowController?.hide()
    }
}