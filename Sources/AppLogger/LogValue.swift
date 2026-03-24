//
//  LogValue.swift
//  AppLogger
//

import Foundation

/// A type-safe value for log metadata and event properties.
///
/// Supports string, integer, floating-point, and boolean values.
/// Conforms to literal protocols so you can write metadata naturally:
/// ```swift
/// Log.info("Loaded", metadata: ["count": 5, "source": "cache", "duration": 1.2])
/// ```
public enum LogValue: Sendable, Equatable, CustomStringConvertible {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)

    public var description: String {
        switch self {
        case .string(let v): return v
        case .int(let v): return String(v)
        case .double(let v): return String(v)
        case .bool(let v): return String(v)
        }
    }

    /// Returns the underlying value as a String, suitable for serialization.
    public var stringValue: String { description }
}

/// Metadata dictionary for log entries and events.
public typealias Metadata = [String: LogValue]

// MARK: - Literal Conformances

extension LogValue: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) { self = .string(value) }
}

extension LogValue: ExpressibleByStringInterpolation {
    public init(stringInterpolation value: DefaultStringInterpolation) {
        self = .string(String(stringInterpolation: value))
    }
}

extension LogValue: ExpressibleByIntegerLiteral {
    public init(integerLiteral value: Int) { self = .int(value) }
}

extension LogValue: ExpressibleByFloatLiteral {
    public init(floatLiteral value: Double) { self = .double(value) }
}

extension LogValue: ExpressibleByBooleanLiteral {
    public init(booleanLiteral value: Bool) { self = .bool(value) }
}
