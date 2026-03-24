//
//  DeviceInfo.swift
//  AppLogger

import Foundation
#if canImport(UIKit)
import UIKit
#endif

/// Gathers device, platform, and app version metadata for log exports.
public struct DeviceInfo: Sendable {

    /// Set from the app layer to include extra context (e.g. slideshow/widget config)
    /// in copied log output. Called lazily when `summary` is accessed.
    nonisolated(unsafe) public static var additionalInfoProvider: (@Sendable () -> String)?

    public let deviceModel: String
    public let deviceName: String
    public let osName: String
    public let osVersion: String
    public let appName: String
    public let appVersion: String
    public let buildNumber: String
    public let locale: String

    public static var current: DeviceInfo {
        let bundle = Bundle.main
        let appName = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
            ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String
            ?? "Unknown"
        let appVersion = bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let buildNumber = bundle.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"

        let processInfo = ProcessInfo.processInfo

        #if os(iOS) || os(tvOS)
        let device = UIDevice.current
        let deviceModel = device.model
        let deviceName = Self.modelIdentifier
        let osName = device.systemName
        let osVersion = device.systemVersion
        #elseif os(macOS)
        let deviceModel = "Mac"
        let deviceName = Self.modelIdentifier
        let osName = "macOS"
        let osVersion = processInfo.operatingSystemVersionString
        #elseif os(watchOS)
        let deviceModel = "Apple Watch"
        let deviceName = Self.modelIdentifier
        let osName = "watchOS"
        let osVersion = processInfo.operatingSystemVersionString
        #else
        let deviceModel = "Unknown"
        let deviceName = "Unknown"
        let osName = "Unknown"
        let osVersion = processInfo.operatingSystemVersionString
        #endif

        return DeviceInfo(
            deviceModel: deviceModel,
            deviceName: deviceName,
            osName: osName,
            osVersion: osVersion,
            appName: appName,
            appVersion: appVersion,
            buildNumber: buildNumber,
            locale: Locale.current.identifier
        )
    }

    /// Formatted multi-line header suitable for pasting into bug reports.
    public var summary: String {
        var lines = """
        Device: \(deviceModel) (\(deviceName))
        OS: \(osName) \(osVersion)
        App: \(appName) \(appVersion) (\(buildNumber))
        Locale: \(locale)
        """
        if let extra = Self.additionalInfoProvider?() {
            lines += "\n" + extra
        }
        return lines
    }

    // MARK: - Private

    private static var modelIdentifier: String {
        var size = 0
        sysctlbyname("hw.model", nil, &size, nil, 0)
        var model = [CChar](repeating: 0, count: size)
        sysctlbyname("hw.model", &model, &size, nil, 0)
        return String(cString: model)
    }
}
