import AppKit
import CryptoKit
import StashCore

@main struct StashCoreChecks {
    @MainActor static func main() throws {
        let checks = StashCoreChecks()
        try checks.testEncryptedRoundTripPreservesEveryRepresentationAndItem()
        try checks.testWrongKeyAndTamperingFailClosed()
        checks.testRetentionAlwaysKeepsPinsAndNewestWithinBudget()
        checks.testUnlimitedDaysStillHonorsByteBudget()
        checks.testSensitiveMarkersAndExclusions()
        checks.testSearchIsCaseAndDiacriticInsensitiveAndMatchesAllTerms()
        checks.testFingerprintIncludesItemBoundariesAndIsFormatOrderIndependent()
        try checks.testNamedPasteboardRoundTripRichTextAndMultipleFiles()
        try checks.testCaptureFormatsAndPlainTextRestore()
        try checks.testImageCaptureAndRestore()
        try checks.testCaptureRejectsSensitiveExcludedAndOversize()
        try checks.testRestoreFailurePreservesClipboard()
        print("PASS: 12 checks — encryption, tamper rejection, retention, storage budget, privacy, search, fingerprints, rich/multi-file pasteboard round trip")
    }
    func clip(_ text: String = "hello", age: Double = 0, pinned: Bool = false) -> Clip {
        Clip(createdAt: Date().addingTimeInterval(-age * 86400), source: "Safari", kind: .text, text: text, items: [[Representation(type: "public.utf8-plain-text", data: Data(text.utf8))]], pinned: pinned)
    }
    func testEncryptedRoundTripPreservesEveryRepresentationAndItem() throws {
        let original = Clip(source: "Finder", kind: .file, text: "files", items: [
            [Representation(type: "public.file-url", data: Data("file:///tmp/a.txt".utf8)), Representation(type: "public.html", data: Data("<b>Hello</b>".utf8))],
            [Representation(type: "public.file-url", data: Data("file:///tmp/b.txt".utf8)), Representation(type: "public.png", data: Data([0, 1, 255, 4]))]
        ], pinned: true)
        let key = SymmetricKey(size: .bits256)
        let ciphertext = try VaultCodec.seal(original, key: key)
        expectNil(ciphertext.range(of: Data("file:///tmp/a.txt".utf8)))
        let restored = try VaultCodec.open(ciphertext, key: key)
        expectEqual(restored.items, original.items)
        expectEqual(restored.id, original.id)
        expectTrue(restored.pinned)
        expectEqual(restored.fingerprint, original.fingerprint)
    }
    func testWrongKeyAndTamperingFailClosed() throws {
        let key = SymmetricKey(size: .bits256)
        var ciphertext = try VaultCodec.seal(clip(), key: key)
        expectThrows(try VaultCodec.open(ciphertext, key: SymmetricKey(size: .bits256)))
        ciphertext[ciphertext.count / 2] ^= 1
        expectThrows(try VaultCodec.open(ciphertext, key: key))
    }
    func testRetentionAlwaysKeepsPinsAndNewestWithinBudget() {
        let pin = clip("pin", age: 200, pinned: true)
        let expired = clip("expired", age: 31)
        let old = clip("older", age: 2)
        let new = clip("new", age: 1)
        let retained = HistoryPolicy.retained([old, expired, new, pin], days: 30, limit: 2, maxBytes: 100)
        expectEqual(Set(retained.map(\.id)), Set([pin.id, new.id]))
        expectEqual(HistoryPolicy.retained([pin, new], days: 30, limit: 1, maxBytes: 1).map(\.id), [pin.id])
    }
    func testUnlimitedDaysStillHonorsByteBudget() {
        let older = clip("old", age: 900)
        expectEqual(HistoryPolicy.retained([older], days: 0, limit: 10, maxBytes: 3).count, 1)
        expectTrue(HistoryPolicy.retained([older], days: 0, limit: 10, maxBytes: 2).isEmpty)
    }
    func testSensitiveMarkersAndExclusions() {
        for type in HistoryPolicy.sensitiveTypes {
            expectFalse(HistoryPolicy.shouldCapture(types: ["public.utf8-plain-text", type], sourceBundle: "app", excluded: []))
        }
        expectFalse(HistoryPolicy.shouldCapture(types: [], sourceBundle: "COM.APP", excluded: ["com.app"]))
        expectTrue(HistoryPolicy.shouldCapture(types: ["public.html"], sourceBundle: "com.app.other", excluded: ["com.app", ""]))
    }
    func testSearchIsCaseAndDiacriticInsensitiveAndMatchesAllTerms() {
        let entry = clip("Café design notes")
        expectTrue(entry.matches("CAFE safari"))
        expectTrue(entry.matches("   "))
        expectFalse(entry.matches("cafe missing"))
    }
    func testFingerprintIncludesItemBoundariesAndIsFormatOrderIndependent() {
        let a = Representation(type: "a", data: Data([1]))
        let b = Representation(type: "b", data: Data([2]))
        var first = clip(); first.items = [[a, b]]
        var reordered = first; reordered.items = [[b, a]]
        var split = first; split.items = [[a], [b]]
        expectEqual(first.fingerprint, reordered.fingerprint)
        expectNotEqual(first.fingerprint, split.fingerprint)
    }
    @MainActor func testNamedPasteboardRoundTripRichTextAndMultipleFiles() throws {
        let pasteboard = NSPasteboard.withUniqueName()
        defer { pasteboard.releaseGlobally() }
        let first = NSPasteboardItem()
        first.setString("Hello", forType: .string)
        first.setString("<strong>Hello</strong>", forType: .html)
        first.setString("file:///tmp/a.txt", forType: .fileURL)
        let second = NSPasteboardItem(); second.setString("file:///tmp/b.txt", forType: .fileURL)
        expectTrue(pasteboard.writeObjects([first, second]))
        let entry = try unwrap(PasteboardCodec.capture(from: pasteboard, source: "Test", bundle: "test.app"))
        expectEqual(entry.kind, .file)
        expectEqual(entry.text, "/tmp/a.txt\n/tmp/b.txt")
        let key = SymmetricKey(size: .bits256)
        let decoded = try VaultCodec.open(VaultCodec.seal(entry, key: key), key: key)
        expectTrue(PasteboardCodec.restore(decoded, to: pasteboard))
        expectEqual(pasteboard.pasteboardItems?.count, 2)
        expectEqual(pasteboard.pasteboardItems?.first?.string(forType: .html), "<strong>Hello</strong>")
        expectEqual(pasteboard.pasteboardItems?.last?.string(forType: .fileURL), "file:///tmp/b.txt")
    }
    @MainActor func testCaptureFormatsAndPlainTextRestore() throws {
        let pb = NSPasteboard.withUniqueName(); defer { pb.releaseGlobally() }
        let rich = NSPasteboardItem()
        rich.setString("<style>hidden</style><b>Hello</b> &amp; welcome<script>hidden</script>", forType: .html)
        expectTrue(pb.writeObjects([rich]))
        let html = try unwrap(PasteboardCodec.capture(from: pb, source: "Browser", bundle: "browser"))
        expectTrue(html.text.contains("Hello")); expectFalse(html.text.contains("hidden"))
        expectTrue(PasteboardCodec.restore(html, to: pb, plain: true))
        expectEqual(pb.string(forType: .string), html.text)
        expectNil(pb.data(forType: .html))
        // Replayed clips must not loop back into capture.
        expectNil(try PasteboardCodec.capture(from: pb, source: "Test", bundle: "test"))
        pb.clearContents()
        pb.setString("https://example.com/path?q=test", forType: .URL)
        let link = try unwrap(PasteboardCodec.capture(from: pb, source: "Browser", bundle: "browser"))
        expectEqual(link.kind, .link)
        let attributed = NSAttributedString(string: "Rich text sample")
        let rtf = try attributed.data(from: NSRange(location: 0, length: attributed.length), documentAttributes: [.documentType: NSAttributedString.DocumentType.rtf])
        pb.clearContents(); pb.setData(rtf, forType: .rtf)
        let clip = try unwrap(PasteboardCodec.capture(from: pb, source: "Editor", bundle: "editor"))
        expectEqual(clip.text, "Rich text sample")
        expectTrue(PasteboardCodec.restore(clip, to: pb))
        expectEqual(pb.data(forType: .rtf), rtf)
    }
    @MainActor func testImageCaptureAndRestore() throws {
        let pb = NSPasteboard.withUniqueName(); defer { pb.releaseGlobally() }
        let bitmap = try unwrap(NSBitmapImageRep(bitmapDataPlanes: nil, pixelsWide: 2, pixelsHigh: 2, bitsPerSample: 8, samplesPerPixel: 4, hasAlpha: true, isPlanar: false, colorSpaceName: .deviceRGB, bytesPerRow: 0, bitsPerPixel: 0))
        for x in 0..<2 { for y in 0..<2 { bitmap.setColor(NSColor(deviceRed: 1, green: 0, blue: 0, alpha: 1), atX: x, y: y) } }
        let png = try unwrap(bitmap.representation(using: .png, properties: [:]))
        pb.setData(png, forType: .png)
        let entry = try unwrap(PasteboardCodec.capture(from: pb, source: "Screenshot", bundle: "test"))
        expectEqual(entry.kind, .image)
        expectTrue(PasteboardCodec.restore(entry, to: pb))
        expectEqual(pb.data(forType: .png), png)
        let restoredPNG = try unwrap(pb.data(forType: .png))
        expectTrue(NSImage(data: restoredPNG) != nil)
    }
    @MainActor func testCaptureRejectsSensitiveExcludedAndOversize() throws {
        let pb = NSPasteboard.withUniqueName(); defer { pb.releaseGlobally() }
        let plain = NSPasteboardItem(); plain.setString("public text", forType: .string)
        let secret = NSPasteboardItem(); secret.setString("private text", forType: .string)
        secret.setString("1", forType: .init("org.nspasteboard.ConcealedType"))
        expectTrue(pb.writeObjects([plain, secret]))
        expectNil(try PasteboardCodec.capture(from: pb, source: "App", bundle: "test"))
        pb.clearContents(); pb.setString("content", forType: .string)
        expectNil(try PasteboardCodec.capture(from: pb, source: "App", bundle: "excluded", excluded: ["excluded"]))
        expectThrows(try PasteboardCodec.capture(from: pb, source: "App", bundle: "test", maxClipBytes: 1))
    }
    @MainActor func testRestoreFailurePreservesClipboard() throws {
        let pb = NSPasteboard.withUniqueName(); defer { pb.releaseGlobally() }
        pb.setString("keep me", forType: .string)
        let invalid = Clip(source: "Test", kind: .image, text: "", items: [])
        expectFalse(PasteboardCodec.restore(invalid, to: pb))
        expectFalse(PasteboardCodec.restore(invalid, to: pb, plain: true))
        expectEqual(pb.string(forType: .string), "keep me")
    }

}

// Lightweight assertions keep these checks runnable with Command Line Tools alone.
func expectTrue(_ value: @autoclosure () -> Bool, file: StaticString = #file, line: UInt = #line) { precondition(value(), "Expected true", file: file, line: line) }
func expectFalse(_ value: @autoclosure () -> Bool, file: StaticString = #file, line: UInt = #line) { precondition(!value(), "Expected false", file: file, line: line) }
func expectEqual<T: Equatable>(_ a: T, _ b: T, file: StaticString = #file, line: UInt = #line) { precondition(a == b, "Values differ", file: file, line: line) }
func expectNotEqual<T: Equatable>(_ a: T, _ b: T, file: StaticString = #file, line: UInt = #line) { precondition(a != b, "Values should differ", file: file, line: line) }
func expectNil<T>(_ value: T?, file: StaticString = #file, line: UInt = #line) { precondition(value == nil, "Expected nil", file: file, line: line) }
func expectThrows<T>(_ value: @autoclosure () throws -> T, file: StaticString = #file, line: UInt = #line) {
    do { _ = try value() } catch { return }
    preconditionFailure("Expected an error", file: file, line: line)
}
func unwrap<T>(_ value: T?) throws -> T {
    guard let value else { throw CocoaError(.coderValueNotFound) }; return value
}
