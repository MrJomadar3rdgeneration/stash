import SwiftUI
import AppKit
import Carbon
import ApplicationServices
import ServiceManagement

struct SettingsView: View {
    @ObservedObject var store: HistoryStore
    let delegate: AppDelegate
    @Environment(\.dismiss) private var dismiss
    @ViewState private var recording = false
    @ViewState private var shortcutLabel = UserDefaults.standard.string(forKey: "hotkeyLabel") ?? "⌘ ⇧ V"
    @ViewState private var shortcutError: String?
    @ViewState private var loginEnabled = SMAppService.mainApp.status == .enabled
    @ViewState private var loginError: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack { Text("Make room for your workflow.").font(.system(size: 22, weight: .medium, design: .rounded)); Spacer(); Button("Done") { dismiss() }.keyboardShortcut(.cancelAction) }
            Form {
                Section("Quick access") {
                    Button("Restore menu-bar icon") { delegate.restoreStatusItem() }
                    Text("If the icon is still missing, macOS may have run out of menu-bar space. Open Stash from Applications or use your shortcut.").font(.caption).foregroundStyle(.secondary)
                    HStack {
                        Text("Open history"); Spacer()
                        ShortcutRecorder(recording: $recording, label: $shortcutLabel, error: $shortcutError, shortcut: delegate.shortcut).frame(width: 190, height: 28)
                    }
                    if let shortcutError { Text(shortcutError).foregroundStyle(.orange).font(.caption) }
                    Toggle("Paste directly into the previous app", isOn: $store.directPaste)
                    Text("Off by default: Return copies the clip. Direct paste needs Accessibility permission and may not work in protected fields. ⇧Return uses plain text.").font(.caption).foregroundStyle(.secondary)
                    if store.directPaste {
                        Button("Allow Accessibility…") {
                            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
                            _ = AXIsProcessTrustedWithOptions(options)
                            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                        }
                    }
                    Toggle("Launch at login", isOn: Binding(get: { loginEnabled }, set: { enabled in
                        do {
                            if enabled { try SMAppService.mainApp.register() } else { try SMAppService.mainApp.unregister() }
                            refreshLoginStatus()
                        } catch { loginError = error.localizedDescription; loginEnabled = SMAppService.mainApp.status == .enabled }
                    }))
                    Text("Starts capturing quietly after you sign in. Closing the history window keeps capture running; Quit Stash stops it.").font(.caption).foregroundStyle(.secondary)
                    if SMAppService.mainApp.status == .requiresApproval {
                        Button("Open Login Items Settings…") { SMAppService.openSystemSettingsLoginItems() }
                    }
                    if let loginError { Text(loginError).font(.caption).foregroundStyle(.orange) }
                }
                Section("Local history") {
                    Picker("Keep unpinned clips", selection: $store.retentionDays) {
                        Text("7 days").tag(7); Text("30 days").tag(30); Text("90 days").tag(90); Text("Until storage limit").tag(0)
                    }
                    Picker("Maximum clips", selection: $store.historyLimit) {
                        Text("500").tag(500); Text("1,000").tag(1000); Text("5,000").tag(5000); Text("10,000").tag(10000)
                    }
                    Text("\(store.clips.count) clips · \(store.storageSize) of content. Cleanup applies immediately. Unpinned history has a 250 MB budget; pins are never automatically removed. Clips over 20 MB are skipped.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Privacy") {
                    Text("Never capture from these apps (one bundle identifier per line)").font(.caption)
                    TextEditor(text: $store.exclusions).font(.system(size: 11, design: .monospaced)).frame(height: 76)
                    Text("Exclusions apply to future copies. Delete older clips separately. Password managers and clipboard content marked confidential or temporary are skipped. Unmarked secrets may still be captured—Stash is not a password vault.").font(.caption).foregroundStyle(.secondary)
                    Text("History is encrypted on this Mac. No accounts, analytics, cloud sync, or network requests. Your system clipboard may still participate in Apple Universal Clipboard.").font(.caption).foregroundStyle(.secondary)
                }
                Section("Keyboard") {
                    Text("↑ ↓ Select · Return Copy/Paste · ⇧Return Plain text\n⌘P Pin · ⌘⌫ Delete · Escape Hide").font(.system(size: 11, design: .monospaced))
                }
            }.formStyle(.grouped)
            HStack { Text("STASH  /  0.3.1").font(.system(size: 9, weight: .medium)).tracking(1.4).foregroundStyle(muted); Spacer(); Button("Quit Stash") { delegate.quit() }.buttonStyle(.plain).foregroundStyle(muted).font(.caption) }
        }.padding(25).frame(width: 560, height: 720).background(canvas).preferredColorScheme(.dark)
            .onAppear { refreshLoginStatus() }
            .onDisappear {
                if recording { _ = delegate.shortcut.resumeAfterRecording() }
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.didBecomeActiveNotification)) { _ in refreshLoginStatus() }
    }
    private func refreshLoginStatus() {
        let status = SMAppService.mainApp.status
        loginEnabled = status == .enabled
        loginError = status == .requiresApproval ? "macOS requires approval in Login Items before automatic startup is enabled." : nil
    }
}
struct ShortcutRecorder: NSViewRepresentable {
    @Binding var recording: Bool
    @Binding var label: String
    @Binding var error: String?
    let shortcut: GlobalShortcut
    func makeNSView(context: Context) -> RecorderButton {
        let button = RecorderButton()
        button.bezelStyle = .rounded
        button.target = button
        button.action = #selector(RecorderButton.beginRecording(_:))
        button.onRecord = { shortcut.suspendForRecording(); recording = true }
        button.onKey = { event in
            if event.keyCode == 53 {
                if !shortcut.resumeAfterRecording() { error = "The previous shortcut is now unavailable. Record another combination." }
                recording = false; return
            }
            let flags = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
            guard flags.contains(.command) || flags.contains(.control) || flags.contains(.option) else { error = "Include ⌘, ⌃, or ⌥ with a key."; return }
            var mods: UInt32 = 0
            if flags.contains(.command) { mods |= UInt32(cmdKey) }
            if flags.contains(.shift) { mods |= UInt32(shiftKey) }
            if flags.contains(.option) { mods |= UInt32(optionKey) }
            if flags.contains(.control) { mods |= UInt32(controlKey) }
            guard shortcut.register(key: UInt32(event.keyCode), modifiers: mods) else { error = "Shortcut unavailable. Try another combination."; return }
            let title = (flags.contains(.control) ? "⌃ " : "") + (flags.contains(.option) ? "⌥ " : "") + (flags.contains(.shift) ? "⇧ " : "") + (flags.contains(.command) ? "⌘ " : "") + (event.charactersIgnoringModifiers?.uppercased() ?? "Key \(event.keyCode)")
            UserDefaults.standard.set(Int(event.keyCode), forKey: "hotkeyCode")
            UserDefaults.standard.set(Int(mods), forKey: "hotkeyModifiers")
            UserDefaults.standard.set(title, forKey: "hotkeyLabel")
            label = title; error = nil; recording = false
        }
        return button
    }
    func updateNSView(_ button: RecorderButton, context: Context) {
        button.title = recording ? "Press shortcut… (Esc cancels)" : label
        button.recording = recording
    }
}
final class RecorderButton: NSButton {
    var recording = false
    var onRecord: (() -> Void)?
    var onKey: ((NSEvent) -> Void)?
    override var acceptsFirstResponder: Bool { true }
    @objc func beginRecording(_ sender: Any?) { window?.makeFirstResponder(self); onRecord?() }
    override func keyDown(with event: NSEvent) { if recording { onKey?(event) } else { super.keyDown(with: event) } }
    override func performKeyEquivalent(with event: NSEvent) -> Bool { if recording { onKey?(event); return true }; return super.performKeyEquivalent(with: event) }
}
