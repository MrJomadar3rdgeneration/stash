import AppKit
import SwiftUI
import StashCore

@MainActor final class HistoryStore: ObservableObject {
    @Published var clips: [Clip] = []
    @Published var query = ""
    @Published var filter = "All clips"
    @Published var selectedID: UUID?
    @Published var paused = false { didSet { configureTimer(discardPending: true) } }
    @Published var error: String?
    @Published var notice: String?
    @Published var ready = false
    @Published var settingsOpen = false
    @Published var editing = false
    @Published var retentionDays: Int { didSet { defaults.set(retentionDays, forKey: "retentionDays"); prune() } }
    @Published var historyLimit: Int { didSet { defaults.set(historyLimit, forKey: "historyLimit"); prune() } }
    @Published var exclusions: String { didSet { defaults.set(exclusions, forKey: "exclusions") } }
    @Published var directPaste: Bool { didSet { defaults.set(directPaste, forKey: "directPaste") } }
    let demo: Bool
    private let defaults: UserDefaults
    private var vault: Vault?
    private let diskQueue = DispatchQueue(label: "com.stash.vault", qos: .utility)
    private var timer: Timer?
    private var observingPower = false
    private var displayAsleep = false
    private var systemAsleep = false
    private var sessionInactive = false
    private var workspaceObservers: [NSObjectProtocol] = []
    private var powerObserver: NSObjectProtocol?
    private var lastChange = NSPasteboard.general.changeCount
    private var lastPrune = Date()
    private var fingerprints: [UUID: String] = [:]
    private let maxClipBytes = 20 * 1024 * 1024
    var visible: [Clip] {
        clips.filter { clip in
            (filter == "All clips" || (filter == "Pinned" && clip.pinned) || filter == clip.kind.title) && clip.matches(query)
        }
    }
    var selected: Clip? { visible.first { $0.id == selectedID } }
    var storageSize: String { ByteCountFormatter.string(fromByteCount: Int64(clips.reduce(0) { $0 + $1.byteCount }), countStyle: .file) }
    init(demo: Bool = false) {
        self.demo = demo
        defaults = demo ? UserDefaults(suiteName: "com.stash.demo")! : .standard
        defaults.register(defaults: ["retentionDays": 30, "historyLimit": 1000, "exclusions": "com.1password.1password\ncom.agilebits.onepassword7\ncom.bitwarden.desktop\norg.keepassxc.keepassxc\ncom.apple.Passwords"])
        retentionDays = defaults.integer(forKey: "retentionDays")
        historyLimit = defaults.integer(forKey: "historyLimit")
        exclusions = defaults.string(forKey: "exclusions") ?? ""
        directPaste = defaults.bool(forKey: "directPaste")
        if demo { clips = Self.demoClips(); ready = true; selectedID = clips.first?.id; return }
        diskQueue.async { [weak self] in
            do {
                let vault = try Vault()
                let loaded = try vault.load()
                DispatchQueue.main.async {
                    guard let self else { return }
                    self.vault = vault; self.clips = loaded.clips; self.ready = true
                    if loaded.unreadable > 0 { self.error = "\(loaded.unreadable) history files could not be decrypted and were preserved on disk." }
                    self.prune(); self.startMonitoring(); self.ensureSelection()
                }
            } catch { DispatchQueue.main.async { self?.error = error.localizedDescription } }
        }
    }
    func ensureSelection() {
        if !visible.contains(where: { $0.id == selectedID }) { selectedID = visible.first?.id }
    }
    func move(_ delta: Int) {
        let list = visible; guard !list.isEmpty else { return }
        let index = list.firstIndex { $0.id == selectedID } ?? 0
        selectedID = list[min(max(index + delta, 0), list.count - 1)].id
    }
    func startMonitoring() {
        if !observingPower {
            observingPower = true
            let center = NSWorkspace.shared.notificationCenter
            let events: [(Notification.Name, (HistoryStore) -> Void)] = [
                (NSWorkspace.willSleepNotification, { $0.systemAsleep = true }),
                (NSWorkspace.didWakeNotification, { $0.systemAsleep = false }),
                (NSWorkspace.screensDidSleepNotification, { $0.displayAsleep = true }),
                (NSWorkspace.screensDidWakeNotification, { $0.displayAsleep = false }),
                (NSWorkspace.sessionDidResignActiveNotification, { $0.sessionInactive = true }),
                (NSWorkspace.sessionDidBecomeActiveNotification, { $0.sessionInactive = false })
            ]
            for (name, update) in events {
                workspaceObservers.append(center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                    MainActor.assumeIsolated {
                        guard let self else { return }
                        update(self); self.configureTimer(discardPending: true)
                    }
                })
            }
            powerObserver = NotificationCenter.default.addObserver(forName: .NSProcessInfoPowerStateDidChange, object: nil, queue: .main) { [weak self] _ in
                MainActor.assumeIsolated { self?.configureTimer(discardPending: false) }
            }
        }
        configureTimer(discardPending: true)
    }
    private func configureTimer(discardPending: Bool) {
        timer?.invalidate(); timer = nil
        guard !demo, ready, vault != nil else { return }
        if discardPending { lastChange = NSPasteboard.general.changeCount }
        guard !paused, !displayAsleep, !systemAsleep, !sessionInactive else { return }
        let interval: TimeInterval = ProcessInfo.processInfo.isLowPowerModeEnabled ? 1.0 : 0.5
        let newTimer = Timer(timeInterval: interval, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.poll() }
        }
        newTimer.tolerance = interval * 0.2
        timer = newTimer
        RunLoop.main.add(newTimer, forMode: .common)
    }
    func stopMonitoring() {
        timer?.invalidate(); timer = nil
        for observer in workspaceObservers { NSWorkspace.shared.notificationCenter.removeObserver(observer) }
        workspaceObservers.removeAll()
        if let powerObserver { NotificationCenter.default.removeObserver(powerObserver) }
        powerObserver = nil; observingPower = false
    }
    func poll() {
        if Date().timeIntervalSince(lastPrune) > 60 { prune(); lastPrune = Date() }
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChange else { return }
        lastChange = pasteboard.changeCount
        guard !paused, ready, vault != nil else { return }
        let change = lastChange
        let app = NSWorkspace.shared.frontmostApplication
        let bundle = app?.bundleIdentifier ?? ""
        guard bundle != Bundle.main.bundleIdentifier else { return }
        let excluded = exclusions.components(separatedBy: .newlines).map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
        do {
            if let clip = try PasteboardCodec.capture(from: pasteboard, source: app?.localizedName ?? "Unknown app", bundle: bundle, excluded: excluded, maxClipBytes: maxClipBytes), pasteboard.changeCount == change { add(clip) }
        } catch { notice = "Skipped a clip larger than 20 MB." }
    }

    func add(_ clip: Clip) {
        var incoming = clip
        let incomingHash = clip.fingerprint
        if let previous = clips.first(where: { existing in
            let hash = fingerprints[existing.id] ?? existing.fingerprint
            fingerprints[existing.id] = hash
            return hash == incomingHash
        }) {
            incoming = previous; incoming.lastCopiedAt = Date()
            clips.removeAll { $0.id == previous.id }
        }
        fingerprints[incoming.id] = incomingHash
        clips.insert(incoming, at: 0); persist(incoming); prune(); ensureSelection()
    }
    func pin(_ clip: Clip) {
        guard let index = clips.firstIndex(where: { $0.id == clip.id }) else { return }
        clips[index].pinned.toggle(); persist(clips[index]); prune(); ensureSelection()
    }
    func edit(_ clip: Clip, text: String) {
        guard let index = clips.firstIndex(where: { $0.id == clip.id }) else { return }
        clips[index].text = text
        clips[index].kind = .text
        clips[index].items = [[Representation(type: NSPasteboard.PasteboardType.string.rawValue, data: Data(text.utf8))]]
        fingerprints[clip.id] = clips[index].fingerprint
        persist(clips[index]); ensureSelection(); notice = "Saved as plain text."
    }
    func delete(_ clip: Clip) {
        clips.removeAll { $0.id == clip.id }; removeFromDisk([clip.id]); ensureSelection()
    }
    func clear(includePinned: Bool) {
        let removed = clips.filter { includePinned || !$0.pinned }
        clips.removeAll { includePinned || !$0.pinned }; removeFromDisk(removed.map(\.id)); ensureSelection()
    }
    func prune() {
        guard ready else { return }
        let retained = HistoryPolicy.retained(clips, days: retentionDays, limit: historyLimit, maxBytes: 250 * 1024 * 1024)
        let ids = Set(retained.map(\.id)); let removed = clips.filter { !ids.contains($0.id) }.map(\.id)
        if clips.map(\.id) != retained.map(\.id) {
            clips = retained; fingerprints = fingerprints.filter { ids.contains($0.key) }; ensureSelection()
        }
        removeFromDisk(removed)
    }
    private func persist(_ clip: Clip) {
        guard !demo, let vault else { return }
        diskQueue.async { [weak self] in
            do { try vault.save(clip) }
            catch { DispatchQueue.main.async { self?.error = "History could not be saved: \(error.localizedDescription)"; self?.paused = true } }
        }
    }
    private func removeFromDisk(_ ids: [UUID]) {
        guard !demo, let vault, !ids.isEmpty else { return }
        diskQueue.async { [weak self] in
            do { for id in ids { try vault.delete(id) } }
            catch { DispatchQueue.main.async { self?.error = "Some history could not be deleted: \(error.localizedDescription)" } }
        }
    }
    func flush() { diskQueue.sync {} }
    func restore(_ clip: Clip, plain: Bool = false) -> Bool {
        let success = PasteboardCodec.restore(clip, to: .general, plain: plain)
        lastChange = NSPasteboard.general.changeCount
        if !success { error = "This clip could not be copied in the requested format." }
        return success
    }

    static func demoClips() -> [Clip] {
        let values: [(String, ClipKind, String, Bool)] = [
            ("Linear", .text, "A little less friction.\nA little more flow.\n\nA quiet place for everything you copy. Find the right words, pick up an idea, and keep moving.", false),
            ("Safari", .link, "https://developer.apple.com/design/human-interface-guidelines", false),
            ("Notes", .text, "The details make the design.\nKeep it useful. Keep it simple.", true),
            ("Finder", .file, "/Users/you/Documents/Brand guidelines.pdf", false),
            ("Xcode", .text, "let ideas = clipboard.history\n    .filter { $0.isWorthKeeping }", false),
            ("Mail", .text, "Thanks for reaching out!\n\nI’ll take a look and get back to you shortly.\n\nBest,", true)
        ]
        return values.enumerated().map { index, v in Clip(createdAt: Date().addingTimeInterval(Double(-index * 840)), source: v.0, kind: v.1, text: v.2, items: [[Representation(type: "public.utf8-plain-text", data: Data(v.2.utf8))]], pinned: v.3) }
    }
}
