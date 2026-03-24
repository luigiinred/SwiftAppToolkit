//
//  FeatureFlagViewerView.swift
//  FeatureFlags
//

import SwiftUI

/// A settings-style feature flag viewer with search, categories, and toggle controls.
///
/// Drop this into any project that uses FeatureFlags:
/// ```swift
/// // In a settings window / tab:
/// FeatureFlagViewerView()
///
/// // Or with a custom store:
/// FeatureFlagViewerView(store: myStore)
/// ```
public struct FeatureFlagViewerView: View {
    @ObservedObject private var store: FeatureFlagStore
    @State private var searchText = ""

    public init(store: FeatureFlagStore? = nil) {
        _store = ObservedObject(wrappedValue: store ?? Flags)
    }

    private var groupedFlags: [(category: String, flags: [FeatureFlag])] {
        let groups = store.flagsByCategory()
        guard !searchText.isEmpty else { return groups }

        return groups.compactMap { group in
            let filtered = group.flags.filter {
                $0.name.localizedCaseInsensitiveContains(searchText)
                    || $0.key.localizedCaseInsensitiveContains(searchText)
            }
            return filtered.isEmpty ? nil : (category: group.category, flags: filtered)
        }
    }

    public var body: some View {
        VStack(spacing: 0) {
            flagList
            Divider()
            bottomBar
        }
    }

    // MARK: - Flag List

    private var flagList: some View {
        List {
            ForEach(groupedFlags, id: \.category) { group in
                Section(group.category) {
                    ForEach(group.flags) { flag in
                        FlagRow(
                            flag: flag,
                            isEnabled: store.isEnabled(flag.key),
                            isOverridden: store.isOverridden(flag.key),
                            onToggle: { store.toggle(flag.key) },
                            onReset: { store.resetFlag(flag.key) }
                        )
                    }
                }
            }
        }
        .searchable(text: $searchText, placement: .toolbar, prompt: "Search")
        .overlay {
            if !searchText.isEmpty && groupedFlags.isEmpty {
                ContentUnavailableView.search(text: searchText)
            }
        }
    }

    // MARK: - Bottom Bar

    private var bottomBar: some View {
        HStack {
            if store.overrideCount > 0 {
                Text("\(store.overrideCount) override\(store.overrideCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Reset Feature Flags") {
                store.resetAll()
            }
            .disabled(store.overrideCount == 0)
            .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Flag Row

private struct FlagRow: View {
    let flag: FeatureFlag
    let isEnabled: Bool
    let isOverridden: Bool
    let onToggle: () -> Void
    let onReset: () -> Void

    var body: some View {
        HStack {
            Toggle(isOn: Binding(get: { isEnabled }, set: { _ in onToggle() })) {
                HStack(spacing: 6) {
                    Text(flag.name)
                    if isOverridden {
                        Image(systemName: "arrow.uturn.backward.circle.fill")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                            .help("Modified from default \u{2014} click to reset")
                            .onTapGesture { onReset() }
                    }
                }
            }
            #if os(macOS)
            .toggleStyle(.checkbox)
            #endif

            Spacer()

            Text(flag.status.rawValue)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview("Feature Flags") {
    let store = FeatureFlagStore(defaults: .init(suiteName: "preview")!, prefix: "prev_")
    let _ = store.register([
        FeatureFlag(key: "dark_mode", name: "Dark Mode", category: "Appearance", status: .stable, defaultValue: true),
        FeatureFlag(key: "accent_colors", name: "Custom Accent Colors", category: "Appearance", status: .testable),
        FeatureFlag(key: "blur_bg", name: "Blur Backgrounds", category: "Appearance", status: .preview),
        FeatureFlag(key: "new_grid", name: "New Photo Grid", category: "Photos", status: .stable, defaultValue: true),
        FeatureFlag(key: "ai_crop", name: "AI Crop Suggestions", category: "Photos", status: .testable),
        FeatureFlag(key: "live_preview", name: "Live Preview", category: "Editor", status: .preview),
        FeatureFlag(key: "batch_export", name: "Batch Export", category: "Export", status: .stable, defaultValue: true),
    ])
    return FeatureFlagViewerView(store: store)
        .frame(width: 560, height: 500)
}
