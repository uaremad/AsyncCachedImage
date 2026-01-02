//
//  AsyncCachedImage
//
//  Copyright © 2026 Jan-Hendrik Damerau.
//  https://github.com/uaremad/AsyncCachedImage
//
//  Licensed under the MIT License
//  Free to use without restrictions. See LICENSE file for full terms.
//

import Foundation

// MARK: - CacheInfo

/// Aggregated cache statistics for disk and memory usage.
///
/// Provides a snapshot of the current cache state, including storage usage
/// and entry counts. Use `CacheManager.shared.info` to retrieve this information.
///
/// ## Example
///
/// ```swift
/// let info = await CacheManager.shared.info
/// print(info.summary)
/// // Output: "Disk: 45.2 MB / 500 MB, Memory: 12.3 MB, Entries: 127"
/// ```
public struct CacheInfo: Sendable {
    /// The amount of disk space currently used by cached images in bytes.
    public let diskUsedBytes: Int64

    /// The maximum disk cache capacity in bytes.
    public let diskCapacityBytes: Int64

    /// The amount of memory currently used by cached images in bytes.
    public let memoryUsedBytes: Int64

    /// The maximum memory cache capacity in bytes.
    public let memoryCapacityBytes: Int64

    /// The total number of cached image entries (including thumbnails).
    public let cachedEntryCount: Int

    // MARK: - Formatted Properties

    /// Human-readable formatted disk usage.
    ///
    /// Example: "45.2 MB"
    public var diskUsedFormatted: String {
        ByteCountFormatter.string(fromByteCount: diskUsedBytes, countStyle: .file)
    }

    /// Human-readable formatted disk capacity.
    ///
    /// Example: "500 MB"
    public var diskCapacityFormatted: String {
        ByteCountFormatter.string(fromByteCount: diskCapacityBytes, countStyle: .file)
    }

    /// Human-readable formatted memory usage.
    ///
    /// Example: "12.3 MB"
    public var memoryUsedFormatted: String {
        ByteCountFormatter.string(fromByteCount: memoryUsedBytes, countStyle: .file)
    }

    /// Human-readable formatted memory capacity.
    ///
    /// Example: "100 MB"
    public var memoryCapacityFormatted: String {
        ByteCountFormatter.string(fromByteCount: memoryCapacityBytes, countStyle: .file)
    }

    /// A one-line summary of all cache statistics.
    ///
    /// Example: "Disk: 45.2 MB / 500 MB, Memory: 12.3 MB, Entries: 127"
    public var summary: String {
        "Disk: \(diskUsedFormatted) / \(diskCapacityFormatted), Memory: \(memoryUsedFormatted), Entries: \(cachedEntryCount)"
    }
}
