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

// MARK: - MemoryCacheStorage

/// Thread-safe storage backend for the memory cache.
///
/// This class provides the underlying NSCache storage that can be accessed
/// both synchronously and asynchronously. NSCache is documented by Apple
/// as thread-safe, making it safe to access from any thread.
///
/// The storage is separated from the actor to enable synchronous access
/// for view initialization, preventing flicker when parent views re-render.
final class MemoryCacheStorage: @unchecked Sendable {
    /// The shared storage instance.
    static let shared = MemoryCacheStorage()

    /// The underlying NSCache for image storage.
    private let cache: NSCache<NSURL, PlatformImage>

    /// NSCache is explicitly documented by Apple as thread-safe:
    ///
    ///     "You can add, remove, and query items in the cache from different threads without having to lock the cache yourself."
    ///     — https://developer.apple.com/documentation/foundation/nscache
    ///
    private init() {
        cache = NSCache<NSURL, PlatformImage>()
        cache.countLimit = Constants.countLimit
        cache.totalCostLimit = Constants.costLimitBytes
    }

    // MARK: - Synchronous API

    /// Retrieves a cached image synchronously.
    ///
    /// This method is safe to call from any thread because NSCache
    /// is inherently thread-safe.
    ///
    /// - Parameters:
    ///   - url: The image URL used as the cache key.
    ///   - thumb: Whether to retrieve the thumbnail variant.
    /// - Returns: The cached image, or nil if not found.
    func image(for url: URL, thumb: Bool) -> PlatformImage? {
        let key = createCacheKey(for: url, thumb: thumb)
        return cache.object(forKey: key)
    }

    /// Stores an image in the cache.
    ///
    /// - Parameters:
    ///   - image: The decoded image to store.
    ///   - url: The image URL used as the cache key.
    ///   - thumb: Whether this is a thumbnail variant.
    ///   - cost: The memory cost of the image in bytes.
    func store(_ image: PlatformImage, for url: URL, thumb: Bool, cost: Int) {
        let key = createCacheKey(for: url, thumb: thumb)
        cache.setObject(image, forKey: key, cost: cost)
    }

    /// Removes an image from the cache.
    ///
    /// - Parameters:
    ///   - url: The image URL used as the cache key.
    ///   - thumb: Whether to remove the thumbnail variant.
    func remove(for url: URL, thumb: Bool) {
        let key = createCacheKey(for: url, thumb: thumb)
        cache.removeObject(forKey: key)
    }

    /// Removes all cached images.
    func clearAll() {
        cache.removeAllObjects()
    }

    // MARK: - Private Helpers

    /// Creates a cache key for the given URL and variant.
    ///
    /// - Parameters:
    ///   - url: The base image URL.
    ///   - thumb: Whether this is a thumbnail variant.
    /// - Returns: An NSURL suitable for use as an NSCache key.
    private func createCacheKey(for url: URL, thumb: Bool) -> NSURL {
        if thumb {
            return NSURL(string: url.absoluteString + "#thumb") ?? url as NSURL
        }
        return url as NSURL
    }

    // MARK: - Constants

    private enum Constants {
        static let countLimit = 150
        static let costLimitBytes = 100 * 1024 * 1024
    }
}
