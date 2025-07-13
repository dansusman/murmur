import AppKit

class RecordingBorderWindow: NSWindow {
    private var borderView: RecordingBorderView
    
    init(contentRect: NSRect, borderColor: NSColor = .systemRed, borderWidth: CGFloat = 3.0) {
        self.borderView = RecordingBorderView(frame: contentRect)
        
        super.init(
            contentRect: contentRect,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        
        setupWindow()
        setupBorderView(borderColor: borderColor, borderWidth: borderWidth)
    }
    
    private func setupWindow() {
        self.backgroundColor = .clear
        self.isOpaque = false
        self.level = .floating
        self.ignoresMouseEvents = true
        self.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
    }
    
    private func setupBorderView(borderColor: NSColor, borderWidth: CGFloat) {
        borderView.borderColor = borderColor
        borderView.borderWidth = borderWidth
        self.contentView = borderView
    }
    
    func updateBorder(color: NSColor, width: CGFloat) {
        borderView.borderColor = color
        borderView.borderWidth = width
    }
    
    func updateFrame(_ frame: NSRect) {
        self.setFrame(frame, display: true, animate: false)
        borderView.frame = NSRect(origin: .zero, size: frame.size)
    }
    
    override var canBecomeKey: Bool {
        return false
    }
    
    override var canBecomeMain: Bool {
        return false
    }
}