//
//  FeatureFlag.swift
//  FeatureFlags
//

import Foundation

/// The maturity level of a feature flag, matching Apple's convention.
public enum FeatureFlagStatus: String, Sendable, CaseIterable, Identifiable, Comparable {
    case preview = "Preview"
    case testable = "Testable"
    case stable = "Stable"

    public var id: String { rawValue }

    public static func < (lhs: FeatureFlagStatus, rhs: FeatureFlagStatus) -> Bool {
        lhs.sortOrder < rhs.sortOrder
    }

    private var sortOrder: Int {
        switch self {
        case .stable: return 0
        case .testable: return 1
        case .preview: return 2
        }
    }
}

/// A registered feature flag with metadata and a default value.
public struct FeatureFlag: Identifiable, Sendable {
    public let key: String
    public let name: String
    public let category: String
    public let status: FeatureFlagStatus
    public let defaultValue: Bool

    public var id: String { key }

    public init(
        key: String,
        name: String,
        category: String,
        status: FeatureFlagStatus = .stable,
        defaultValue: Bool = false
    ) {
        self.key = key
        self.name = name
        self.category = category
        self.status = status
        self.defaultValue = defaultValue
    }
}
