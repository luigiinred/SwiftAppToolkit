//
//  AppLogger.swift
//  AppLogger
//

import Foundation

/// A thread-safe logger with pluggable sinks, level filtering, and event tracking.
///
/// Configure once at app startup, then use the ``Log`` convenience anywhere:
/// ```swift
/// Log.configure(minimumLevel: .info, sinks: [
///     ConsoleSink(),
///     OSLogSink(subsystem: "com.myapp"),
/// ])
///
/// Log.info("Photo loaded", category: "Photo")
/// Log.event("theme_changed", properties: ["to": "dark"])
/// ```
public final class AppLogger: @unchecked Sendable {
    public static let shared = AppLogger()

    private var sinks: [LogSink] = []
    private var _minimumLevel: LogLevel = .debug
    private let lock = NSLock()

    public init() {}

    // MARK: - Configuration

    /// Set the minimum log level and register sinks.
    /// Call once at app startup. Can be called again to reconfigure.
    public func configure(minimumLevel: LogLevel = .debug, sinks: [LogSink] = []) {
        lock.lock()
        self._minimumLevel = minimumLevel
        self.sinks = sinks
        lock.unlock()
    }

    /// Register an additional sink after initial configuration.
    public func addSink(_ sink: LogSink) {
        lock.lock()
        sinks.append(sink)
        lock.unlock()
    }

    /// The minimum severity for log entries to be captured.
    /// Logs below this level are silently dropped.
    /// Events are always captured regardless of this setting.
    public var minimumLevel: LogLevel {
        get {
            lock.lock()
            defer { lock.unlock() }
            return _minimumLevel
        }
        set {
            lock.lock()
            _minimumLevel = newValue
            lock.unlock()
        }
    }

    /// Returns the first ``InMemorySink`` registered, if any.
    /// Use this to bind a log viewer UI to the in-memory store.
    public var store: InMemorySink? {
        lock.lock()
        defer { lock.unlock() }
        return sinks.compactMap { $0 as? InMemorySink }.first
    }

    // MARK: - Logging

    public func debug(
        _ message: String,
        category: String = "General",
        metadata: Metadata? = nil,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        log(message, level: .debug, category: category, metadata: metadata,
            file: file, function: function, line: line)
    }

    public func info(
        _ message: String,
        category: String = "General",
        metadata: Metadata? = nil,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        log(message, level: .info, category: category, metadata: metadata,
            file: file, function: function, line: line)
    }

    public func warn(
        _ message: String,
        category: String = "General",
        metadata: Metadata? = nil,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        log(message, level: .warning, category: category, metadata: metadata,
            file: file, function: function, line: line)
    }

    public func error(
        _ message: String,
        category: String = "General",
        error: Error? = nil,
        metadata: Metadata? = nil,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        var merged = metadata ?? [:]
        if let error {
            merged["errorDescription"] = .string(error.localizedDescription)
            merged["errorType"] = .string(String(describing: type(of: error)))
            let nsError = error as NSError
            merged["errorDomain"] = .string(nsError.domain)
            merged["errorCode"] = .int(nsError.code)
        }
        log(message, level: .error, category: category, metadata: merged.isEmpty ? nil : merged,
            file: file, function: function, line: line)
    }

    // MARK: - Events

    /// Track a structured event. Events are always captured regardless of minimum level.
    public func event(
        _ name: String,
        category: String? = nil,
        properties: Metadata? = nil,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        let event = LogEvent(
            name: name, category: category, properties: properties,
            file: file, function: function, line: line
        )
        lock.lock()
        let currentSinks = sinks
        lock.unlock()

        for sink in currentSinks {
            sink.receive(event: event)
        }
    }

    // MARK: - Internal

    private func log(
        _ message: String,
        level: LogLevel,
        category: String,
        metadata: Metadata?,
        file: String,
        function: String,
        line: UInt
    ) {
        lock.lock()
        let currentMinimum = _minimumLevel
        let currentSinks = sinks
        lock.unlock()

        guard level >= currentMinimum else { return }

        let entry = LogEntry(
            level: level, category: category, message: message, metadata: metadata,
            file: file, function: function, line: line
        )

        for sink in currentSinks {
            sink.receive(entry: entry)
        }
    }
}

/// Convenience accessor for the shared logger instance.
///
/// ```swift
/// Log.info("Hello world")
/// Log.event("app_launched")
/// ```
public let Log = AppLogger.shared
