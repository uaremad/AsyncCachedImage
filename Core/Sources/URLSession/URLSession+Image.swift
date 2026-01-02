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

// MARK: - URLSession Image Extensions

extension URLSession {
    /// A pre-configured URLSession optimized for image downloading with caching.
    ///
    /// Features:
    /// - 100 MB memory cache for compressed image data
    /// - 500 MB disk cache in the app's caches directory
    /// - Prefers cached data over network requests
    /// - 30 second request timeout
    /// - 120 second resource timeout
    ///
    /// The cache directory is located at `{CachesDirectory}/ImageCache/`.
    ///
    /// - Note: This session is separate from the app's default URLSession to avoid
    ///   polluting other network requests with image caching behavior.
    static let imageCacheSession: URLSession = {
        let cacheDirectory = createCacheDirectory()
        let cache = createURLCache(directory: cacheDirectory)
        let configuration = createCachingConfiguration(cache: cache)
        return URLSession(configuration: configuration)
    }()

    /// A pre-configured URLSession that bypasses all caching.
    ///
    /// Used for:
    /// - Cache revalidation HEAD requests
    /// - Force-refresh downloads when cache is invalidated
    /// - Downloading updated images after server content changes
    ///
    /// Features:
    /// - No memory or disk caching
    /// - Ignores any cached responses
    /// - 30 second request timeout
    /// - 120 second resource timeout
    static let imageNoCacheSession: URLSession = {
        let configuration = createNoCacheConfiguration()
        return URLSession(configuration: configuration)
    }()
}

// MARK: - Configuration Helpers

private extension URLSession {
    /// Creates the cache directory URL.
    ///
    /// Falls back to the temporary directory if the caches directory is unavailable.
    ///
    /// - Returns: The URL for the image cache directory.
    static func createCacheDirectory() -> URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("ImageCache")
    }

    /// Creates a URLCache with the specified directory.
    ///
    /// - Parameter directory: The directory for disk cache storage.
    /// - Returns: A configured URLCache instance.
    static func createURLCache(directory: URL) -> URLCache {
        URLCache(
            memoryCapacity: CacheConstants.memoryCapacity,
            diskCapacity: CacheConstants.diskCapacity,
            directory: directory
        )
    }

    /// Creates a URLSessionConfiguration optimized for cached image loading.
    ///
    /// - Parameter cache: The URLCache to use for caching responses.
    /// - Returns: A configured URLSessionConfiguration.
    static func createCachingConfiguration(cache: URLCache) -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = cache
        configuration.requestCachePolicy = .returnCacheDataElseLoad
        configuration.timeoutIntervalForRequest = TimeoutConstants.requestTimeout
        configuration.timeoutIntervalForResource = TimeoutConstants.resourceTimeout
        return configuration
    }

    /// Creates a URLSessionConfiguration that bypasses all caching.
    ///
    /// - Returns: A configured URLSessionConfiguration with caching disabled.
    static func createNoCacheConfiguration() -> URLSessionConfiguration {
        let configuration = URLSessionConfiguration.default
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        configuration.timeoutIntervalForRequest = TimeoutConstants.requestTimeout
        configuration.timeoutIntervalForResource = TimeoutConstants.resourceTimeout
        return configuration
    }
}

// MARK: - Constants

private extension URLSession {
    /// Cache size constants.
    enum CacheConstants {
        /// Memory cache capacity: 100 MB
        ///
        /// Stores compressed image data for fast retrieval without disk I/O.
        static let memoryCapacity = 100 * 1024 * 1024

        /// Disk cache capacity: 500 MB
        ///
        /// Persistent storage for image data across app launches.
        static let diskCapacity = 500 * 1024 * 1024
    }

    /// Network timeout constants.
    enum TimeoutConstants {
        /// Timeout for the initial connection: 30 seconds
        static let requestTimeout: TimeInterval = 30

        /// Timeout for the entire resource download: 120 seconds
        static let resourceTimeout: TimeInterval = 120
    }
}
