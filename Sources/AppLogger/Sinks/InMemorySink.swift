//
//  InMemorySink.swift
//  AppLogger
//

import Foundation

/// Stores log entries and events in memory for display in a log viewer UI.
///
/// This sink is `ObservableObject` so SwiftUI views can bind directly to it:
/// ```swift
/// struct LogViewerView: View {
///     @ObservedObject var store: InMemorySink
///     var body: some View {
///         List(store.entries) { entry in
///             Text(entry.message)
///         }
///     }
/// }
/// ```
///
/// Access it after configuration via ``AppLogger/store``:
/// ```swift
/// let logStore = Log.store  // returns the InMemorySink if one is registered
/// ```
public final class InMemorySink: LogSink, ObservableObject, @unchecked Sendable {
    @Published public private(set) var entries: [LogEntry] = []
    @Published public private(set) var events: [LogEvent] = []

    private let maxEntries: Int

    /// - Parameter maxEntries: Maximum number of entries/events to keep in memory.
    ///   Oldest entries are evicted when the limit is exceeded. Default: 5000.
    public init(maxEntries: Int = 5000) {
        self.maxEntries = maxEntries
    }

    public func receive(entry: LogEntry) {
        let max = maxEntries
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.entries.append(entry)
            if self.entries.count > max {
                self.entries.removeFirst(self.entries.count - max)
            }
        }
    }

    public func receive(event: LogEvent) {
        let max = maxEntries
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.events.append(event)
            if self.events.count > max {
                self.events.removeFirst(self.events.count - max)
            }
        }
    }

    /// Clear all stored entries and events.
    public func clear() {
        DispatchQueue.main.async { [weak self] in
            self?.entries.removeAll()
            self?.events.removeAll()
        }
    }

    /// All unique category strings seen across entries and events, sorted alphabetically.
    public var categories: [String] {
        let entryCats = Set(entries.map(\.category))
        let eventCats = Set(events.compactMap(\.category))
        return entryCats.union(eventCats).sorted()
    }

    /// Filtered entries matching optional search text, level, and category.
    public func filtered(
        search: String = "",
        level: LogLevel? = nil,
        category: String? = nil,
        since: Date? = nil
    ) -> [LogEntry] {
        entries.filter { entry in
            if let since, entry.timestamp < since { return false }
            if let level, entry.level != level { return false }
            if let category, entry.category != category { return false }
            if !search.isEmpty {
                return entry.message.localizedCaseInsensitiveContains(search)
                    || entry.category.localizedCaseInsensitiveContains(search)
                    || entry.level.label.localizedCaseInsensitiveContains(search)
            }
            return true
        }
    }
}
