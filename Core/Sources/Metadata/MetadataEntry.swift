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

// MARK: - MetadataEntry

/// Represents a single cached image entry with its metadata.
///
/// Used by the cache browser and management APIs to display and manage
/// cached images. Combines URL, variant information, metadata, and size.
public struct MetadataEntry: Identifiable, Sendable {
    /// Unique identifier for this cache entry.
    ///
    /// Typically the URL string, with `#thumb` suffix for thumbnail variants.
    public let id: String

    /// The original URL of the cached image.
    public let url: URL

    /// Whether this entry is a thumbnail variant.
    ///
    /// Thumbnail and full-size versions of the same image are stored separately.
    public let isThumb: Bool

    /// The cache metadata containing ETag, Last-Modified, and cache timestamp.
    ///
    /// May be nil if metadata was not stored or could not be loaded.
    public let metadata: Metadata?

    /// The size of the cached data on disk in bytes.
    public let diskSizeBytes: Int64

    // MARK: - Computed Properties

    /// Human-readable formatted disk size.
    ///
    /// Examples: "1.2 MB", "456 KB", "12 bytes"
    public var diskSizeFormatted: String {
        ByteCountFormatter.string(fromByteCount: diskSizeBytes, countStyle: .file)
    }

    /// The file name extracted from the URL.
    ///
    /// Returns the last path component of the URL (e.g., "image.jpg").
    public var fileName: String {
        url.lastPathComponent
    }
}
