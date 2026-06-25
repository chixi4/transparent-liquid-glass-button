import AppKit

// MARK: - Draggable Glass Capsule Button
class DraggableGlassButton: NSButton {
    private let glassView = NSGlassEffectView()
    private var isDragging = false
    private var dragScreenStart: NSPoint = .zero
    private var windowFrameStart: NSPoint = .zero
    
    let capsuleHeight: CGFloat = 56
    let capsuleWidth: CGFloat = 130
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        title = ""
        bezelStyle = .rounded
        isBordered = false
        
        glassView.frame = bounds
        glassView.autoresizingMask = [.width, .height]
        glassView.cornerRadius = capsuleHeight / 2
        if #available(macOS 27, *) {
            glassView.style = .clear
            glassView.effectIsInteractive = true
        }
        addSubview(glassView, positioned: .below, relativeTo: nil)
        
        wantsLayer = true
        layer?.cornerRadius = capsuleHeight / 2
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.25).cgColor
        layer?.masksToBounds = false
    }
    
    // MARK: - Drag (screen coordinates to avoid jitter)
    override func mouseDown(with event: NSEvent) {
        isDragging = false
        dragScreenStart = NSEvent.mouseLocation
        windowFrameStart = window?.frame.origin ?? .zero
    }
    
    override func mouseDragged(with event: NSEvent) {
        isDragging = true
        guard let win = window else { return }
        let currentScreen = NSEvent.mouseLocation
        let dx = currentScreen.x - dragScreenStart.x
        let dy = currentScreen.y - dragScreenStart.y
        win.setFrameOrigin(NSPoint(
            x: windowFrameStart.x + dx,
            y: windowFrameStart.y + dy
        ))
    }
    
    override func mouseUp(with event: NSEvent) {
        if !isDragging {
            _ = target?.perform(action, with: self)
        }
        isDragging = false
    }
}

// MARK: - Transparent Floating Window
@MainActor
class AppDelegate: NSObject, NSApplicationDelegate {
    private var window: NSWindow!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        let button = DraggableGlassButton()
        let padding: CGFloat = 20
        let winW = button.capsuleWidth + padding * 2
        let winH = button.capsuleHeight + padding * 2
        
        let screenFrame = NSScreen.main?.visibleFrame ?? NSRect(x: 0, y: 0, width: 1440, height: 900)
        let origin = NSPoint(
            x: screenFrame.midX - winW / 2,
            y: screenFrame.midY - winH / 2
        )
        
        window = NSWindow(
            contentRect: NSRect(origin: origin, size: NSSize(width: winW, height: winH)),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = ""
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.level = .floating
        window.standardWindowButton(.closeButton)?.isHidden = true
        window.standardWindowButton(.miniaturizeButton)?.isHidden = true
        window.standardWindowButton(.zoomButton)?.isHidden = true
        window.titlebarAppearsTransparent = true
        window.makeKeyAndOrderFront(nil)
        
        guard let contentView = window.contentView else { return }
        
        button.frame = NSRect(x: padding, y: padding, width: button.capsuleWidth, height: button.capsuleHeight)
        contentView.addSubview(button)
    }
}

// MARK: - Entry Point
@main struct MainApp {
    static func main() {
        let app = NSApplication.shared
        app.setActivationPolicy(.regular)
        let delegate = AppDelegate()
        app.delegate = delegate
        app.run()
    }
}
