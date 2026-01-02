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

// MARK: - DiskCache

/// Thread-safe disk cache for images using actor isolation.
///
/// Provides persistent storage for downloaded images using URLCache.
/// Uses Swift 6 actor isolation for proper concurrency safety.
///
/// The disk cache automatically:
/// - Filters out error responses (404, 403, 500, etc.) before caching
/// - Validates cached responses before returning data
/// - Removes invalid cached entries when discovered
///
/// - Note: The cache is backed by URLSession's built-in URLCache system.
actor DiskCache {
    /// The shared disk cache instance.
    static let shared = DiskCache()

    private init() {}

    // MARK: - Retrieval

    /// Retrieves cached image data for a URL if available.
    ///
    /// Only returns data from successful HTTP responses (2xx status codes).
    /// Cached error responses are filtered out and automatically removed from cache.
    ///
    /// - Parameter url: The URL to look up in the cache.
    /// - Returns: The cached image data, or nil if not found or invalid.
    func cachedData(for url: URL) -> Data? {
        let request = RequestBuilder.createCacheRequest(for: url)
        return fetchValidCachedData(for: request, url: url)
    }

    /// Loads a cached image from disk, decoding it and storing in memory cache.
    ///
    /// If successful, the decoded image is also stored in the memory cache
    /// for faster subsequent access.
    ///
    /// - Parameters:
    ///   - url: The URL to look up.
    ///   - asThumbnail: If true, decodes as a downscaled thumbnail.
    /// - Returns: The decoded image, or nil if not cached or decoding fails.
    func loadCachedImage(for url: URL, asThumbnail: Bool) async -> PlatformImage? {
        guard let data = cachedData(for: url) else {
            return nil
        }

        let thumbnailSize = await MainActor.run { Configuration.shared.thumbnailMaxPixelSize }
        guard let image = ImageDecoder.decode(
            from: data,
            asThumbnail: asThumbnail,
            thumbnailMaxPixelSize: thumbnailSize
        ) else {
            return nil
        }

        await MemoryCache.shared.store(image, for: url, thumb: asThumbnail)
        return image
    }

    // MARK: - Storage

    /// Stores image data in the disk cache.
    ///
    /// Only caches successful HTTP responses (2xx status codes).
    /// Error responses are silently ignored to prevent caching invalid data
    /// that would cause decoding failures.
    ///
    /// - Parameters:
    ///   - data: The image data to cache.
    ///   - response: The HTTP response associated with the data.
    ///   - url: The URL key for the cache entry.
    func store(data: Data, response: URLResponse, for url: URL) {
        guard let cache = urlCache else { return }
        guard CacheEligibilityChecker.isEligibleForCaching(response) else {
            logSkippedCaching(url: url, response: response)
            return
        }

        let cachedResponse = CachedURLResponse(response: response, data: data)
        let request = URLRequest(url: url)
        cache.storeCachedResponse(cachedResponse, for: request)
    }

    // MARK: - Removal

    /// Removes cached data for a URL across all cache policies.
    ///
    /// Ensures complete removal by clearing the entry for all possible
    /// cache policy variants.
    ///
    /// - Parameter url: The URL to remove from cache.
    func remove(for url: URL) {
        guard let cache = urlCache else { return }
        CachePolicyRemover.removeFromAllPolicies(url: url, cache: cache)
    }

    /// Removes all cached responses from the disk cache.
    func removeAll() {
        urlCache?.removeAllCachedResponses()
    }

    // MARK: - Cache Info

    /// Current disk usage in bytes.
    var currentDiskUsage: Int {
        urlCache?.currentDiskUsage ?? 0
    }

    /// Maximum disk capacity in bytes.
    var diskCapacity: Int {
        urlCache?.diskCapacity ?? 0
    }

    /// Current memory usage in bytes for the URLCache memory layer.
    var currentMemoryUsage: Int {
        urlCache?.currentMemoryUsage ?? 0
    }

    /// Maximum memory capacity in bytes for the URLCache memory layer.
    var memoryCapacity: Int {
        urlCache?.memoryCapacity ?? 0
    }

    // MARK: - Private Helpers

    /// The underlying URLCache used for storage.
    private var urlCache: URLCache? {
        URLSession.imageCacheSession.configuration.urlCache
    }

    /// Fetches cached data after validating the response.
    ///
    /// - Parameters:
    ///   - request: The cache request to look up.
    ///   - url: The original URL for logging and cleanup.
    /// - Returns: Valid cached data, or nil if not found or invalid.
    private func fetchValidCachedData(for request: URLRequest, url: URL) -> Data? {
        guard let cachedResponse = urlCache?.cachedResponse(for: request) else {
            return nil
        }

        guard CachedResponseValidator.hasValidStatusCode(cachedResponse) else {
            removeInvalidCachedResponse(for: url)
            return nil
        }

        guard CachedResponseValidator.hasNonEmptyData(cachedResponse) else {
            return nil
        }

        return cachedResponse.data
    }

    /// Removes an invalid cached response and logs the action.
    ///
    /// - Parameter url: The URL of the invalid cache entry.
    private func removeInvalidCachedResponse(for url: URL) {
        remove(for: url)
        logRemovedInvalidCache(url: url)
    }

    // MARK: - Logging

    /// Logs when caching is skipped for an error response.
    ///
    /// - Parameters:
    ///   - url: The URL that was not cached.
    ///   - response: The error response.
    private func logSkippedCaching(url: URL, response: URLResponse) {
        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
        Logging.log?.warn(
            "[DiskCache] Skipped caching error response (HTTP \(statusCode)): \(url.lastPathComponent)"
        )
    }

    /// Logs when an invalid cached response is removed.
    ///
    /// - Parameter url: The URL of the removed cache entry.
    private func logRemovedInvalidCache(url: URL) {
        Logging.log?.trace(
            "[DiskCache] Removed cached error response: \(url.lastPathComponent)"
        )
    }
}

// MARK: - CacheEligibilityChecker

/// Determines if an HTTP response is eligible for caching.
///
/// Only successful responses (2xx status codes) should be cached.
/// This prevents caching of error pages, which would cause decoding failures
/// and CGImageSource errors when attempting to decode HTML as image data.
private enum CacheEligibilityChecker {
    /// Checks if a response is eligible for caching.
    ///
    /// - Parameter response: The URL response to check.
    /// - Returns: True if the response has a 2xx status code and should be cached.
    static func isEligibleForCaching(_ response: URLResponse) -> Bool {
        guard let httpResponse = response as? HTTPURLResponse else {
            return false
        }
        return isSuccessStatusCode(httpResponse.statusCode)
    }

    /// Checks if a status code indicates success.
    ///
    /// - Parameter statusCode: The HTTP status code to check.
    /// - Returns: True if the status code is in the 2xx range.
    private static func isSuccessStatusCode(_ statusCode: Int) -> Bool {
        (200 ..< 300).contains(statusCode)
    }
}

// MARK: - CachedResponseValidator

/// Validates cached responses before returning data.
///
/// Ensures that only valid, successful responses are used from cache.
/// Invalid responses are detected and can be removed to clean up the cache.
private enum CachedResponseValidator {
    /// Checks if a cached response has a successful HTTP status code.
    ///
    /// - Parameter cachedResponse: The cached response to validate.
    /// - Returns: True if the original response had a 2xx status code.
    static func hasValidStatusCode(_ cachedResponse: CachedURLResponse) -> Bool {
        guard let httpResponse = cachedResponse.response as? HTTPURLResponse else {
            return false
        }
        return isSuccessStatusCode(httpResponse.statusCode)
    }

    /// Checks if a cached response has non-empty data.
    ///
    /// - Parameter cachedResponse: The cached response to validate.
    /// - Returns: True if the cached data is not empty.
    static func hasNonEmptyData(_ cachedResponse: CachedURLResponse) -> Bool {
        !cachedResponse.data.isEmpty
    }

    /// Checks if a status code indicates success.
    ///
    /// - Parameter statusCode: The HTTP status code to check.
    /// - Returns: True if the status code is in the 2xx range.
    private static func isSuccessStatusCode(_ statusCode: Int) -> Bool {
        (200 ..< 300).contains(statusCode)
    }
}

// MARK: - RequestBuilder

/// Builds URL requests for cache operations.
private enum RequestBuilder {
    /// Creates a cache-friendly request for the given URL.
    ///
    /// Uses `.returnCacheDataElseLoad` policy to prefer cached data.
    ///
    /// - Parameter url: The URL to create a request for.
    /// - Returns: A configured URLRequest optimized for cache lookups.
    static func createCacheRequest(for url: URL) -> URLRequest {
        URLRequest(url: url, cachePolicy: .returnCacheDataElseLoad)
    }
}

// MARK: - CachePolicyRemover

/// Handles removal of cached responses across all cache policies.
///
/// URLCache stores responses keyed by request, which includes the cache policy.
/// To ensure complete removal, we must remove entries for all policy variants.
private enum CachePolicyRemover {
    /// Removes cached responses for all cache policy variants.
    ///
    /// - Parameters:
    ///   - url: The URL to remove from cache.
    ///   - cache: The URLCache instance to remove from.
    static func removeFromAllPolicies(url: URL, cache: URLCache) {
        for policy in allPolicies {
            let request = URLRequest(url: url, cachePolicy: policy)
            cache.removeCachedResponse(for: request)
        }
    }

    /// All cache policies that might have stored a response.
    private static var allPolicies: [URLRequest.CachePolicy] {
        [
            .returnCacheDataElseLoad,
            .reloadIgnoringLocalCacheData,
            .reloadIgnoringLocalAndRemoteCacheData,
            .useProtocolCachePolicy
        ]
    }
}
