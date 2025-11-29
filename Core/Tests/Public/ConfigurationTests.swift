//
//  AsyncCachedImage
//
//  Copyright © 2025 Jan-Hendrik Damerau.
//  https://github.com/uaremad/AsyncCachedImage
//
//  Licensed under the MIT License
//  Free to use without restrictions. See LICENSE file for full terms.
//

import XCTest
@testable import AsyncCachedImage

// MARK: - ImageLoadingOptionsTests

/// Tests for ImageLoadingOptions which provides per-image configuration.
///
/// ImageLoadingOptions can override global Configuration settings:
/// - revalidationThrottleInterval: Override throttle for specific images
/// - skipRevalidation: Disable revalidation for static images
/// - ignoreCache: Force fresh download
///
/// Applied via .imageConfiguration() modifier.
final class ImageLoadingOptionsTests: XCTestCase {
    // MARK: - Default Values

    /// Verifies default options have nil throttle interval.
    ///
    /// nil means use global Configuration value.
    ///
    /// Expected: revalidationThrottleInterval is nil.
    func testDefaultOptionsHaveNilThrottleInterval() {
        let options = ImageLoadingOptions.default

        XCTAssertNil(options.revalidationThrottleInterval)
    }

    /// Verifies default options do not skip revalidation.
    ///
    /// Expected: skipRevalidation is false.
    func testDefaultOptionsDoNotSkipRevalidation() {
        let options = ImageLoadingOptions.default

        XCTAssertFalse(options.skipRevalidation)
    }

    /// Verifies default options do not ignore cache.
    ///
    /// Expected: ignoreCache is false.
    func testDefaultOptionsDoNotIgnoreCache() {
        let options = ImageLoadingOptions.default

        XCTAssertFalse(options.ignoreCache)
    }

    // MARK: - Custom Initialization

    /// Verifies custom throttle interval is stored.
    ///
    /// Expected: revalidationThrottleInterval is 60.
    func testInitWithCustomThrottleInterval() {
        let options = ImageLoadingOptions(revalidationThrottleInterval: 60)

        XCTAssertEqual(options.revalidationThrottleInterval, 60)
    }

    /// Verifies skipRevalidation can be enabled.
    ///
    /// Useful for static images that never change.
    ///
    /// Expected: skipRevalidation is true.
    func testInitWithSkipRevalidation() {
        let options = ImageLoadingOptions(skipRevalidation: true)

        XCTAssertTrue(options.skipRevalidation)
    }

    /// Verifies ignoreCache can be enabled.
    ///
    /// Forces fresh download, bypassing disk cache.
    ///
    /// Expected: ignoreCache is true.
    func testInitWithIgnoreCache() {
        let options = ImageLoadingOptions(ignoreCache: true)

        XCTAssertTrue(options.ignoreCache)
    }

    /// Verifies all options can be set together.
    ///
    /// Expected: All values are correctly stored.
    func testInitWithAllOptions() {
        let options = ImageLoadingOptions(
            revalidationThrottleInterval: 120,
            skipRevalidation: true,
            ignoreCache: true
        )

        XCTAssertEqual(options.revalidationThrottleInterval, 120)
        XCTAssertTrue(options.skipRevalidation)
        XCTAssertTrue(options.ignoreCache)
    }

    // MARK: - Protocol Conformance

    /// Verifies ImageLoadingOptions conforms to Sendable.
    ///
    /// Required for Swift 6 concurrency safety.
    ///
    /// Expected: Can be assigned to Sendable type.
    func testConformsToSendableProtocol() {
        let options: Sendable = ImageLoadingOptions.default
        XCTAssertNotNil(options)
    }
}

// MARK: - ConfigurationTests

/// Tests for Configuration which provides global library settings.
///
/// Configuration settings affect all AsyncCachedImage instances:
/// - revalidationInterval: How often to check if cached content is stale
/// - revalidationThrottleInterval: Minimum time between revalidation attempts
/// - thumbnailMaxPixelSize: Maximum size for thumbnail decoding
/// - memoryCacheCountLimit: Maximum images in memory cache
/// - memoryCacheSizeLimit: Maximum memory for decoded images
@MainActor
final class ConfigurationTests: XCTestCase {
    // MARK: - Shared Instance

    /// Verifies shared singleton instance exists.
    ///
    /// Expected: Configuration.shared is not nil.
    func testSharedInstanceExists() {
        let config = Configuration.shared

        XCTAssertNotNil(config)
    }

    // MARK: - Default Values

    /// Verifies default revalidation interval is 30 seconds.
    ///
    /// Content older than this is revalidated via HEAD request.
    ///
    /// Expected: revalidationInterval is 30.
    func testDefaultRevalidationInterval() {
        let config = Configuration()

        XCTAssertEqual(config.revalidationInterval, 30)
    }

    /// Verifies default throttle interval is 5 seconds.
    ///
    /// Prevents excessive revalidation when views appear/disappear.
    ///
    /// Expected: revalidationThrottleInterval is 5.
    func testDefaultRevalidationThrottleInterval() {
        let config = Configuration()

        XCTAssertEqual(config.revalidationThrottleInterval, 5)
    }

    /// Verifies default thumbnail size is 400 pixels.
    ///
    /// Images decoded with asThumbnail fit within this dimension.
    ///
    /// Expected: thumbnailMaxPixelSize is 400.
    func testDefaultThumbnailMaxPixelSize() {
        let config = Configuration()

        XCTAssertEqual(config.thumbnailMaxPixelSize, 400)
    }

    /// Verifies default memory cache count is 150 images.
    ///
    /// Expected: memoryCacheCountLimit is 150.
    func testDefaultMemoryCacheCountLimit() {
        let config = Configuration()

        XCTAssertEqual(config.memoryCacheCountLimit, 150)
    }

    /// Verifies default memory cache size is 100 MB.
    ///
    /// Expected: memoryCacheSizeLimit is 100 * 1024 * 1024.
    func testDefaultMemoryCacheSizeLimit() {
        let config = Configuration()

        let expectedSize = 100 * 1024 * 1024
        XCTAssertEqual(config.memoryCacheSizeLimit, expectedSize)
    }

    // MARK: - Custom Initialization

    /// Verifies custom revalidation interval is stored.
    ///
    /// Expected: revalidationInterval is 60.
    func testInitWithCustomRevalidationInterval() {
        let config = Configuration(revalidationInterval: 60)

        XCTAssertEqual(config.revalidationInterval, 60)
    }

    /// Verifies custom throttle interval is stored.
    ///
    /// Expected: revalidationThrottleInterval is 10.
    func testInitWithCustomThrottleInterval() {
        let config = Configuration(revalidationThrottleInterval: 10)

        XCTAssertEqual(config.revalidationThrottleInterval, 10)
    }

    /// Verifies custom thumbnail size is stored.
    ///
    /// Expected: thumbnailMaxPixelSize is 200.
    func testInitWithCustomThumbnailSize() {
        let config = Configuration(thumbnailMaxPixelSize: 200)

        XCTAssertEqual(config.thumbnailMaxPixelSize, 200)
    }

    /// Verifies custom memory cache count is stored.
    ///
    /// Expected: memoryCacheCountLimit is 300.
    func testInitWithCustomMemoryCacheCountLimit() {
        let config = Configuration(memoryCacheCountLimit: 300)

        XCTAssertEqual(config.memoryCacheCountLimit, 300)
    }

    /// Verifies custom memory cache size is stored.
    ///
    /// Expected: memoryCacheSizeLimit is 200 MB.
    func testInitWithCustomMemoryCacheSizeLimit() {
        let config = Configuration(memoryCacheSizeLimit: 200 * 1024 * 1024)

        XCTAssertEqual(config.memoryCacheSizeLimit, 200 * 1024 * 1024)
    }

    /// Verifies all custom values can be set together.
    ///
    /// Expected: All values are correctly stored.
    func testInitWithAllCustomValues() {
        let config = Configuration(
            revalidationInterval: 120,
            revalidationThrottleInterval: 15,
            thumbnailMaxPixelSize: 500,
            memoryCacheCountLimit: 200,
            memoryCacheSizeLimit: 150 * 1024 * 1024
        )

        XCTAssertEqual(config.revalidationInterval, 120)
        XCTAssertEqual(config.revalidationThrottleInterval, 15)
        XCTAssertEqual(config.thumbnailMaxPixelSize, 500)
        XCTAssertEqual(config.memoryCacheCountLimit, 200)
        XCTAssertEqual(config.memoryCacheSizeLimit, 150 * 1024 * 1024)
    }

    // MARK: - Defaults Constants

    /// Verifies Defaults.revalidationInterval constant.
    ///
    /// Expected: Value is 30.
    func testDefaultsRevalidationInterval() {
        XCTAssertEqual(Configuration.Defaults.revalidationInterval, 30)
    }

    /// Verifies Defaults.revalidationThrottleInterval constant.
    ///
    /// Expected: Value is 5.
    func testDefaultsRevalidationThrottleInterval() {
        XCTAssertEqual(Configuration.Defaults.revalidationThrottleInterval, 5)
    }

    /// Verifies Defaults.thumbnailMaxPixelSize constant.
    ///
    /// Expected: Value is 400.
    func testDefaultsThumbnailMaxPixelSize() {
        XCTAssertEqual(Configuration.Defaults.thumbnailMaxPixelSize, 400)
    }

    /// Verifies Defaults.memoryCacheCountLimit constant.
    ///
    /// Expected: Value is 150.
    func testDefaultsMemoryCacheCountLimit() {
        XCTAssertEqual(Configuration.Defaults.memoryCacheCountLimit, 150)
    }

    /// Verifies Defaults.memoryCacheSizeLimit constant.
    ///
    /// Expected: Value is 100 MB.
    func testDefaultsMemoryCacheSizeLimit() {
        let expectedSize = 100 * 1024 * 1024
        XCTAssertEqual(Configuration.Defaults.memoryCacheSizeLimit, expectedSize)
    }

    // MARK: - Protocol Conformance

    /// Verifies Configuration conforms to Sendable.
    ///
    /// Required for Swift 6 concurrency safety.
    ///
    /// Expected: Can be assigned to Sendable type.
    func testConformsToSendableProtocol() {
        let config: Sendable = Configuration()
        XCTAssertNotNil(config)
    }

    // MARK: - Mutability

    /// Verifies revalidationInterval is mutable.
    ///
    /// Expected: Value can be changed after initialization.
    func testRevalidationIntervalIsMutable() {
        var config = Configuration()
        config.revalidationInterval = 90

        XCTAssertEqual(config.revalidationInterval, 90)
    }

    /// Verifies revalidationThrottleInterval is mutable.
    ///
    /// Expected: Value can be changed after initialization.
    func testRevalidationThrottleIntervalIsMutable() {
        var config = Configuration()
        config.revalidationThrottleInterval = 20

        XCTAssertEqual(config.revalidationThrottleInterval, 20)
    }
}

// MARK: - AsyncCachedImageConfigurationTests

/// Tests for the AsyncCachedImageConfiguration typealias.
///
/// This typealias provides a namespaced way to access Configuration,
/// avoiding naming conflicts with other Configuration types in the app.
@MainActor
final class AsyncCachedImageConfigurationTests: XCTestCase {
    /// Verifies typealias maps to Configuration.
    ///
    /// Expected: Can create Configuration via typealias.
    func testTypealiasExists() {
        let config: AsyncCachedImageConfiguration = Configuration()

        XCTAssertNotNil(config)
    }

    /// Verifies typealias can access shared instance.
    ///
    /// Expected: AsyncCachedImageConfiguration.shared is not nil.
    func testTypealiasAccessesSharedInstance() {
        let config = AsyncCachedImageConfiguration.shared

        XCTAssertNotNil(config)
    }
}
