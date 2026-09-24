//
//  LogViewerView.swift
//  AppLogger

import SwiftUI

/// Time window options for filtering log entries.
private enum LogTimeWindow: String, CaseIterable, Identifiable {
    case all = "All"
    case last15s = "15s"
    case last30s = "30s"
    case last1m = "1m"
    case last5m = "5m"
    case last15m = "15m"

    var id: String { rawValue }

    var cutoff: Date? {
        switch self {
        case .all: return nil
        case .last15s: return Date().addingTimeInterval(-15)
        case .last30s: return Date().addingTimeInterval(-30)
        case .last1m: return Date().addingTimeInterval(-60)
        case .last5m: return Date().addingTimeInterval(-300)
        case .last15m: return Date().addingTimeInterval(-900)
        }
    }
}

/// A ready-to-use log viewer with search, level/category/time filtering, and auto-scroll.
///
/// Drop this into any project that uses AppLogger:
/// ```swift
/// .sheet(isPresented: $showLogs) {
///     LogViewerView()
/// }
/// ```
///
/// Requires an ``InMemorySink`` to be registered during configuration.
public struct LogViewerView: View {
    @ObservedObject private var logStore: InMemorySink
    @State private var searchText = ""
    @State private var selectedLevel: LogLevel?
    @State private var selectedCategory: String?
    @State private var selectedTimeWindow: LogTimeWindow = .all
    @State private var autoScroll = true
    @State private var showCopiedToast = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    public init(store: InMemorySink? = nil) {
        _logStore = ObservedObject(wrappedValue: store ?? Log.store ?? InMemorySink())
    }

    private var filteredEntries: [LogEntry] {
        logStore.filtered(
            search: searchText,
            level: selectedLevel,
            category: selectedCategory,
            since: selectedTimeWindow.cutoff
        ).reversed()
    }

    private var isCompact: Bool {
        #if os(macOS)
        return false
        #else
        return horizontalSizeClass == .compact
        #endif
    }

    public var body: some View {
        #if os(macOS)
        macOSBody
        #elseif os(tvOS)
        tvOSBody
        #else
        iOSBody
        #endif
    }

    #if os(macOS)
    private var macOSBody: some View {
        VStack(spacing: 0) {
            macOSHeaderBar
            Divider()
            filterBar
            Divider()
            logList
            Divider()
            statusBar
        }
        .overlay(alignment: .top) {
            if showCopiedToast {
                copiedToast
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .frame(minWidth: 500, idealWidth: 700, minHeight: 400, idealHeight: 600)
        .background(Color(.textBackgroundColor))
    }

    private var macOSHeaderBar: some View {
        HStack {
            Text("Logs")
                .font(.headline)

            Spacer()

            Toggle("Auto-scroll", isOn: $autoScroll)
                .toggleStyle(.switch)
                .controlSize(.small)

            Button {
                logStore.clear()
            } label: {
                Label("Clear", systemImage: "trash")
            }
            .controlSize(.small)

            Button {
                copyLogs()
            } label: {
                Label("Copy", systemImage: "doc.on.doc")
            }
            .controlSize(.small)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }
    #endif

    #if os(iOS)
    private var iOSBody: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                Divider()
                logList
                Divider()
                statusBar
            }
            .overlay(alignment: .top) {
                if showCopiedToast {
                    copiedToast
                        .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .background(Color(.systemBackground))
            .navigationTitle("Logs")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        copyLogs()
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }

                    Menu {
                        Toggle("Auto-scroll", isOn: $autoScroll)

                        Divider()

                        Button(role: .destructive) {
                            logStore.clear()
                        } label: {
                            Label("Clear All", systemImage: "trash")
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
    }
    #endif

    #if os(tvOS)
    // No pasteboard on tvOS, so the viewer is read-only with a Clear action.
    private var tvOSBody: some View {
        NavigationStack {
            VStack(spacing: 0) {
                filterBar
                logList
                statusBar
            }
            .navigationTitle("Logs")
            .toolbar {
                Button(role: .destructive) {
                    logStore.clear()
                } label: {
                    Label("Clear All", systemImage: "trash")
                }
            }
        }
    }
    #endif

    // MARK: - Filter Bar

    private var filterBar: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Search logs…", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .background(.quaternary)
            .clipShape(RoundedRectangle(cornerRadius: 8))

            HStack(spacing: 8) {
                Picker("Level", selection: $selectedLevel) {
                    Text("All Levels").tag(LogLevel?.none)
                    Divider()
                    ForEach(LogLevel.allCases) { level in
                        Label(level.label, systemImage: level.icon).tag(LogLevel?.some(level))
                    }
                }
                .fixedSize()

                Picker("Category", selection: $selectedCategory) {
                    Text("All Categories").tag(String?.none)
                    Divider()
                    ForEach(logStore.categories, id: \.self) { cat in
                        Text(cat).tag(String?.some(cat))
                    }
                }
                .fixedSize()

                Picker("Time", selection: $selectedTimeWindow) {
                    ForEach(LogTimeWindow.allCases) { window in
                        Text(window.rawValue).tag(window)
                    }
                }
                .fixedSize()

                Spacer()
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - Log List

    private var logList: some View {
        ScrollViewReader { proxy in
            List(filteredEntries) { entry in
                LogEntryRow(entry: entry, compact: isCompact)
                    .id(entry.id)
                    .listRowInsets(EdgeInsets(top: 2, leading: 8, bottom: 2, trailing: 8))
            }
            .listStyle(.plain)
            .font(.system(.caption, design: .monospaced))
            .onChange(of: filteredEntries.count) { _, _ in
                if autoScroll, let first = filteredEntries.first {
                    proxy.scrollTo(first.id, anchor: .top)
                }
            }
        }
    }

    // MARK: - Status Bar

    private var statusBar: some View {
        HStack {
            Text("\(filteredEntries.count) of \(logStore.entries.count) entries")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            if selectedTimeWindow != .all {
                filterChip("Last \(selectedTimeWindow.rawValue)") { selectedTimeWindow = .all }
            }
            if let level = selectedLevel {
                filterChip(level.label) { selectedLevel = nil }
            }
            if let category = selectedCategory {
                filterChip(category) { selectedCategory = nil }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
    }

    private func filterChip(_ label: String, onRemove: @escaping () -> Void) -> some View {
        HStack(spacing: 2) {
            Text(label)
            Button { onRemove() } label: {
                Image(systemName: "xmark.circle.fill")
            }
            .buttonStyle(.plain)
        }
        .font(.caption)
        .padding(.horizontal, 8)
        .padding(.vertical, 2)
        .background(.quaternary)
        .clipShape(Capsule())
    }

    // MARK: - Copied Toast

    private var copiedToast: some View {
        Text("\(filteredEntries.count) entries copied")
            .font(.caption.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.ultraThinMaterial)
            .clipShape(Capsule())
            .padding(.top, 8)
    }

    // MARK: - Actions

    private func copyLogs() {
        let device = DeviceInfo.current
        let header = """
            ── Device Info ──────────────────────
            \(device.summary)
            ── Logs (\(filteredEntries.count) entries) ──────────
            """

        let logLines = filteredEntries.map { entry in
            let ts = Self.timestampFormatter.string(from: entry.timestamp)
            return "[\(ts)][\(entry.level.label)][\(entry.category)] \(entry.message)"
        }.joined(separator: "\n")

        let text = header + "\n" + logLines

        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #elseif os(iOS) || os(visionOS)
        UIPasteboard.general.string = text
        #endif

        withAnimation(.easeInOut(duration: 0.2)) { showCopiedToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeInOut(duration: 0.2)) { showCopiedToast = false }
        }
    }

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()
}

// MARK: - Log Entry Row

private struct LogEntryRow: View {
    let entry: LogEntry
    let compact: Bool

    private static let timestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm:ss.SSS"
        return f
    }()

    private static let compactTimestampFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "H:mm:ss"
        return f
    }()

    var body: some View {
        if compact {
            compactLayout
        } else {
            wideLayout
        }
    }

    private var wideLayout: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: entry.level.icon)
                .foregroundStyle(levelColor)
                .frame(width: 14)

            Text(Self.timestampFormatter.string(from: entry.timestamp))
                .foregroundStyle(.secondary)
                .frame(width: 80, alignment: .leading)

            Text(entry.category)
                .foregroundStyle(.secondary)
                .frame(width: 60, alignment: .leading)

            Text(entry.message)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                #if !os(tvOS)
                .textSelection(.enabled)
                #endif
        }
    }

    private var compactLayout: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: entry.level.icon)
                    .foregroundStyle(levelColor)
                    .font(.caption2)

                Text(Self.compactTimestampFormatter.string(from: entry.timestamp))
                    .foregroundStyle(.secondary)

                Text(entry.category)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .font(.system(.caption2, design: .monospaced))

            Text(entry.message)
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity, alignment: .leading)
                #if !os(tvOS)
                .textSelection(.enabled)
                #endif
                .font(.system(.caption, design: .monospaced))
        }
    }

    private var levelColor: Color {
        switch entry.level {
        case .debug: return .secondary
        case .info: return .blue
        case .warning: return .orange
        case .error: return .red
        }
    }
}
