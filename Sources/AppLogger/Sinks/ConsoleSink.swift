//
//  ConsoleSink.swift
//  AppLogger
//

import Foundation

/// Prints log entries and events to stdout using `print()`.
///
/// Best for debug builds. In production, prefer ``OSLogSink`` which writes
/// to Apple's unified logging system (visible in Console.app and crash logs).
///
/// ```swift
/// Log.configure(sinks: [ConsoleSink()])
/// ```
public final class ConsoleSink: LogSink, @unchecked Sendable {
    private let formatter: DateFormatter

    public init() {
        formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
    }

    public func receive(entry: LogEntry) {
        let ts = formatter.string(from: entry.timestamp)
        let level = entry.level.label.padding(toLength: 5, withPad: " ", startingAt: 0)
        var line = "[\(ts)] \(level) [\(entry.category)] \(entry.message)"
        if let metadata = entry.metadata, !metadata.isEmpty {
            let pairs = metadata.sorted(by: { $0.key < $1.key })
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: " ")
            line += " | \(pairs)"
        }
        print(line)
    }

    public func receive(event: LogEvent) {
        let ts = formatter.string(from: event.timestamp)
        var line = "[\(ts)] EVENT"
        if let cat = event.category { line += " [\(cat)]" }
        line += " \(event.name)"
        if let props = event.properties, !props.isEmpty {
            let pairs = props.sorted(by: { $0.key < $1.key })
                .map { "\($0.key)=\($0.value)" }
                .joined(separator: " ")
            line += " | \(pairs)"
        }
        print(line)
    }
}
