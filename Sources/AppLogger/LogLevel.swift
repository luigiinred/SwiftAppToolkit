//
//  LogLevel.swift
//  AppLogger
//

import os.log

/// Severity level for log entries, ordered from least to most severe.
///
/// Use the minimum level setting to control which logs are captured at runtime.
/// In production, setting `.warning` reduces noise while still capturing problems.
public enum LogLevel: Int, Comparable, CaseIterable, Identifiable, Sendable {
    case debug = 0
    case info = 1
    case warning = 2
    case error = 3

    public var id: Int { rawValue }

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    /// Short uppercase label for console output (e.g. "DEBUG", "WARN").
    public var label: String {
        switch self {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .warning: return "WARN"
        case .error: return "ERROR"
        }
    }

    /// Human-readable name for settings UI.
    public var displayName: String {
        switch self {
        case .debug: return "Debug"
        case .info: return "Info"
        case .warning: return "Warning"
        case .error: return "Error"
        }
    }

    /// SF Symbol name for log viewer UI.
    public var icon: String {
        switch self {
        case .debug: return "ant"
        case .info: return "info.circle"
        case .warning: return "exclamationmark.triangle"
        case .error: return "xmark.octagon"
        }
    }

    var osLogType: OSLogType {
        switch self {
        case .debug: return .debug
        case .info: return .info
        case .warning: return .default
        case .error: return .error
        }
    }
}
