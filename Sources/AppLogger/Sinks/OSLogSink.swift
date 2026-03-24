//
//  OSLogSink.swift
//  AppLogger
//

import Foundation
import os.log

/// Writes log entries to Apple's unified logging system (`os.log`).
///
/// Logs are visible in Console.app, Xcode's debug console, and are included
/// in sysdiagnose bundles — making this the best sink for production debugging.
///
/// ```swift
/// Log.configure(sinks: [OSLogSink(subsystem: "com.myapp")])
/// ```
public final class OSLogSink: LogSink, @unchecked Sendable {
    private let logger: os.Logger

    /// - Parameter subsystem: Your app's bundle identifier (e.g. "com.myapp").
    public init(subsystem: String) {
        self.logger = os.Logger(subsystem: subsystem, category: "app")
    }

    public func receive(entry: LogEntry) {
        let meta = formatMetadata(entry.metadata)
        let msg = meta.isEmpty
            ? "[\(entry.category)] \(entry.message)"
            : "[\(entry.category)] \(entry.message) | \(meta)"
        logger.log(level: entry.level.osLogType, "\(msg, privacy: .public)")
    }

    public func receive(event: LogEvent) {
        let props = formatMetadata(event.properties)
        let cat = event.category.map { "[\($0)] " } ?? ""
        let msg = props.isEmpty
            ? "\(cat)event: \(event.name)"
            : "\(cat)event: \(event.name) | \(props)"
        logger.log(level: .info, "\(msg, privacy: .public)")
    }

    private func formatMetadata(_ metadata: Metadata?) -> String {
        guard let metadata, !metadata.isEmpty else { return "" }
        return metadata.sorted(by: { $0.key < $1.key })
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: " ")
    }
}
