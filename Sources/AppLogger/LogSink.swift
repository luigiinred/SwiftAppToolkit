//
//  LogSink.swift
//  AppLogger
//

/// A destination that receives log entries and events.
///
/// Implement this protocol to send logs wherever you need: Sentry, a file,
/// a remote server, or a custom UI. Sinks must be thread-safe — they may
/// be called from any thread or queue.
///
/// ```swift
/// final class MySentrySink: LogSink {
///     func receive(entry: LogEntry) {
///         SentrySDK.addBreadcrumb(...)
///     }
///     func receive(event: LogEvent) {
///         SentrySDK.addBreadcrumb(...)
///     }
/// }
/// ```
public protocol LogSink: AnyObject {
    func receive(entry: LogEntry)
    func receive(event: LogEvent)
}
