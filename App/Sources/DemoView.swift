//
//  AsyncCachedImage
//
//  Copyright © 2025 Jan-Hendrik Damerau.
//  https://github.com/uaremad/AsyncCachedImage
//
//  Licensed under the MIT License
//  Free to use without restrictions. See LICENSE file for full terms.
//

import AsyncCachedImage
import SwiftUI

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - DemoView

/// A demonstration view showcasing the AsyncCachedImage functionality.
///
/// Displays a grid of 348 images loaded from a CDN server, demonstrating:
/// - Parallel image loading without UI blocking
/// - Memory and disk caching
/// - Cache revalidation via ETag/Last-Modified headers
/// - Pull-to-refresh for cache statistics
/// - Cache browser sheet for inspecting cached entries
@MainActor
public struct DemoView: View {
    /// Whether the cache browser sheet is visible.
    @State private var showBrowser = false

    /// Current cache statistics, updated every 2 seconds.
    @State private var cacheInfo: CacheInfo?

    /// Provides the demo image URLs.
    private let imageSource = DemoImageSource()

    /// Timer for periodic cache info refresh.
    private let refreshTimer = Timer.publish(every: 2, on: .main, in: .common).autoconnect()

    public init() {}

    public var body: some View {
        NavigationStack {
            ScrollView {
                imageGrid
            }
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                #if os(iOS)
                settingsToolbarItem
                #endif
                cacheInfoToolbarItem
                browserToolbarItem
            }
            .task {
                await refreshCacheInfo()
            }
            .onReceive(refreshTimer) { _ in
                Task {
                    await refreshCacheInfo()
                }
            }
            .refreshable {
                await handlePullToRefresh()
            }
            .sheet(isPresented: $showBrowser) {
                cacheBrowserSheet
            }
        }
    }

    // MARK: - Subviews

    /// The main image grid displaying all demo images.
    private var imageGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 220))], spacing: 16) {
            ForEach(imageSource.imageURLs, id: \.absoluteString) { url in
                ImageCardView(url: url)
            }
        }
        .padding()
    }

    /// The cache browser sheet content.
    private var cacheBrowserSheet: some View {
        CacheView()
        #if os(macOS)
            .frame(minWidth: 640, minHeight: 480)
        #endif
    }

    // MARK: - Toolbar Items

    /// Toolbar button to open the cache browser.
    private var browserToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button {
                showBrowser = true
            } label: {
                Image(systemName: "list.bullet")
            }
            .accessibilityLabel("Open cache browser")
            .accessibilityHint("Shows all cached images")
        }
    }

    /// Toolbar item displaying cache statistics.
    private var cacheInfoToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            CacheInfoBadge(info: cacheInfo)
        }
    }

    /// Toolbar button to open app settings.
    private var settingsToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                openAppSettings()
            } label: {
                Image(systemName: "gear")
            }
            .accessibilityLabel("Open settings")
            .accessibilityHint("Opens app settings")
        }
    }

    // MARK: - Actions

    /// Refreshes the cache statistics from CacheManager.
    private func refreshCacheInfo() async {
        cacheInfo = await CacheManager.shared.info
    }

    /// Handles pull-to-refresh gesture.
    private func handlePullToRefresh() async {
        #if DEBUG
        print("[DemoView] Pull-to-refresh triggered")
        #endif
        try? await Task.sleep(nanoseconds: 500_000_000)
        await refreshCacheInfo()
    }

    /// Opens the app settings screen.
    private func openAppSettings() {
        #if os(iOS)
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(settingsURL)
        #elseif os(macOS)
        NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
        #endif
    }
}

// MARK: - DemoImageSource

/// Provides demo image URLs for the DemoView.
///
/// Generates URLs for 348 landscape images from the CDN server.
private struct DemoImageSource {
    /// Base URL for the CDN image server.
    private let baseURL = "https://cdn.manasuite.com/card_sets/artwork/"

    /// All available demo image URLs.
    var imageURLs: [URL] {
        (1 ... 348).compactMap { index in
            createSLDLandscapeURL(index: index)
        }
    }

    /// Creates a URL for a specific landscape image.
    ///
    /// - Parameter index: The image index (1-348).
    /// - Returns: The constructed URL, or nil if invalid.
    private func createSLDLandscapeURL(index: Int) -> URL? {
        URL(string: "\(baseURL)sld_\(index)_landscape.jpg")
    }
}

// MARK: - CacheInfoBadge

/// Displays cache statistics in a compact badge format.
///
/// Shows the number of cached images, disk usage, and memory usage
/// in a glass-effect badge in the navigation bar.
private struct CacheInfoBadge: View {
    /// The cache info to display, or nil if not yet loaded.
    let info: CacheInfo?

    var body: some View {
        if let info {
            VStack(spacing: 2) {
                imageCountLabel(count: info.cachedEntryCount)
                storageInfoLabel(info: info)
            }
            .font(.caption)
            .foregroundStyle(.primary)
            .padding(.horizontal)
            .padding(.vertical, 6)
            .glassEffect()
            .accessibilityElement(children: .combine)
            .accessibilityLabel(accessibilityDescription(for: info))
        }
    }

    /// Creates the image count label.
    ///
    /// - Parameter count: The number of cached images.
    /// - Returns: A text view displaying the count.
    private func imageCountLabel(count: Int) -> some View {
        Text("Images \(count)")
    }

    /// Creates the storage info label.
    ///
    /// - Parameter info: The cache info containing storage details.
    /// - Returns: A view displaying disk and memory usage.
    private func storageInfoLabel(info: CacheInfo) -> some View {
        HStack(spacing: 4) {
            Text("Disk \(info.diskUsedFormatted)")
            Text("|")
                .accessibilityHidden(true)
            Text("Memory \(info.memoryUsedFormatted)")
        }
    }

    /// Creates an accessibility description for the cache info.
    ///
    /// - Parameter info: The cache info to describe.
    /// - Returns: A human-readable description for VoiceOver.
    private func accessibilityDescription(for info: CacheInfo) -> String {
        "\(info.cachedEntryCount) cached images, disk usage \(info.diskUsedFormatted), memory usage \(info.memoryUsedFormatted)"
    }
}

// MARK: - ImageCardView

/// Displays a single cached image with its metadata.
///
/// Shows the image thumbnail, filename, and cache metadata including
/// last modified date and cache timestamp.
private struct ImageCardView: View {
    /// The URL of the image to display.
    let url: URL?

    /// The loaded metadata for this image.
    @State private var metadata: Metadata?

    var body: some View {
        VStack(spacing: 6) {
            imageContent
            fileNameLabel
            MetadataInfoView(metadata: metadata)
        }
        .task {
            await loadMetadata()
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityDescription)
    }

    /// The main image content with placeholder and failure states.
    private var imageContent: some View {
        AsyncCachedImage(
            url: url,
            asThumbnail: true,
            content: { image in
                image
                    .resizable()
                    .scaledToFit()
            },
            placeholder: {
                ImageLoading()
            },
            failure: {
                ImagePlaceholder()
            }
        )
        .imageConfiguration(.listThumbnail)
        .frame(height: 150)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    /// The filename label displayed below the image.
    private var fileNameLabel: some View {
        Text(url?.lastPathComponent ?? "Unknown")
            .font(.caption2)
            .fontWeight(.medium)
            .lineLimit(1)
            .truncationMode(.middle)
    }

    /// The accessibility description for VoiceOver.
    private var accessibilityDescription: String {
        let fileName = url?.lastPathComponent ?? "Unknown"
        if let metadata {
            return "Image \(fileName), cached at \(MetadataDateFormatter.formatTime(metadata.cachedAt))"
        }
        return "Image \(fileName), not cached"
    }

    /// Loads the metadata for this image from the MetadataStore.
    private func loadMetadata() async {
        guard let url else { return }
        metadata = await MetadataStore.shared.metadata(for: url, thumb: true)
    }
}

// MARK: - ImagePlaceholder

/// A placeholder view shown when an image fails to load.
private struct ImagePlaceholder: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .overlay {
                Image(systemName: "exclamationmark.triangle")
                    .font(.largeTitle)
                    .foregroundStyle(.secondary)
            }
    }
}

// MARK: - ImageLoading

/// A loading indicator view shown while an image is being downloaded.
private struct ImageLoading: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(Color.gray.opacity(0.2))
            .overlay {
                ProgressView()
                    .accessibilityLabel("Loading image")
            }
    }
}

// MARK: - MetadataInfoView

/// Displays metadata information for a cached image.
///
/// Shows the last modified date and cache timestamp when available,
/// or a "No metadata" indicator when not cached.
private struct MetadataInfoView: View {
    /// The metadata to display, or nil if not cached.
    let metadata: Metadata?

    var body: some View {
        VStack(spacing: 2) {
            if let metadata {
                lastModifiedLabel(metadata: metadata)
                cachedAtLabel(metadata: metadata)
            } else {
                noMetadataLabel
            }
        }
        .lineLimit(1)
        .truncationMode(.middle)
    }

    /// Creates the last modified label if available.
    ///
    /// - Parameter metadata: The metadata containing the last modified date.
    /// - Returns: A text view with the last modified date, or nothing if not available.
    @ViewBuilder
    private func lastModifiedLabel(metadata: Metadata) -> some View {
        if let lastModified = metadata.lastModified {
            Text("Modified: \(lastModified)")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    /// Creates the cached at label.
    ///
    /// - Parameter metadata: The metadata containing the cache timestamp.
    /// - Returns: A text view with the cache time.
    private func cachedAtLabel(metadata: Metadata) -> some View {
        Text("Cached: \(MetadataDateFormatter.formatTime(metadata.cachedAt))")
            .font(.caption2)
            .foregroundStyle(.blue)
    }

    /// The label shown when no metadata is available.
    private var noMetadataLabel: some View {
        Text("No metadata")
            .font(.caption2)
            .foregroundStyle(.red)
    }
}

// MARK: - MetadataDateFormatter

/// Formats dates for metadata display.
private enum MetadataDateFormatter {
    /// Formatter for time-only display (HH:mm:ss).
    private static let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter
    }()

    /// Formats a date as time only.
    ///
    /// - Parameter date: The date to format.
    /// - Returns: A string in HH:mm:ss format.
    static func formatTime(_ date: Date) -> String {
        timeFormatter.string(from: date)
    }
}

// MARK: - Convenience Presets

public extension ImageLoadingOptions {
    /// Thumbnails in large lists (100+ images).
    ///
    /// Configuration:
    /// - Long throttle interval (300s) to reduce network spam
    /// - Revalidation enabled but infrequent
    /// - Cache enabled for fast scrolling
    static let listThumbnail = ImageLoadingOptions(
        revalidationThrottleInterval: 300,
        skipRevalidation: false,
        ignoreCache: false
    )

    /// Options for high-priority hero images.
    ///
    /// Configuration:
    /// - Short throttle interval (2s) for fresh content
    /// - Frequent revalidation for important images
    static let hero = ImageLoadingOptions(
        revalidationThrottleInterval: 2
    )
}

// MARK: - Preview

#Preview {
    DemoView()
}
