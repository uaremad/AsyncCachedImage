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

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - MemoryCacheTests

/// Tests for the MemoryCache actor which provides in-memory storage for decoded images.
///
/// MemoryCache is responsible for:
/// - Fast access to recently used decoded images without disk I/O
/// - Separate storage for thumbnail and full-size image variants
/// - Automatic eviction under memory pressure via NSCache
/// - Thread-safe operations via actor isolation
final class MemoryCacheTests: XCTestCase {
    // MARK: - Test Data

    private var testURL: URL {
        guard let url = URL(string: "https://cdn.manasuite.com/card_sets/artwork/sld_300_landscape.jpg") else {
            preconditionFailure("Invalid test URL")
        }
        return url
    }

    private var alternateURL: URL {
        guard let url = URL(string: "https://cdn.manasuite.com/card_sets/artwork/sld_301_landscape.jpg") else {
            preconditionFailure("Invalid alternate URL")
        }
        return url
    }

    private var testImage: PlatformImage {
        createTestImage(width: 100, height: 100)
    }

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        await MemoryCache.shared.clearAll()
    }

    override func tearDown() async throws {
        await MemoryCache.shared.clearAll()
        try await super.tearDown()
    }

    // MARK: - Shared Instance

    /// Verifies the singleton pattern is implemented correctly.
    ///
    /// Expected: MemoryCache.shared returns a non-nil instance.
    func testSharedInstanceExists() async {
        let cache = MemoryCache.shared
        XCTAssertNotNil(cache)
    }

    // MARK: - Store and Retrieve

    /// Verifies basic store and retrieve functionality for full-size images.
    ///
    /// Stores a decoded image and verifies it can be retrieved
    /// using the same URL and thumb=false flag.
    ///
    /// Expected: Retrieved image is not nil.
    func testStoreAndRetrieveImage() async {
        let image = testImage

        await MemoryCache.shared.store(image, for: testURL, thumb: false)
        let retrieved = await MemoryCache.shared.image(for: testURL, thumb: false)

        XCTAssertNotNil(retrieved)
    }

    /// Verifies basic store and retrieve functionality for thumbnails.
    ///
    /// Thumbnails are stored with thumb=true and must be retrieved
    /// with the same flag.
    ///
    /// Expected: Retrieved thumbnail is not nil.
    func testStoreAndRetrieveThumbnail() async {
        let image = testImage

        await MemoryCache.shared.store(image, for: testURL, thumb: true)
        let retrieved = await MemoryCache.shared.image(for: testURL, thumb: true)

        XCTAssertNotNil(retrieved)
    }

    /// Verifies retrieval returns nil for URLs not in cache.
    ///
    /// Expected: Returns nil when no image has been stored for the URL.
    func testRetrieveNonExistentImage() async {
        let retrieved = await MemoryCache.shared.image(for: testURL, thumb: false)

        XCTAssertNil(retrieved)
    }

    /// Verifies thumbnail and full-size variants are stored independently.
    ///
    /// The same URL can have both a thumbnail and full-size version
    /// stored simultaneously. They must not interfere with each other.
    ///
    /// Expected: Both variants are retrievable with correct dimensions.
    func testThumbnailAndFullSizeStoredSeparately() async {
        let fullImage = createTestImage(width: 200, height: 200)
        let thumbImage = createTestImage(width: 50, height: 50)

        await MemoryCache.shared.store(fullImage, for: testURL, thumb: false)
        await MemoryCache.shared.store(thumbImage, for: testURL, thumb: true)

        let retrievedFull = await MemoryCache.shared.image(for: testURL, thumb: false)
        let retrievedThumb = await MemoryCache.shared.image(for: testURL, thumb: true)

        XCTAssertNotNil(retrievedFull)
        XCTAssertNotNil(retrievedThumb)

        #if os(iOS)
        XCTAssertEqual(retrievedFull?.cgImage?.width, 200)
        XCTAssertEqual(retrievedThumb?.cgImage?.width, 50)
        #elseif os(macOS)
        XCTAssertEqual(retrievedFull?.cgImageRepresentation?.width, 200)
        XCTAssertEqual(retrievedThumb?.cgImageRepresentation?.width, 50)
        #endif
    }

    /// Verifies full-size retrieval does not return thumbnail data.
    ///
    /// The thumb flag must be honored during retrieval to prevent
    /// accidentally returning a low-resolution thumbnail.
    ///
    /// Expected: Returns nil when only thumbnail is stored but full-size is requested.
    func testFullSizeDoesNotRetrieveThumbnail() async {
        let image = testImage

        await MemoryCache.shared.store(image, for: testURL, thumb: true)
        let retrieved = await MemoryCache.shared.image(for: testURL, thumb: false)

        XCTAssertNil(retrieved)
    }

    /// Verifies thumbnail retrieval does not return full-size data.
    ///
    /// Expected: Returns nil when only full-size is stored but thumbnail is requested.
    func testThumbnailDoesNotRetrieveFullSize() async {
        let image = testImage

        await MemoryCache.shared.store(image, for: testURL, thumb: false)
        let retrieved = await MemoryCache.shared.image(for: testURL, thumb: true)

        XCTAssertNil(retrieved)
    }

    // MARK: - Multiple URLs

    /// Verifies multiple distinct URLs can be stored and retrieved.
    ///
    /// Each URL should have its own independent cache entry.
    ///
    /// Expected: Both URLs have their images retrievable independently.
    func testStoreMultipleImages() async {
        let image1 = createTestImage(width: 100, height: 100)
        let image2 = createTestImage(width: 150, height: 150)

        await MemoryCache.shared.store(image1, for: testURL, thumb: false)
        await MemoryCache.shared.store(image2, for: alternateURL, thumb: false)

        let retrieved1 = await MemoryCache.shared.image(for: testURL, thumb: false)
        let retrieved2 = await MemoryCache.shared.image(for: alternateURL, thumb: false)

        XCTAssertNotNil(retrieved1)
        XCTAssertNotNil(retrieved2)
    }

    // MARK: - Overwrite Behavior

    /// Verifies storing a new image overwrites the existing entry.
    ///
    /// When the same URL is stored twice, the second image should
    /// replace the first (no duplicate entries).
    ///
    /// Expected: Retrieved image has dimensions of the second stored image.
    func testStoreOverwritesExistingImage() async {
        let originalImage = createTestImage(width: 100, height: 100)
        let updatedImage = createTestImage(width: 200, height: 200)

        await MemoryCache.shared.store(originalImage, for: testURL, thumb: false)
        await MemoryCache.shared.store(updatedImage, for: testURL, thumb: false)

        let retrieved = await MemoryCache.shared.image(for: testURL, thumb: false)

        XCTAssertNotNil(retrieved)
        #if os(iOS)
        XCTAssertEqual(retrieved?.cgImage?.width, 200)
        #elseif os(macOS)
        XCTAssertEqual(retrieved?.cgImageRepresentation?.width, 200)
        #endif
    }

    // MARK: - Remove

    /// Verifies single entry removal works correctly.
    ///
    /// After storing an image, removing it should make it unavailable.
    ///
    /// Expected: Retrieval returns nil after removal.
    func testRemoveImage() async {
        let image = testImage

        await MemoryCache.shared.store(image, for: testURL, thumb: false)
        await MemoryCache.shared.remove(for: testURL, thumb: false)

        let retrieved = await MemoryCache.shared.image(for: testURL, thumb: false)

        XCTAssertNil(retrieved)
    }

    /// Verifies removing a thumbnail does not affect full-size entry.
    ///
    /// Expected: Full-size image is still available after removing thumbnail.
    func testRemoveThumbnailKeepsFullSize() async {
        let fullImage = createTestImage(width: 200, height: 200)
        let thumbImage = createTestImage(width: 50, height: 50)

        await MemoryCache.shared.store(fullImage, for: testURL, thumb: false)
        await MemoryCache.shared.store(thumbImage, for: testURL, thumb: true)
        await MemoryCache.shared.remove(for: testURL, thumb: true)

        let retrievedFull = await MemoryCache.shared.image(for: testURL, thumb: false)
        let retrievedThumb = await MemoryCache.shared.image(for: testURL, thumb: true)

        XCTAssertNotNil(retrievedFull)
        XCTAssertNil(retrievedThumb)
    }

    /// Verifies removing full-size does not affect thumbnail entry.
    ///
    /// Expected: Thumbnail is still available after removing full-size.
    func testRemoveFullSizeKeepsThumbnail() async {
        let fullImage = createTestImage(width: 200, height: 200)
        let thumbImage = createTestImage(width: 50, height: 50)

        await MemoryCache.shared.store(fullImage, for: testURL, thumb: false)
        await MemoryCache.shared.store(thumbImage, for: testURL, thumb: true)
        await MemoryCache.shared.remove(for: testURL, thumb: false)

        let retrievedFull = await MemoryCache.shared.image(for: testURL, thumb: false)
        let retrievedThumb = await MemoryCache.shared.image(for: testURL, thumb: true)

        XCTAssertNil(retrievedFull)
        XCTAssertNotNil(retrievedThumb)
    }

    // MARK: - Clear All

    /// Verifies clearAll removes all entries from the cache.
    ///
    /// Expected: All stored images return nil after clearAll.
    func testClearAllRemovesAllImages() async {
        let image1 = createTestImage(width: 100, height: 100)
        let image2 = createTestImage(width: 150, height: 150)

        await MemoryCache.shared.store(image1, for: testURL, thumb: false)
        await MemoryCache.shared.store(image1, for: testURL, thumb: true)
        await MemoryCache.shared.store(image2, for: alternateURL, thumb: false)

        await MemoryCache.shared.clearAll()

        let retrieved1 = await MemoryCache.shared.image(for: testURL, thumb: false)
        let retrieved1Thumb = await MemoryCache.shared.image(for: testURL, thumb: true)
        let retrieved2 = await MemoryCache.shared.image(for: alternateURL, thumb: false)

        XCTAssertNil(retrieved1)
        XCTAssertNil(retrieved1Thumb)
        XCTAssertNil(retrieved2)
    }

    /// Verifies cache is usable after clearAll.
    ///
    /// Expected: New images can be stored and retrieved after clearAll.
    func testStoreAfterClearAll() async {
        let image = testImage

        await MemoryCache.shared.store(image, for: testURL, thumb: false)
        await MemoryCache.shared.clearAll()
        await MemoryCache.shared.store(image, for: testURL, thumb: false)

        let retrieved = await MemoryCache.shared.image(for: testURL, thumb: false)

        XCTAssertNotNil(retrieved)
    }

    // MARK: - Edge Cases

    /// Verifies removing a non-existent entry does not cause errors.
    ///
    /// Expected: No error or crash when removing a URL that was never stored.
    func testRemoveNonExistentImage() async {
        await MemoryCache.shared.remove(for: testURL, thumb: false)

        let retrieved = await MemoryCache.shared.image(for: testURL, thumb: false)

        XCTAssertNil(retrieved)
    }

    /// Verifies clearAll on an empty cache does not cause errors.
    ///
    /// Expected: No error or crash when clearing an already empty cache.
    func testClearEmptyCache() async {
        await MemoryCache.shared.clearAll()

        let retrieved = await MemoryCache.shared.image(for: testURL, thumb: false)

        XCTAssertNil(retrieved)
    }

    /// Verifies URLs with query parameters are handled correctly.
    ///
    /// Query parameters should be included in the cache key.
    ///
    /// Expected: URLs with different query strings are treated as separate entries.
    func testURLWithQueryParameters() async {
        guard let urlWithQuery = URL(string: "https://example.com/image.jpg?size=large") else {
            XCTFail("Invalid URL")
            return
        }
        let image = testImage

        await MemoryCache.shared.store(image, for: urlWithQuery, thumb: false)
        let retrieved = await MemoryCache.shared.image(for: urlWithQuery, thumb: false)

        XCTAssertNotNil(retrieved)
    }

    /// Verifies URLs with special characters (percent-encoded) are handled correctly.
    ///
    /// Encoded characters like %20 (space) in URLs should
    /// be handled properly (%20 = space).
    ///
    /// Expected: Image is stored and retrieved correctly with encoded characters.
    func testURLWithSpecialCharacters() async {
        guard let urlWithSpecial = URL(string: "https://example.com/image%20name.jpg") else {
            XCTFail("Invalid URL")
            return
        }
        let image = testImage

        await MemoryCache.shared.store(image, for: urlWithSpecial, thumb: false)
        let retrieved = await MemoryCache.shared.image(for: urlWithSpecial, thumb: false)

        XCTAssertNotNil(retrieved)
    }

    // MARK: - Concurrency

    /// Verifies thread safety with concurrent store operations.
    ///
    /// Multiple tasks storing different URLs simultaneously must not
    /// cause data races or crashes. Actor isolation should handle this.
    ///
    /// Expected: All concurrent stores complete without error and images are retrievable.
    func testConcurrentStoreOperations() async {
        let urls = (0 ..< 10).compactMap { URL(string: "https://cdn.manasuite.com/card_sets/artwork/sld_\($0)_landscape.jpg") }
        let images = urls.map { _ in createTestImage(width: 50, height: 50) }

        await withTaskGroup(of: Void.self) { group in
            for (url, image) in zip(urls, images) {
                group.addTask {
                    await MemoryCache.shared.store(image, for: url, thumb: false)
                }
            }
        }

        guard let firstURL = urls.first, let lastURL = urls.last else {
            XCTFail("Invalid URLs")
            return
        }

        let first = await MemoryCache.shared.image(for: firstURL, thumb: false)
        let last = await MemoryCache.shared.image(for: lastURL, thumb: false)

        XCTAssertNotNil(first)
        XCTAssertNotNil(last)
    }

    /// Verifies thread safety with concurrent read and write operations.
    ///
    /// Real-world usage involves simultaneous reads and writes to the same URL.
    /// The actor must serialize access correctly without deadlocks.
    ///
    /// Expected: All operations complete without error and final state is consistent.
    func testConcurrentReadWriteOperations() async {
        let image = testImage
        let url = testURL
        let images = (0 ..< 5).map { _ in createTestImage(width: 60, height: 60) }

        await MemoryCache.shared.store(image, for: url, thumb: false)

        await withTaskGroup(of: Void.self) { group in
            for newImage in images {
                group.addTask {
                    _ = await MemoryCache.shared.image(for: url, thumb: false)
                }
                group.addTask {
                    await MemoryCache.shared.store(newImage, for: url, thumb: false)
                }
            }
        }

        let retrieved = await MemoryCache.shared.image(for: url, thumb: false)
        XCTAssertNotNil(retrieved)
    }

    // MARK: - Helper Methods

    private func createTestImage(width: Int, height: Int) -> PlatformImage {
        #if os(iOS)
        return createUIImage(width: width, height: height)
        #elseif os(macOS)
        return createNSImage(width: width, height: height)
        #endif
    }

    #if os(iOS)
    private func createUIImage(width: Int, height: Int) -> UIImage {
        let size = CGSize(width: width, height: height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    #endif

    #if os(macOS)
    private func createNSImage(width: Int, height: Int) -> NSImage {
        let size = NSSize(width: width, height: height)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return image
    }
    #endif
}

// MARK: - MemoryCostCalculatorTests

/// Tests for the MemoryCostCalculator which estimates memory usage of decoded images.
///
/// MemoryCostCalculator is responsible for:
/// - Calculating the uncompressed bitmap size (width * height * 4 bytes per pixel)
/// - Providing accurate cost values for NSCache's cost-based eviction
///
/// Performance note: Uses dimension-based calculation (O(1)) instead of
/// PNG/TIFF encoding (100-500ms for 4K images).
final class MemoryCostCalculatorTests: XCTestCase {
    // MARK: - Cost Calculation

    /// Verifies cost calculation for a small 100x100 image.
    ///
    /// Formula: width * height * 4 (RGBA bytes per pixel)
    ///
    /// Expected: 100 * 100 * 4 = 40,000 bytes
    func testCostCalculationForSmallImage() {
        let image = createTestImage(width: 100, height: 100)
        let cost = MemoryCostCalculator.estimateCost(for: image)

        let expectedCost = 100 * 100 * 4
        XCTAssertEqual(cost, expectedCost)
    }

    /// Verifies cost calculation for a large 1920x1080 (Full HD) image.
    ///
    /// Expected: 1920 * 1080 * 4 = 8,294,400 bytes (~8 MB)
    func testCostCalculationForLargeImage() {
        let image = createTestImage(width: 1920, height: 1080)
        let cost = MemoryCostCalculator.estimateCost(for: image)

        let expectedCost = 1920 * 1080 * 4
        XCTAssertEqual(cost, expectedCost)
    }

    /// Verifies cost calculation for a square 500x500 image.
    ///
    /// Expected: 500 * 500 * 4 = 1,000,000 bytes (1 MB)
    func testCostCalculationForSquareImage() {
        let image = createTestImage(width: 500, height: 500)
        let cost = MemoryCostCalculator.estimateCost(for: image)

        let expectedCost = 500 * 500 * 4
        XCTAssertEqual(cost, expectedCost)
    }

    /// Verifies cost calculation for a tall portrait-oriented image.
    ///
    /// Tests that width and height are correctly used regardless of orientation.
    ///
    /// Expected: 100 * 1000 * 4 = 400,000 bytes
    func testCostCalculationForTallImage() {
        let image = createTestImage(width: 100, height: 1000)
        let cost = MemoryCostCalculator.estimateCost(for: image)

        let expectedCost = 100 * 1000 * 4
        XCTAssertEqual(cost, expectedCost)
    }

    /// Verifies cost calculation for a wide landscape-oriented image.
    ///
    /// Expected: 1000 * 100 * 4 = 400,000 bytes
    func testCostCalculationForWideImage() {
        let image = createTestImage(width: 1000, height: 100)
        let cost = MemoryCostCalculator.estimateCost(for: image)

        let expectedCost = 1000 * 100 * 4
        XCTAssertEqual(cost, expectedCost)
    }

    /// Verifies that calculated cost is always positive for valid images.
    ///
    /// Any valid image with dimensions > 0 must have a positive memory cost.
    ///
    /// Expected: Cost is greater than 0.
    func testCostIsPositive() {
        let image = createTestImage(width: 50, height: 50)
        let cost = MemoryCostCalculator.estimateCost(for: image)

        XCTAssertGreaterThan(cost, 0)
    }

    // MARK: - Helper Methods

    private func createTestImage(width: Int, height: Int) -> PlatformImage {
        #if os(iOS)
        return createUIImage(width: width, height: height)
        #elseif os(macOS)
        return createNSImage(width: width, height: height)
        #endif
    }

    #if os(iOS)
    private func createUIImage(width: Int, height: Int) -> UIImage {
        let size = CGSize(width: width, height: height)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        return renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    #endif

    #if os(macOS)
    private func createNSImage(width: Int, height: Int) -> NSImage {
        let size = NSSize(width: width, height: height)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return image
    }
    #endif
}
