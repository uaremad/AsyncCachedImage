//
//  AsyncCachedImage
//
//  Copyright © 2026 Jan-Hendrik Damerau.
//  https://github.com/uaremad/AsyncCachedImage
//
//  Licensed under the MIT License
//  Free to use without restrictions. See LICENSE file for full terms.
//

import AsyncCachedImage
import SwiftUI

// MARK: - CacheView

/// A view for browsing and managing the image cache.
///
/// Displays all cached images with their metadata and provides
/// options to clear the cache or delete individual entries.
///
/// ## Features
///
/// - List of all cached images with thumbnails
/// - Cache statistics (disk/memory usage, entry count)
/// - Swipe-to-delete on iOS
/// - Clear all button
/// - Expandable metadata details (URL, ETag, Last-Modified)
public struct CacheView: View {
    /// Environment dismiss action for closing the sheet.
    @Environment(\.dismiss) private var dismiss

    /// All cached image entries.
    @State private var entries: [MetadataEntry] = []

    /// Current cache statistics.
    @State private var cacheInfo: CacheInfo?

    public init() {}

    public var body: some View {
        NavigationStack {
            cacheContent
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                leadingToolbarContent
                trailingToolbarContent
            }
            .task {
                await refresh()
            }
        }
    }

    // MARK: - Toolbar

    /// Close button in the leading toolbar position.
    private var leadingToolbarContent: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            .accessibilityLabel("Close")
        }
    }

    /// Refresh and clear buttons in the trailing toolbar position.
    private var trailingToolbarContent: some ToolbarContent {
        ToolbarItemGroup(placement: .primaryAction) {
            Button {
                Task {
                    await refresh()
                }
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .accessibilityLabel("Refresh")

            Button(role: .destructive) {
                Task {
                    await clearAllAndRefresh()
                }
            } label: {
                Image(systemName: "trash")
            }
            .accessibilityLabel("Clear all cached images")
        }
    }

    // MARK: - Content

    /// The main content view, showing either empty state or entry list.
    @ViewBuilder
    private var cacheContent: some View {
        if entries.isEmpty {
            emptyState
        } else {
            entryList
        }
    }

    /// Empty state view when no images are cached.
    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
                .accessibilityHidden(true)
            Text("No cached images")
                .font(.headline)
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    /// List view showing all cached entries.
    private var entryList: some View {
        List {
            Section {
                cacheStatsHeader
            }
            Section {
                ForEach(entries) { entry in
                    CacheEntryRow(entry: entry) {
                        Task {
                            await deleteEntry(entry)
                        }
                    }
                    #if os(iOS)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            Task {
                                await deleteEntry(entry)
                            }
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                    #endif
                }
            }
        }

        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
    }

    /// Header showing cache statistics.
    @ViewBuilder
    private var cacheStatsHeader: some View {
        if let info = cacheInfo {
            VStack(alignment: .leading, spacing: 4) {
                Text("Disk: \(info.diskUsedFormatted) / \(info.diskCapacityFormatted)")
                Text("Memory: \(info.memoryUsedFormatted)")
                Text("Entries: \(info.cachedEntryCount)")
            }
            .font(.caption)
            .textCase(nil)
        }
    }

    // MARK: - Actions

    /// Refreshes the entry list and cache statistics.
    private func refresh() async {
        entries = await CacheManager.shared.getAllEntries()
        cacheInfo = await CacheManager.shared.info
    }

    /// Clears all cached data and refreshes the view.
    private func clearAllAndRefresh() async {
        await CacheManager.shared.clearAll()
        await refresh()
    }

    /// Deletes a single cache entry and refreshes the view.
    ///
    /// - Parameter entry: The entry to delete.
    private func deleteEntry(_ entry: MetadataEntry) async {
        await CacheManager.shared.removeEntry(for: entry.url, thumb: entry.isThumb)
        await refresh()
    }
}

// MARK: - CacheEntryRow

/// A row displaying a single cache entry with expandable details.
private struct CacheEntryRow: View {
    /// The cache entry to display.
    let entry: MetadataEntry

    /// Callback when delete is requested.
    let onDelete: () -> Void

    var body: some View {
        DisclosureGroup {
            detailsContent
        } label: {
            rowContent
        }
    }

    /// The main row content with thumbnail and info.
    private var rowContent: some View {
        HStack(spacing: 12) {
            thumbnailImage
            entryInfo
            Spacer()
            #if os(macOS)
            deleteButton
            #endif
        }
    }

    /// The thumbnail image for the entry.
    private var thumbnailImage: some View {
        AsyncCachedImage(
            url: entry.url,
            asThumbnail: true
        ) { image in
            image
                .resizable()
                .scaledToFill()
        } placeholder: {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color.gray.opacity(0.2))
                .overlay {
                    ProgressView()
                }
        }
        .frame(width: 48, height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 6))
    }

    /// The text information about the entry.
    private var entryInfo: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(entry.fileName)
                .font(.subheadline)
                .fontWeight(.medium)
                .lineLimit(1)

            HStack(spacing: 6) {
                if entry.isThumb {
                    thumbBadge
                }
                Text(entry.diskSizeFormatted)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            cachedAtLabel
        }
    }

    /// Badge indicating this is a thumbnail variant.
    private var thumbBadge: some View {
        Text("Thumb")
            .font(.caption2)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.blue.opacity(0.2))
            .clipShape(Capsule())
    }

    /// Label showing when the entry was cached.
    @ViewBuilder
    private var cachedAtLabel: some View {
        if let metadata = entry.metadata {
            Text("Cached: \(formatDate(metadata.cachedAt))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    #if os(macOS)
    /// Delete button for macOS (iOS uses swipe actions).
    private var deleteButton: some View {
        Button(role: .destructive) {
            onDelete()
        } label: {
            Image(systemName: "trash")
        }
        .buttonStyle(.borderless)
        .accessibilityLabel("Delete entry")
    }
    #endif

    /// The expandable details content.
    @ViewBuilder
    private var detailsContent: some View {
        if let metadata = entry.metadata {
            MetadataDetailsView(entry: entry, metadata: metadata)
        } else {
            Text("No metadata available")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    /// Formats a date for display.
    ///
    /// - Parameter date: The date to format.
    /// - Returns: A formatted string with short date and medium time.
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

// MARK: - MetadataDetailsView

/// Displays detailed metadata for a cache entry.
private struct MetadataDetailsView: View {
    /// The cache entry.
    let entry: MetadataEntry

    /// The metadata to display.
    let metadata: Metadata

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Divider()

            urlSection
            etagSection
            lastModifiedSection
        }
        .font(.caption)
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// Section displaying the full URL.
    private var urlSection: some View {
        Group {
            Text("URL:")
                .fontWeight(.medium)
            Text(entry.url.absoluteString)
                .foregroundStyle(.secondary)
        }
    }

    /// Section displaying the ETag if available.
    @ViewBuilder
    private var etagSection: some View {
        if let etag = metadata.etag {
            Text("ETag:")
                .fontWeight(.medium)
            Text(etag)
                .foregroundStyle(.secondary)
        }
    }

    /// Section displaying the Last-Modified header if available.
    @ViewBuilder
    private var lastModifiedSection: some View {
        if let lastModified = metadata.lastModified {
            Text("Last-Modified:")
                .fontWeight(.medium)
            Text(lastModified)
                .foregroundStyle(.secondary)
        }
    }
}
