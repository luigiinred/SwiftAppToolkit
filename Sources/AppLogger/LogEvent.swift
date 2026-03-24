//
//  LogEvent.swift
//  AppLogger
//

import Foundation

/// A structured event representing a discrete occurrence in the app.
///
/// Events differ from log messages: they represent user actions or state changes
/// that you want to track as a timeline. They are always captured regardless of
/// the minimum log level, making them reliable breadcrumbs for crash investigation.
///
/// ```swift
/// Log.event("theme_changed", properties: ["from": "fullscreen", "to": "mosaic"])
/// Log.event("photo_loaded", category: "Photo", properties: ["source": "icloud", "loadTime": 1.2])
/// ```
public struct LogEvent: Identifiable, Sendable {
    public let id: UUID
    public let timestamp: Date
    public let name: String
    public let category: String?
    public let properties: Metadata?
    public let file: String
    public let function: String
    public let line: UInt

    public init(
        name: String,
        category: String? = nil,
        properties: Metadata? = nil,
        file: String = #file,
        function: String = #function,
        line: UInt = #line
    ) {
        self.id = UUID()
        self.timestamp = Date()
        self.name = name
        self.category = category
        self.properties = properties
        self.file = file
        self.function = function
        self.line = line
    }

    /// The source filename without the full path.
    public var fileName: String {
        (file as NSString).lastPathComponent
    }
}
