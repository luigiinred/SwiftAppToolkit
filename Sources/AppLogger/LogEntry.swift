//
//  LogEntry.swift
//  AppLogger
//

import Foundation

/// A single log message with level, category, and optional metadata.
///
/// Entries capture the source location automatically so you can trace
/// log messages back to exact file and line in production crash reports.
public struct LogEntry: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let level: LogLevel
    public let category: String
    public let message: String
    public let metadata: Metadata?
    public let file: String
    public let function: String
    public let line: UInt

    public init(
        level: LogLevel,
        category: String,
        message: String,
        metadata: Metadata? = nil,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.level = level
        self.category = category
        self.message = message
        self.metadata = metadata
        self.file = file
        self.function = function
        self.line = line
    }

    /// The source filename without the full path (e.g. "PhotoService.swift").
    public var fileName: String {
        (file as NSString).lastPathComponent
    }
}
