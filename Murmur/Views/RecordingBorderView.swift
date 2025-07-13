import AppKit

class RecordingBorderView: NSView {
    var borderColor: NSColor = .systemRed {
        didSet {
            needsDisplay = true
        }
    }
    
    var borderWidth: CGFloat = 3.0 {
        didSet {
            needsDisplay = true
        }
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.wantsLayer = true
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard borderWidth > 0 else { return }
        
        let borderPath = NSBezierPath(rect: bounds)
        borderPath.lineWidth = borderWidth
        
        borderColor.setStroke()
        borderPath.stroke()
    }
    
    override var isOpaque: Bool {
        return false
    }
    
    override func acceptsFirstMouse(for event: NSEvent?) -> Bool {
        return false
    }
}