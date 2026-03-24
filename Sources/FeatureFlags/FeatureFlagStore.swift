//
//  FeatureFlagStore.swift
//  FeatureFlags
//

import Foundation

/// A thread-safe, UserDefaults-backed feature flag store with observable state.
///
/// Register flags once at app startup, then check them anywhere:
/// ```swift
/// Flags.register([
///     FeatureFlag(key: "dark_mode", name: "Dark Mode", category: "UI", status: .stable, defaultValue: true),
///     FeatureFlag(key: "new_editor", name: "New Editor", category: "UI", status: .testable),
/// ])
///
/// if Flags.isEnabled("dark_mode") { ... }
/// ```
public final class FeatureFlagStore: ObservableObject, @unchecked Sendable {
    public static let shared = FeatureFlagStore()

    private let lock = NSLock()
    private var _flags: [String: FeatureFlag] = [:]
    private var _overrides: [String: Bool] = [:]
    private let defaults: UserDefaults
    private let prefix: String

    @Published public private(set) var registeredFlags: [FeatureFlag] = []

    /// - Parameters:
    ///   - defaults: The `UserDefaults` suite to persist overrides. Default: `.standard`.
    ///   - prefix: A key prefix to namespace stored values. Default: `"ff_"`.
    public init(defaults: UserDefaults = .standard, prefix: String = "ff_") {
        self.defaults = defaults
        self.prefix = prefix
    }

    // MARK: - Registration

    /// Register one or more feature flags. Flags with duplicate keys are silently skipped.
    public func register(_ flags: [FeatureFlag]) {
        lock.lock()
        for flag in flags where _flags[flag.key] == nil {
            _flags[flag.key] = flag
            if let stored = defaults.object(forKey: storageKey(flag.key)) as? Bool {
                _overrides[flag.key] = stored
            }
        }
        let snapshot = sortedFlags()
        lock.unlock()

        DispatchQueue.main.async { [weak self] in
            self?.registeredFlags = snapshot
        }
    }

    /// Register a single feature flag.
    public func register(_ flag: FeatureFlag) {
        register([flag])
    }

    // MARK: - Querying

    /// Whether a flag is enabled. Returns `defaultValue` if no override exists.
    /// Returns `false` for unknown keys.
    public func isEnabled(_ key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        if let override = _overrides[key] { return override }
        return _flags[key]?.defaultValue ?? false
    }

    /// Whether a flag has been overridden from its default.
    public func isOverridden(_ key: String) -> Bool {
        lock.lock()
        defer { lock.unlock() }
        return _overrides[key] != nil
    }

    // MARK: - Toggling

    /// Set a flag to a specific value, persisting to UserDefaults.
    public func setEnabled(_ key: String, _ value: Bool) {
        lock.lock()
        _overrides[key] = value
        defaults.set(value, forKey: storageKey(key))
        let snapshot = sortedFlags()
        lock.unlock()

        DispatchQueue.main.async { [weak self] in
            self?.registeredFlags = snapshot
        }
    }

    /// Toggle a flag's current value.
    public func toggle(_ key: String) {
        setEnabled(key, !isEnabled(key))
    }

    /// Remove the override for a flag, reverting to its default value.
    public func resetFlag(_ key: String) {
        lock.lock()
        _overrides.removeValue(forKey: key)
        defaults.removeObject(forKey: storageKey(key))
        let snapshot = sortedFlags()
        lock.unlock()

        DispatchQueue.main.async { [weak self] in
            self?.registeredFlags = snapshot
        }
    }

    /// Remove all overrides, reverting every flag to its default.
    public func resetAll() {
        lock.lock()
        for key in _overrides.keys {
            defaults.removeObject(forKey: storageKey(key))
        }
        _overrides.removeAll()
        let snapshot = sortedFlags()
        lock.unlock()

        DispatchQueue.main.async { [weak self] in
            self?.registeredFlags = snapshot
        }
    }

    /// The number of flags that have been overridden from their defaults.
    public var overrideCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return _overrides.count
    }

    // MARK: - Grouped Access

    /// All unique category names, sorted alphabetically.
    public var categories: [String] {
        lock.lock()
        defer { lock.unlock() }
        return Array(Set(_flags.values.map(\.category))).sorted()
    }

    /// Flags grouped by category, each group sorted by name.
    public func flagsByCategory() -> [(category: String, flags: [FeatureFlag])] {
        lock.lock()
        let allFlags = Array(_flags.values)
        lock.unlock()

        let grouped = Dictionary(grouping: allFlags, by: \.category)
        return grouped
            .sorted { $0.key < $1.key }
            .map { (category: $0.key, flags: $0.value.sorted { $0.name < $1.name }) }
    }

    // MARK: - Private

    private func storageKey(_ flagKey: String) -> String {
        "\(prefix)\(flagKey)"
    }

    private func sortedFlags() -> [FeatureFlag] {
        Array(_flags.values).sorted { $0.name < $1.name }
    }
}

/// Convenience accessor for the shared feature flag store.
///
/// ```swift
/// Flags.register(...)
/// if Flags.isEnabled("my_flag") { ... }
/// ```
public let Flags = FeatureFlagStore.shared
