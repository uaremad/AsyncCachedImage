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

// MARK: - Configuration

/// Global configuration for the AsyncCachedImage library.
///
/// Set this once at app launch to configure default behavior for all cached images.
/// Individual images can override specific settings using the `.imageConfiguration()` modifier.
///
/// ## Usage
///
/// You can use `typealias AsyncCachedImageConfiguration = Configuration` to avoid naming conflicts.
///
/// Configure at app launch (e.g., in `App.init()` or `AppDelegate`):
/// ```swift
/// AsyncCachedImageConfiguration.shared = Configuration(
///     revalidationInterval: 60,
///     revalidationThrottleInterval: 10,
///     thumbnailMaxPixelSize: 300
/// )
/// ```
///
/// Or modify individual properties:
/// ```swift
/// Configuration.shared.revalidationInterval = 120
/// ```
public struct Configuration: Sendable {
    // MARK: - Shared Instance

    /// The shared global configuration used by all AsyncCachedImage instances.
    ///
    /// Modify this at app launch to set default behavior.
    /// Thread-safe via MainActor isolation.
    @MainActor
    public static var shared = Configuration()

    // MARK: - Revalidation Settings

    /// Time in seconds after which cached content is considered stale and needs revalidation.
    ///
    /// When an image has been cached longer than this interval, a HEAD request is made
    /// to check if the server has a newer version (using ETag or Last-Modified headers).
    ///
    /// - Default: 30 seconds
    /// - Note: Set to `0` to always revalidate, or `.infinity` to never revalidate.
    public var revalidationInterval: TimeInterval

    /// Minimum time in seconds between revalidation attempts for the same image.
    ///
    /// Prevents excessive network requests when views appear/disappear frequently.
    /// This throttle is per-image-view instance.
    ///
    /// - Default: 5 seconds
    public var revalidationThrottleInterval: TimeInterval

    // MARK: - Thumbnail Settings

    /// Maximum pixel size for thumbnail images.
    ///
    /// When `asThumbnail: true` is used, images are downscaled to fit within
    /// this dimension (longest edge) during decoding.
    ///
    /// - Default: 400 pixels
    public var thumbnailMaxPixelSize: Int

    // MARK: - Memory Cache Settings

    /// Maximum number of decoded images to keep in memory cache.
    ///
    /// The memory cache stores fully decoded images for instant display.
    /// When this limit is exceeded, least recently used images are evicted.
    ///
    /// - Default: 150 images
    public var memoryCacheCountLimit: Int

    /// Maximum memory in bytes for the decoded image cache.
    ///
    /// This limits the total memory used by decoded images.
    /// When exceeded, least recently used images are evicted.
    ///
    /// - Default: 100 MB (100 * 1024 * 1024)
    public var memoryCacheSizeLimit: Int

    // MARK: - Initialization

    /// Creates a new configuration with the specified settings.
    ///
    /// - Parameters:
    ///   - revalidationInterval: Seconds before cached content needs revalidation. Default: 30
    ///   - revalidationThrottleInterval: Minimum seconds between revalidation attempts. Default: 5
    ///   - thumbnailMaxPixelSize: Maximum pixel size for thumbnails. Default: 400
    ///   - memoryCacheCountLimit: Maximum decoded images in memory. Default: 150
    ///   - memoryCacheSizeLimit: Maximum memory for decoded images in bytes. Default: 100 MB
    public init(
        revalidationInterval: TimeInterval = Defaults.revalidationInterval,
        revalidationThrottleInterval: TimeInterval = Defaults.revalidationThrottleInterval,
        thumbnailMaxPixelSize: Int = Defaults.thumbnailMaxPixelSize,
        memoryCacheCountLimit: Int = Defaults.memoryCacheCountLimit,
        memoryCacheSizeLimit: Int = Defaults.memoryCacheSizeLimit
    ) {
        self.revalidationInterval = revalidationInterval
        self.revalidationThrottleInterval = revalidationThrottleInterval
        self.thumbnailMaxPixelSize = thumbnailMaxPixelSize
        self.memoryCacheCountLimit = memoryCacheCountLimit
        self.memoryCacheSizeLimit = memoryCacheSizeLimit
    }

    // MARK: - Defaults

    /// Default values for configuration options.
    ///
    /// Use these constants when you need to reference default values programmatically.
    public enum Defaults {
        /// Default revalidation interval: 30 seconds.
        public static let revalidationInterval: TimeInterval = 30

        /// Default revalidation throttle interval: 5 seconds.
        public static let revalidationThrottleInterval: TimeInterval = 5

        /// Default thumbnail maximum pixel size: 400 pixels.
        public static let thumbnailMaxPixelSize: Int = 400

        /// Default memory cache count limit: 150 images.
        public static let memoryCacheCountLimit: Int = 150

        /// Default memory cache size limit: 100 MB.
        public static let memoryCacheSizeLimit: Int = 100 * 1024 * 1024
    }
}

// MARK: - ImageLoadingOptions

/// Per-image loading options that override global configuration.
///
/// Use with the `.imageConfiguration()` modifier to customize behavior for specific images.
///
/// ## Usage
///
/// ```swift
/// AsyncCachedImage(url: imageURL) { image in
///     image.resizable()
/// } placeholder: {
///     ProgressView()
/// }
/// .imageConfiguration(ImageLoadingOptions(
///     revalidationThrottleInterval: 60
/// ))
/// ```
public struct ImageLoadingOptions: Sendable {
    // MARK: - Revalidation Options

    /// Override the revalidation throttle interval for this image.
    ///
    /// When set, overrides `Configuration.shared.revalidationThrottleInterval`.
    /// Set to `nil` to use the global default.
    public var revalidationThrottleInterval: TimeInterval?

    /// When `true`, skip revalidation entirely for this image.
    ///
    /// Useful for static images that never change.
    /// - Default: false
    public var skipRevalidation: Bool

    // MARK: - Loading Options

    /// When `true`, bypass the disk cache and always fetch from network.
    ///
    /// Useful for images that must always be fresh.
    /// - Default: false
    public var ignoreCache: Bool

    // MARK: - Initialization

    /// Creates new loading options with the specified settings.
    ///
    /// - Parameters:
    ///   - revalidationThrottleInterval: Override throttle interval, or nil for global default.
    ///   - skipRevalidation: When true, never revalidate this image. Default: false.
    ///   - ignoreCache: When true, always fetch from network. Default: false.
    public init(
        revalidationThrottleInterval: TimeInterval? = nil,
        skipRevalidation: Bool = false,
        ignoreCache: Bool = false
    ) {
        self.revalidationThrottleInterval = revalidationThrottleInterval
        self.skipRevalidation = skipRevalidation
        self.ignoreCache = ignoreCache
    }

    // MARK: - Default Instance

    /// Default options that use global configuration.
    ///
    /// Equivalent to calling `ImageLoadingOptions()` with no arguments.
    public static let `default` = ImageLoadingOptions()
}
