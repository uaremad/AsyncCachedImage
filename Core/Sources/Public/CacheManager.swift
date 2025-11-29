//
//  AsyncCachedImage
//
//  Copyright © 2025 Jan-Hendrik Damerau.
//  https://github.com/uaremad/AsyncCachedImage
//
//  Licensed under the MIT License
//  Free to use without restrictions. See LICENSE file for full terms.
//

import Foundation

// MARK: - CacheManager

/// Coordinates all cache operations across memory, disk, and metadata stores.
///
/// Provides a unified interface for cache management, statistics, and cleanup.
/// Uses actor isolation for Swift 6 concurrency safety.
///
/// ## Example Usage
///
/// ```swift
/// // Get cache statistics
/// let info = await CacheManager.shared.info
/// print(info.summary)
///
/// // Clear all caches
/// await CacheManager.shared.clearAll()
///
/// // Remove a specific entry
/// await CacheManager.shared.removeEntry(for: imageURL, thumb: false)
/// ```
public actor CacheManager {
    /// The shared cache manager instance.
    public static let shared = CacheManager()

    private init() {}

    // MARK: - Cache Info

    /// Returns current cache statistics.
    ///
    /// Aggregates information from URLCache and MetadataStore to provide
    /// a complete picture of cache usage.
    public var info: CacheInfo {
        get async {
            let urlCache = URLSession.imageCacheSession.configuration.urlCache
            let diskUsed = Int64(urlCache?.currentDiskUsage ?? 0)
            let diskCapacity = Int64(urlCache?.diskCapacity ?? 0)
            let memoryUsed = Int64(urlCache?.currentMemoryUsage ?? 0)
            let memoryCapacity = Int64(urlCache?.memoryCapacity ?? 0)
            let entryCount = await MetadataStore.shared.entryCount()

            return CacheInfo(
                diskUsedBytes: diskUsed,
                diskCapacityBytes: diskCapacity,
                memoryUsedBytes: memoryUsed,
                memoryCapacityBytes: memoryCapacity,
                cachedEntryCount: entryCount
            )
        }
    }

    // MARK: - Clear Operations

    /// Clears all caches including disk, memory, and metadata.
    ///
    /// This removes all cached images and their associated metadata.
    /// Use this for a complete cache reset.
    public func clearAll() async {
        await clearURLCache()
        await clearMemoryCache()
        await clearMetadata()
        logCacheCleared(type: "All caches")
    }

    /// Clears only the memory cache, preserving disk cache.
    ///
    /// Use this to free up memory while keeping disk-cached images available.
    /// Images will be reloaded from disk on next access.
    public func clearMemoryOnly() async {
        await clearMemoryCache()
        logCacheCleared(type: "Memory cache")
    }

    // MARK: - Entry Management

    /// Removes a specific cache entry from all cache layers.
    ///
    /// Removes the entry from memory cache, disk cache, and metadata store.
    ///
    /// - Parameters:
    ///   - url: The image URL to remove.
    ///   - thumb: Whether to remove the thumbnail variant.
    public func removeEntry(for url: URL, thumb: Bool) async {
        await MemoryCache.shared.remove(for: url, thumb: thumb)
        await MetadataStore.shared.remove(for: url, thumb: thumb)
        await DiskCache.shared.remove(for: url)
    }

    /// Returns all cached image entries.
    ///
    /// Retrieves metadata for all cached images, sorted by cache date (newest first).
    /// Useful for building cache browser UIs.
    ///
    /// - Returns: An array of metadata entries for all cached images.
    public func getAllEntries() async -> [MetadataEntry] {
        let metadataEntries = await MetadataStore.shared.allEntries()
        var entries: [MetadataEntry] = []

        for entry in metadataEntries {
            if let metadataEntry = await createEntry(from: entry.key, metadata: entry.metadata) {
                entries.append(metadataEntry)
            }
        }

        return entries.sorted { sortByDate($0, $1) }
    }

    // MARK: - Private Helpers

    /// Clears all responses from the URL cache.
    private func clearURLCache() async {
        URLSession.imageCacheSession.configuration.urlCache?.removeAllCachedResponses()
    }

    /// Clears all images from the memory cache.
    private func clearMemoryCache() async {
        await MemoryCache.shared.clearAll()
    }

    /// Clears all stored metadata.
    private func clearMetadata() async {
        await MetadataStore.shared.removeAll()
    }

    /// Creates a MetadataEntry from a cache key and metadata.
    ///
    /// Parses the cache key to extract the URL and thumbnail flag,
    /// then retrieves the disk size for the entry.
    ///
    /// - Parameters:
    ///   - key: The cache key (URL string, optionally with #thumb suffix).
    ///   - metadata: The associated metadata.
    /// - Returns: A MetadataEntry, or nil if the key is invalid.
    private func createEntry(from key: String, metadata: Metadata) async -> MetadataEntry? {
        let isThumb = key.hasSuffix("#thumb")
        let urlString = isThumb ? String(key.dropLast(6)) : key

        guard let url = URL(string: urlString) else {
            return nil
        }

        let diskSize = await calculateDiskSize(for: url)

        return MetadataEntry(
            id: key,
            url: url,
            isThumb: isThumb,
            metadata: metadata,
            diskSizeBytes: diskSize
        )
    }

    /// Calculates the disk size of a cached image.
    ///
    /// - Parameter url: The URL of the cached image.
    /// - Returns: The size in bytes, or 0 if not cached.
    private func calculateDiskSize(for url: URL) async -> Int64 {
        guard let data = await DiskCache.shared.cachedData(for: url) else {
            return 0
        }
        return Int64(data.count)
    }

    /// Sorts two entries by cache date, newest first.
    ///
    /// - Parameters:
    ///   - lhs: The first entry to compare.
    ///   - rhs: The second entry to compare.
    /// - Returns: True if lhs was cached more recently than rhs.
    private func sortByDate(_ lhs: MetadataEntry, _ rhs: MetadataEntry) -> Bool {
        (lhs.metadata?.cachedAt ?? .distantPast) > (rhs.metadata?.cachedAt ?? .distantPast)
    }

    /// Logs a cache cleared message in debug builds.
    ///
    /// - Parameter type: A description of what was cleared.
    private func logCacheCleared(type: String) {
        #if DEBUG
        print("[CacheManager] \(type) cleared")
        #endif
    }
}
