# SwiftAppToolkit

Shared Swift libraries for app infrastructure. Two independent modules, zero external dependencies.

## Modules

| Module | Purpose |
|--------|---------|
| **AppLogger** | Thread-safe logging with pluggable sinks, structured events, and a built-in log viewer UI |
| **FeatureFlags** | UserDefaults-backed feature flag store with registration, toggling, and a settings viewer UI |

## Installation

Add to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/luigiinred/SwiftAppToolkit.git", from: "1.0.0"),
],
targets: [
    .target(name: "YourTarget", dependencies: [
        .product(name: "AppLogger", package: "SwiftAppToolkit"),
        .product(name: "FeatureFlags", package: "SwiftAppToolkit"),
    ]),
]
```

Or add via Xcode: File > Add Package Dependencies, paste the URL above.

## AppLogger

```swift
import AppLogger

// Configure once at startup
Log.configure(minimumLevel: .info, sinks: [
    OSLogSink(subsystem: "com.myapp"),
    InMemorySink(),
])

// Log anywhere
Log.info("Photo loaded", category: "Photo", metadata: ["loadTime": 1.2])
Log.error("Request failed", category: "Network", error: someError)

// Track events (always captured regardless of minimum level)
Log.event("theme_changed", properties: ["to": "dark"])

// Show the built-in log viewer
LogViewerView()
```

## FeatureFlags

```swift
import FeatureFlags

// Register flags at startup
Flags.register([
    FeatureFlag(key: "new_editor", name: "New Editor", category: "UI", status: .testable),
    FeatureFlag(key: "dark_mode", name: "Dark Mode", category: "UI", status: .stable, defaultValue: true),
])

// Check flags anywhere
if Flags.isEnabled("new_editor") { ... }

// Show the built-in settings viewer
FeatureFlagViewerView()
```

## Platforms

- iOS 17+
- macOS 14+

## License

MIT
