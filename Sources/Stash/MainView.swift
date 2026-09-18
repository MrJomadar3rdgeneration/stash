import SwiftUI
import AppKit
import StashCore

// Explicit property-wrapper alias also builds with SDKs that expose the new State macro.
typealias ViewState<Value> = SwiftUI.State<Value>

let accent = Color(red: 0.60, green: 0.87, blue: 0.73)
let muted = Color(red: 0.53, green: 0.58, blue: 0.58)
let canvas = Color(red: 0.075, green: 0.09, blue: 0.10)

struct MainView: View {
    @ObservedObject var store: HistoryStore
    let delegate: AppDelegate
    @FocusState private var searchFocused: Bool
    @ViewState private var clearConfirmation = false
    @ViewState private var includePinned = false
    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                sidebar.frame(width: 178)
                Divider().overlay(Color.white.opacity(0.04))
                VStack(spacing: 0) {
                    searchBar
                    HStack(spacing: 0) {
                        clipList.frame(width: 340)
                        Divider().overlay(Color.white.opacity(0.04))
                        if let clip = store.selected { ClipDetail(clip: clip, store: store, delegate: delegate).id(clip.id) }
                        else { emptyDetail.frame(maxWidth: .infinity, maxHeight: .infinity) }
                    }
                }
            }
            footer
        }
        .background(canvas).preferredColorScheme(.dark)
        .sheet(isPresented: $store.settingsOpen) { SettingsView(store: store, delegate: delegate) }
        .alert("Clear clipboard history?", isPresented: $clearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button(includePinned ? "Delete everything" : "Clear unpinned history", role: .destructive) { store.clear(includePinned: includePinned) }
        } message: { Text(includePinned ? "All saved clips, including pinned items, will be deleted from Stash. This cannot be undone." : "Unpinned clips will be deleted. Pinned clips stay. This cannot be undone. The system clipboard is unchanged.") }
        .onChange(of: store.query) { _, _ in store.ensureSelection() }
        .onChange(of: store.filter) { _, _ in store.ensureSelection() }
        .onReceive(NotificationCenter.default.publisher(for: .init("StashFocusSearch"))) { _ in searchFocused = true }
        .onAppear { searchFocused = true }
    }
    private var sidebar: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 9) {
                Image(systemName: "square.on.square.fill").foregroundStyle(accent).font(.system(size: 22, weight: .medium))
                Text("stash").font(.system(size: 26, weight: .semibold, design: .rounded)).tracking(-1)
            }.padding(.top, 44).padding(.bottom, 7)
            Text("A little more flow.").font(.system(size: 11)).foregroundStyle(muted).padding(.bottom, 38)
            Text("LIBRARY").font(.system(size: 9, weight: .semibold)).tracking(1.7).foregroundStyle(muted).padding(.bottom, 13)
            nav("All clips", "square.stack", count: store.clips.count)
            nav("Pinned", "pin", count: store.clips.filter(\.pinned).count)
            Text("FORMATS").font(.system(size: 9, weight: .semibold)).tracking(1.7).foregroundStyle(muted).padding(.top, 31).padding(.bottom, 13)
            ForEach(ClipKind.allCases, id: \.self) { kind in nav(kind.title, kind.symbol) }
            Spacer()
            if store.demo { Text("DEMO · SAMPLE CLIPS").font(.system(size: 8, weight: .bold)).foregroundStyle(accent).padding(.bottom, 12) }
            Button { store.paused.toggle() } label: {
                Label(store.paused ? "Resume capture" : "Pause capture", systemImage: store.paused ? "play.circle" : "pause.circle")
                    .frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 9).contentShape(Rectangle())
            }.buttonStyle(.plain).foregroundStyle(muted).font(.system(size: 12)).padding(.bottom, 20)
            Button { store.settingsOpen = true } label: { Label("Settings", systemImage: "slider.horizontal.3").frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 9).contentShape(Rectangle()) }
                .buttonStyle(.plain).foregroundStyle(muted).font(.system(size: 12)).padding(.bottom, 24)
        }.padding(.horizontal, 18).background(Color.white.opacity(0.014))
    }
    private func nav(_ title: String, _ symbol: String, count: Int? = nil) -> some View {
        Button { store.filter = title } label: {
            HStack(spacing: 10) {
                Image(systemName: symbol).frame(width: 15)
                Text(title)
                Spacer()
                if let count { Text("\(count)").font(.system(size: 10, design: .monospaced)).opacity(0.7) }
            }.font(.system(size: 12, weight: store.filter == title ? .medium : .regular))
                .foregroundStyle(store.filter == title ? accent : Color.white.opacity(0.65))
                .padding(.horizontal, 10).padding(.vertical, 10)
                .frame(maxWidth: .infinity, minHeight: 36, alignment: .leading)
                .contentShape(Rectangle())
                .background(store.filter == title ? accent.opacity(0.10) : .clear, in: RoundedRectangle(cornerRadius: 7))
        }.buttonStyle(.plain).padding(.horizontal, -8).padding(.bottom, 3)
    }
    private var searchBar: some View {
        HStack(spacing: 12) {
            Image(systemName: "magnifyingglass").font(.system(size: 19)).foregroundStyle(accent)
            TextField("Search your clipboard…", text: $store.query).textFieldStyle(.plain).font(.system(size: 17)).focused($searchFocused)
            if !store.query.isEmpty { Button { store.query = "" } label: { Image(systemName: "xmark.circle.fill") }.buttonStyle(.plain).foregroundStyle(muted) }
            Text("esc").font(.system(size: 10, design: .monospaced)).foregroundStyle(muted).padding(5).overlay(RoundedRectangle(cornerRadius: 4).stroke(.white.opacity(0.12)))
        }.padding(.horizontal, 26).padding(.top, 35).padding(.bottom, 25)
        .background(Color.white.opacity(0.015)).overlay(alignment: .bottom) { Divider() }
    }
    private var clipList: some View {
        VStack(spacing: 0) {
            HStack {
                Text(store.query.isEmpty ? store.filter : "Search results").font(.system(size: 12, weight: .medium))
                Text("\(store.visible.count)").foregroundStyle(muted).font(.system(size: 11))
                Spacer()
                Menu {
                    Button("Clear unpinned history…") { includePinned = false; clearConfirmation = true }
                    Button("Delete all, including pins…", role: .destructive) { includePinned = true; clearConfirmation = true }
                } label: { Image(systemName: "ellipsis") }.menuStyle(.borderlessButton).frame(width: 22)
            }.padding(.horizontal, 20).padding(.vertical, 18)
            if store.visible.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: store.query.isEmpty ? "doc.on.clipboard" : "magnifyingglass").font(.system(size: 26)).foregroundStyle(accent.opacity(0.7))
                    Text(store.query.isEmpty ? "Room for your next idea." : "No matching clips.").font(.system(size: 13, weight: .medium))
                    Text(store.query.isEmpty ? "Copy text, a link, an image, or a file in another app to get started." : "Try another word or format.").font(.system(size: 12)).foregroundStyle(muted).multilineTextAlignment(.center)
                }.padding(30).frame(maxHeight: .infinity)
            } else {
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 7) {
                            ForEach(store.visible) { clip in
                                ClipRow(clip: clip, selected: store.selectedID == clip.id)
                                    .contentShape(Rectangle())
                                    .onTapGesture { store.selectedID = clip.id }
                                    .contextMenu {
                                        Button("Copy") { delegate.use(clip) }
                                        Button(clip.pinned ? "Unpin" : "Pin") { store.pin(clip) }
                                        Button("Delete", role: .destructive) { store.delete(clip) }
                                    }.id(clip.id)
                            }
                        }.padding(.horizontal, 11).padding(.bottom, 14)
                    }.onChange(of: store.selectedID) { _, id in if let id { withAnimation(.easeOut(duration: 0.12)) { proxy.scrollTo(id) } } }
                }
            }
        }
    }
    private var emptyDetail: some View {
        VStack(spacing: 16) {
            Image(systemName: "square.on.square").font(.system(size: 44, weight: .ultraLight)).foregroundStyle(accent.opacity(0.6))
            Text("Everything you copy.\nRight where you need it.").font(.system(size: 22, weight: .medium, design: .rounded)).multilineTextAlignment(.center)
            Text("Private by default. Ready when you are.").font(.system(size: 12)).foregroundStyle(muted)
        }.padding(24)
    }
    private var footer: some View {
        VStack(spacing: 0) {
            if let error = store.error {
                HStack { Image(systemName: "exclamationmark.triangle"); Text(error).textSelection(.enabled); Spacer(); Button("Dismiss") { store.error = nil } }
                    .font(.system(size: 11)).foregroundStyle(.orange).padding(10).background(.orange.opacity(0.07))
            }
            if let notice = store.notice {
                HStack { Text(notice); Spacer(); Button { store.notice = nil } label: { Image(systemName: "xmark") }.buttonStyle(.plain) }.font(.system(size: 11)).foregroundStyle(accent).padding(10).background(accent.opacity(0.06))
            }
            HStack(spacing: 8) {
                Circle().fill(store.paused || !store.ready ? Color.orange : accent).frame(width: 5, height: 5)
                Text(store.demo ? "Demo mode" : (!store.ready ? "Vault unavailable" : (store.paused ? "Capture paused" : "Stored only on this Mac")))
                Spacer()
                Text("↑ ↓  navigate"); Text("↵  \(store.directPaste ? "paste" : "copy")").padding(.leading, 12); Text("⌘ P  pin").padding(.leading, 12)
            }.font(.system(size: 10)).foregroundStyle(muted).padding(.horizontal, 20).padding(.vertical, 13).overlay(alignment: .top) { Divider() }
        }
    }
}
struct ClipRow: View {
    let clip: Clip
    let selected: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 7) {
                Image(systemName: clip.kind.symbol).foregroundStyle(selected ? accent : muted)
                Text(clip.source).foregroundStyle(muted)
                Spacer()
                if clip.pinned { Image(systemName: "pin.fill").foregroundStyle(accent).font(.system(size: 9)) }
                Text(clip.lastCopiedAt.formatted(.relative(presentation: .numeric, unitsStyle: .abbreviated))).foregroundStyle(muted.opacity(0.8))
            }.font(.system(size: 10))
            Text(clip.title).font(.system(size: 13, weight: .medium)).lineLimit(2).lineSpacing(4).foregroundStyle(.white.opacity(0.88)).frame(maxWidth: .infinity, alignment: .leading)
            Text(clip.kind.title.uppercased()).font(.system(size: 8, weight: .medium)).tracking(1.1).foregroundStyle(selected ? accent.opacity(0.85) : muted.opacity(0.7))
        }.padding(14).frame(maxWidth: .infinity, alignment: .leading)
            .background(selected ? accent.opacity(0.075) : Color.white.opacity(0.018), in: RoundedRectangle(cornerRadius: 9))
            .overlay(RoundedRectangle(cornerRadius: 9).stroke(selected ? accent.opacity(0.35) : Color.white.opacity(0.045), lineWidth: 1))
            .accessibilityElement(children: .combine).accessibilityAddTraits(selected ? [.isSelected, .isButton] : .isButton)
    }
}
struct ClipDetail: View {
    let clip: Clip
    @ObservedObject var store: HistoryStore
    let delegate: AppDelegate
    @ViewState private var draft = ""
    @ViewState private var editMode = false
    private var image: NSImage? {
        for rep in clip.items.flatMap({ $0 }) where ["public.png", "public.tiff"].contains(rep.type) {
            if let image = NSImage(data: rep.data) { return image }
        }
        return nil
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("PREVIEW").font(.system(size: 9, weight: .semibold)).tracking(1.8).foregroundStyle(muted)
                Spacer()
                Button { store.pin(clip) } label: { Image(systemName: clip.pinned ? "pin.fill" : "pin") }.help("Pin clip · ⌘P").foregroundStyle(clip.pinned ? accent : muted)
                Button { store.delete(clip) } label: { Image(systemName: "trash") }.help("Delete clip · ⌘⌫").foregroundStyle(muted).padding(.leading, 12)
            }.buttonStyle(.plain).padding(.bottom, 30)
            HStack(spacing: 10) {
                Image(systemName: clip.kind.symbol).font(.system(size: 19)).foregroundStyle(accent).frame(width: 40, height: 40).background(accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 10))
                VStack(alignment: .leading, spacing: 4) {
                    Text(clip.kind == .text ? "Text snippet" : (clip.kind == .link ? "Saved link" : clip.kind == .image ? "Image" : "File reference")).font(.system(size: 16, weight: .medium))
                    Text("Copied from \(clip.source)").font(.system(size: 11)).foregroundStyle(muted)
                }
            }.padding(.bottom, 25)
            if editMode {
                TextEditor(text: $draft).font(.system(size: 14)).scrollContentBackground(.hidden).padding(12).background(.white.opacity(0.035), in: RoundedRectangle(cornerRadius: 10))
                Text("Editing saves this clip as plain text.").font(.system(size: 10)).foregroundStyle(muted).padding(.top, 8)
                HStack { Button("Cancel") { endEditing() }; Spacer(); Button("Save changes") { store.edit(clip, text: draft); endEditing() }.tint(accent) }.padding(.top, 12)
            } else {
                ScrollView {
                    if clip.kind == .image, let image {
                        Image(nsImage: image).resizable().scaledToFit().clipShape(RoundedRectangle(cornerRadius: 8))
                    } else {
                        Text(clip.text.isEmpty ? "This clip contains binary data. Copy it to restore its original formats." : clip.text)
                            .font(.system(size: 15, design: clip.text.contains("let ") ? .monospaced : .default)).lineSpacing(8).textSelection(.enabled)
                            .foregroundStyle(.white.opacity(0.88)).frame(maxWidth: .infinity, alignment: .leading)
                    }
                }.padding(20).frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .background(Color.white.opacity(0.028), in: RoundedRectangle(cornerRadius: 11))
                    .overlay(RoundedRectangle(cornerRadius: 11).stroke(.white.opacity(0.055)))
                HStack {
                    Text(clip.lastCopiedAt.formatted(date: .abbreviated, time: .shortened))
                    Spacer()
                    Text(ByteCountFormatter.string(fromByteCount: Int64(clip.byteCount), countStyle: .file))
                }.font(.system(size: 10)).foregroundStyle(muted).padding(.top, 15)
                if clip.kind == .file { Text("Files stay in their original location. Moving or deleting them may break pasting.").font(.system(size: 10)).foregroundStyle(muted).padding(.top, 10) }
                HStack(spacing: 12) {
                    if clip.kind == .text || clip.kind == .link {
                        Button { draft = clip.text; editMode = true; store.editing = true } label: { Label("Edit", systemImage: "pencil") }.buttonStyle(.plain).foregroundStyle(muted)
                    }
                    Spacer()
                    Button { delegate.use(clip) } label: {
                        HStack(spacing: 18) { Text(store.directPaste ? "Paste clip" : "Copy clip").fontWeight(.semibold); Text("↵").opacity(0.55) }.padding(.horizontal, 16).padding(.vertical, 11)
                            .foregroundStyle(canvas).background(accent, in: RoundedRectangle(cornerRadius: 7))
                    }.buttonStyle(.plain)
                }.font(.system(size: 12)).padding(.top, 27)
            }
        }.padding(26).frame(maxWidth: .infinity, maxHeight: .infinity).onDisappear { store.editing = false }
    }
    private func endEditing() { editMode = false; store.editing = false }
}
