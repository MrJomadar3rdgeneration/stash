import AppKit
import SwiftUI
import Carbon
import ApplicationServices
import StashCore

@main enum StashApp {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = AppDelegate()
        app.delegate = delegate
        withExtendedLifetime(delegate) { app.run() }
    }
}
@MainActor final class AppDelegate: NSObject, NSApplicationDelegate {
    var store: HistoryStore!
    var window: NSWindow!
    var statusItem: NSStatusItem!
    var previousApp: NSRunningApplication?
    var shortcut: GlobalShortcut!
    var keyMonitor: Any?
    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        installMainMenu()
        store = HistoryStore(demo: CommandLine.arguments.contains("--demo"))
        window = NSWindow(contentRect: NSRect(x: 0, y: 0, width: 1040, height: 680), styleMask: [.titled, .closable, .resizable, .fullSizeContentView], backing: .buffered, defer: false)
        window.title = "Stash"; window.titlebarAppearsTransparent = true; window.titleVisibility = .hidden
        window.isReleasedWhenClosed = false; window.minSize = NSSize(width: 900, height: 580)
        window.backgroundColor = NSColor(calibratedRed: 0.075, green: 0.09, blue: 0.10, alpha: 1)
        window.appearance = NSAppearance(named: .darkAqua)
        window.level = .normal; window.collectionBehavior = [.moveToActiveSpace, .fullScreenAuxiliary]
        window.contentView = NSHostingView(rootView: MainView(store: store, delegate: self))
        window.center()
        restoreStatusItem()
        shortcut = GlobalShortcut { [weak self] in self?.toggle() }
        registerShortcut()
        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            guard let self, self.window.isKeyWindow, self.window.attachedSheet == nil, !self.store.settingsOpen, !self.store.editing else { return event }
            let command = event.modifierFlags.contains(.command)
            if event.keyCode == 53 { self.window.orderOut(nil); return nil }
            if event.keyCode == 125 { self.store.move(1); return nil }
            if event.keyCode == 126 { self.store.move(-1); return nil }
            if event.keyCode == 36, let clip = self.store.selected {
                self.use(clip, plain: event.modifierFlags.contains(.shift)); return nil
            }
            if command, event.charactersIgnoringModifiers == "p", let clip = self.store.selected { self.store.pin(clip); return nil }
            if command, event.keyCode == 51, let clip = self.store.selected { self.store.delete(clip); return nil }
            return event
        }
        let event = NSAppleEventManager.shared().currentAppleEvent
        let launchedAtLogin = event?.eventID == kAEOpenApplication && event?.paramDescriptor(forKeyword: keyAEPropData)?.enumCodeValue == keyAELaunchedAsLogInItem
        if !launchedAtLogin && !CommandLine.arguments.contains("--background") { show() }
    }
    @objc func restoreStatusItem() {
        if let statusItem { NSStatusBar.system.removeStatusItem(statusItem) }
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        statusItem.autosaveName = "StashStatusItem"
        statusItem.isVisible = true
        let icon = NSImage(systemSymbolName: "square.on.square", accessibilityDescription: "Stash clipboard history")
        icon?.isTemplate = true
        icon?.size = NSSize(width: 18, height: 18)
        statusItem.button?.image = icon
        statusItem.button?.toolTip = "Stash — open clipboard history"
        statusItem.button?.setAccessibilityLabel("Stash clipboard history")
        statusItem.button?.target = self
        statusItem.button?.action = #selector(statusClicked)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
    }
    func installMainMenu() {
        let main = NSMenu()
        let appItem = NSMenuItem(); main.addItem(appItem)
        let appMenu = NSMenu(title: "Stash"); appItem.submenu = appMenu
        let openItem = appMenu.addItem(withTitle: "Open Stash", action: #selector(show), keyEquivalent: "0"); openItem.target = self
        let settings = appMenu.addItem(withTitle: "Settings…", action: #selector(openSettings), keyEquivalent: ","); settings.target = self
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "Quit Stash", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        let editItem = NSMenuItem(); main.addItem(editItem)
        let edit = NSMenu(title: "Edit"); editItem.submenu = edit
        for (title, selector, key) in [("Undo", "undo:", "z"), ("Cut", "cut:", "x"), ("Copy", "copy:", "c"), ("Paste", "paste:", "v"), ("Select All", "selectAll:", "a")] {
            edit.addItem(withTitle: title, action: Selector(selector), keyEquivalent: key)
        }
        NSApp.mainMenu = main
    }
    @objc func openSettings() { show(); store.settingsOpen = true }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool { show(); return true }
    func registerShortcut() {
        let defaults = UserDefaults.standard
        let key = defaults.object(forKey: "hotkeyCode") == nil ? UInt32(kVK_ANSI_V) : UInt32(defaults.integer(forKey: "hotkeyCode"))
        let mods = defaults.object(forKey: "hotkeyModifiers") == nil ? UInt32(cmdKey | shiftKey) : UInt32(defaults.integer(forKey: "hotkeyModifiers"))
        if !shortcut.register(key: key, modifiers: mods) { store.error = "The global shortcut is in use. Choose another combination in Settings." }
    }
    @objc func statusClicked() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(withTitle: "Open Stash", action: #selector(show), keyEquivalent: "")
            menu.addItem(withTitle: store.paused ? "Resume capture" : "Pause capture", action: #selector(pause), keyEquivalent: "")
            menu.addItem(.separator())
            menu.addItem(withTitle: "Quit Stash", action: #selector(quit), keyEquivalent: "q")
            for item in menu.items { item.target = self }
            statusItem.menu = menu; statusItem.button?.performClick(nil); statusItem.menu = nil
        } else { toggle() }
    }
    @objc func pause() { store.paused.toggle() }
    @objc func quit() { NSApp.terminate(nil) }
    func toggle() { if window.isVisible && window.isKeyWindow { window.orderOut(nil) } else { show() } }
    @objc func show() {
        if NSWorkspace.shared.frontmostApplication?.processIdentifier != ProcessInfo.processInfo.processIdentifier { previousApp = NSWorkspace.shared.frontmostApplication }
        store.objectWillChange.send()
        NSApp.activate(ignoringOtherApps: true); window.makeKeyAndOrderFront(nil)
        NotificationCenter.default.post(name: .init("StashFocusSearch"), object: nil)
    }
    func use(_ clip: Clip, plain: Bool = false) {
        guard store.restore(clip, plain: plain) else { return }
        guard store.directPaste else { store.notice = "Copied. Switch to your app and press ⌘V."; return }
        guard AXIsProcessTrusted() else { store.notice = "Copied. Enable Accessibility in Settings for direct paste."; return }
        guard let target = previousApp, !target.isTerminated else { store.notice = "Copied. Press ⌘V in your destination app."; return }
        window.orderOut(nil); target.activate(options: [])
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            guard NSWorkspace.shared.frontmostApplication?.processIdentifier == target.processIdentifier else { self?.store.notice = "Copied; destination app could not be focused."; return }
            let source = CGEventSource(stateID: .combinedSessionState)
            let down = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: true)
            let up = CGEvent(keyboardEventSource: source, virtualKey: 9, keyDown: false)
            down?.flags = .maskCommand; up?.flags = .maskCommand
            down?.post(tap: .cghidEventTap); up?.post(tap: .cghidEventTap)
        }
    }
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }
    func applicationWillTerminate(_ notification: Notification) { store.stopMonitoring(); store.flush() }
}
@MainActor final class GlobalShortcut {
    private var hotkey: EventHotKeyRef?
    private var handler: EventHandlerRef?
    private var registeredKey: UInt32?
    private var registeredModifiers: UInt32?
    let action: () -> Void
    init(action: @escaping () -> Void) {
        self.action = action
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, _, context in
            guard let context else { return noErr }
            let shortcut = Unmanaged<GlobalShortcut>.fromOpaque(context).takeUnretainedValue()
            MainActor.assumeIsolated { shortcut.action() }; return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), &handler)
    }
    func suspendForRecording() {
        if let hotkey { UnregisterEventHotKey(hotkey) }
        hotkey = nil
    }
    @discardableResult func resumeAfterRecording() -> Bool {
        guard let key = registeredKey, let modifiers = registeredModifiers else { return false }
        return register(key: key, modifiers: modifiers)
    }
    func register(key: UInt32, modifiers: UInt32) -> Bool {
        if hotkey != nil, key == registeredKey, modifiers == registeredModifiers { return true }
        var candidate: EventHotKeyRef?
        let result = RegisterEventHotKey(key, modifiers, EventHotKeyID(signature: 0x53545348, id: 1), GetApplicationEventTarget(), 0, &candidate)
        guard result == noErr else { return false }
        if let hotkey { UnregisterEventHotKey(hotkey) }
        hotkey = candidate; registeredKey = key; registeredModifiers = modifiers; return true
    }
}
