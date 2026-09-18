import AppKit

public enum CaptureError: Error { case tooLarge }

/// Shared by the live monitor and isolated-pasteboard integration checks.
@MainActor public enum PasteboardCodec {
    public static func capture(from pasteboard: NSPasteboard, source: String, bundle: String, excluded: [String] = [], maxClipBytes: Int = 20 * 1024 * 1024) throws -> Clip? {
        let change = pasteboard.changeCount
        let types = (pasteboard.types ?? []).map(\.rawValue)
        guard HistoryPolicy.shouldCapture(types: types, sourceBundle: bundle, excluded: excluded) else { return nil }
        guard let rawItems = pasteboard.pasteboardItems, !rawItems.isEmpty else { return nil }
        var bytes = 0
        var items: [[Representation]] = []
        for item in rawItems {
            guard HistoryPolicy.shouldCapture(types: item.types.map(\.rawValue), sourceBundle: bundle, excluded: excluded) else { return nil }
            var reps: [Representation] = []
            for type in item.types {
                // File promises need their original provider; never replay stale promises.
                if type.rawValue.lowercased().contains("promise") { continue }
                guard let data = item.data(forType: type) else { continue }
                bytes += data.count
                guard bytes <= maxClipBytes else { throw CaptureError.tooLarge }
                reps.append(Representation(type: type.rawValue, data: data))
            }
            if !reps.isEmpty { items.append(reps) }
        }
        guard pasteboard.changeCount == change, !items.isEmpty else { return nil }
        let fileURLs = rawItems.compactMap { $0.string(forType: .fileURL) }.compactMap(URL.init(string:))
        let hasImage = types.contains(NSPasteboard.PasteboardType.png.rawValue) || types.contains(NSPasteboard.PasteboardType.tiff.rawValue)
        var text = pasteboard.string(forType: .string) ?? pasteboard.string(forType: .URL) ?? ""
        if text.isEmpty, let rtf = pasteboard.data(forType: .rtf), let attributed = NSAttributedString(rtf: rtf, documentAttributes: nil) { text = attributed.string }
        if text.isEmpty, let html = pasteboard.string(forType: .html) {
            // Extract searchable text without rendering HTML or fetching remote resources.
            text = html.replacingOccurrences(of: "(?is)<(script|style)[^>]*>.*?</\\1>", with: "", options: .regularExpression)
                .replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
                .replacingOccurrences(of: "&nbsp;", with: " ").replacingOccurrences(of: "&amp;", with: "&")
                .replacingOccurrences(of: "&lt;", with: "<").replacingOccurrences(of: "&gt;", with: ">")
        }
        let kind: ClipKind
        if !fileURLs.isEmpty { kind = .file; text = fileURLs.map(\.path).joined(separator: "\n") }
        else if hasImage { kind = .image }
        else if let url = URL(string: text.trimmingCharacters(in: .whitespacesAndNewlines)), ["http", "https"].contains(url.scheme?.lowercased() ?? ""), url.host != nil { kind = .link }
        else { kind = .text }
        guard pasteboard.changeCount == change else { return nil }
        return Clip(source: source, sourceBundle: bundle, kind: kind, text: text, items: items)
    }
    @discardableResult public static func restore(_ clip: Clip, to pb: NSPasteboard, plain: Bool = false) -> Bool {
        let items: [NSPasteboardItem]
        if plain {
            guard !clip.text.isEmpty else { return false }
            let item = NSPasteboardItem(); item.setString(clip.text, forType: .string); items = [item]
        } else {
            guard !clip.items.isEmpty, clip.items.allSatisfy({ !$0.isEmpty }) else { return false }
            items = clip.items.map { reps in
                let item = NSPasteboardItem()
                for rep in reps { item.setData(rep.data, forType: .init(rep.type)) }
                return item
            }
        }
        for item in items { item.setString("1", forType: .init("com.stash.restored")) }
        pb.clearContents()
        let success = pb.writeObjects(items)
        return success
    }
}
