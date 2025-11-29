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

// MARK: - Metadata

/// Cache metadata for a stored image.
///
/// Contains HTTP cache headers and timing information used for revalidation.
/// Persisted alongside cached images to enable efficient conditional requests.
///
/// ## Revalidation Process
///
/// When revalidating cached content, the metadata provides:
/// - `etag` for `If-None-Match` conditional requests
/// - `lastModified` for `If-Modified-Since` conditional requests
/// - `cachedAt` for determining when to trigger revalidation
///
/// If the server returns 304 Not Modified, the cache is still valid.
public struct Metadata: Codable, Sendable {
    /// The ETag header value from the server response.
    ///
    /// ETags are unique identifiers for specific versions of a resource.
    /// Used for conditional requests with the `If-None-Match` header.
    ///
    /// - Note: May be nil if the server doesn't provide ETags.
    public let etag: String?

    /// The Last-Modified header value from the server response.
    ///
    /// Indicates when the resource was last changed on the server.
    /// Used for conditional requests with the `If-Modified-Since` header.
    ///
    /// - Note: May be nil if the server doesn't provide Last-Modified timestamps.
    public let lastModified: String?

    /// The timestamp when this entry was cached.
    ///
    /// Used to determine when the cached content should be revalidated.
    public let cachedAt: Date

    // MARK: - Initialization

    /// Creates new metadata with the specified values.
    ///
    /// - Parameters:
    ///   - etag: The ETag header value from the server, or nil if not provided.
    ///   - lastModified: The Last-Modified header value from the server, or nil if not provided.
    ///   - cachedAt: The timestamp when the content was cached. Defaults to the current date.
    public init(etag: String?, lastModified: String?, cachedAt: Date = Date()) {
        self.etag = etag
        self.lastModified = lastModified
        self.cachedAt = cachedAt
    }
}
