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

// MARK: - CacheManagerTests

/// Tests for CacheManager which coordinates all cache operations.
///
/// CacheManager provides a unified interface for:
/// - Cache statistics (info property)
/// - Cache clearing (clearAll, clearMemoryOnly)
/// - Entry management (removeEntry, getAllEntries)
///
/// It coordinates MemoryCache, DiskCache (URLCache), and MetadataStore.
final class CacheManagerTests: XCTestCase {
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

    private var testMetadata: Metadata {
        Metadata(etag: "test-etag", lastModified: "Mon, 01 Jan 2025 00:00:00 GMT")
    }

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        await CacheManager.shared.clearAll()
    }

    override func tearDown() async throws {
        await CacheManager.shared.clearAll()
        try await super.tearDown()
    }

    // MARK: - Shared Instance

    /// Verifies shared singleton instance exists.
    ///
    /// Expected: CacheManager.shared is not nil.
    func testSharedInstanceExists() async {
        let manager = CacheManager.shared

        XCTAssertNotNil(manager)
    }

    // MARK: - Cache Info

    /// Verifies info property returns CacheInfo.
    ///
    /// Expected: Info is not nil.
    func testInfoReturnsCacheInfo() async {
        let info = await CacheManager.shared.info

        XCTAssertNotNil(info)
    }

    /// Verifies disk usage is non-negative.
    ///
    /// Expected: diskUsedBytes >= 0.
    func testInfoHasNonNegativeDiskUsage() async {
        let info = await CacheManager.shared.info

        XCTAssertGreaterThanOrEqual(info.diskUsedBytes, 0)
    }

    /// Verifies disk capacity is positive.
    ///
    /// URLCache is configured with 500 MB disk capacity.
    ///
    /// Expected: diskCapacityBytes > 0.
    func testInfoHasPositiveDiskCapacity() async {
        let info = await CacheManager.shared.info

        XCTAssertGreaterThan(info.diskCapacityBytes, 0)
    }

    /// Verifies memory usage is non-negative.
    ///
    /// Expected: memoryUsedBytes >= 0.
    func testInfoHasNonNegativeMemoryUsage() async {
        let info = await CacheManager.shared.info

        XCTAssertGreaterThanOrEqual(info.memoryUsedBytes, 0)
    }

    /// Verifies memory capacity is positive.
    ///
    /// URLCache is configured with 100 MB memory capacity.
    ///
    /// Expected: memoryCapacityBytes > 0.
    func testInfoHasPositiveMemoryCapacity() async {
        let info = await CacheManager.shared.info

        XCTAssertGreaterThan(info.memoryCapacityBytes, 0)
    }

    /// Verifies entry count matches MetadataStore.
    ///
    /// Expected: cachedEntryCount equals stored metadata count.
    func testInfoEntryCountMatchesMetadataStore() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)
        await MetadataStore.shared.store(testMetadata, for: alternateURL, thumb: false)

        let info = await CacheManager.shared.info

        XCTAssertEqual(info.cachedEntryCount, 2)
    }

    // MARK: - Clear All

    /// Verifies clearAll removes metadata.
    ///
    /// Expected: Metadata is nil after clearAll.
    func testClearAllRemovesMetadata() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)

        await CacheManager.shared.clearAll()

        let metadata = await MetadataStore.shared.metadata(for: testURL, thumb: false)
        XCTAssertNil(metadata)
    }

    /// Verifies clearAll removes memory cache.
    ///
    /// Expected: Cached image is nil after clearAll.
    func testClearAllRemovesMemoryCache() async {
        await MemoryCache.shared.store(testImage, for: testURL, thumb: false)

        await CacheManager.shared.clearAll()

        let cached = await MemoryCache.shared.image(for: testURL, thumb: false)
        XCTAssertNil(cached)
    }

    /// Verifies clearAll sets entry count to zero.
    ///
    /// Expected: cachedEntryCount is 0.
    func testClearAllSetsEntryCountToZero() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)
        await MetadataStore.shared.store(testMetadata, for: alternateURL, thumb: false)

        await CacheManager.shared.clearAll()

        let info = await CacheManager.shared.info
        XCTAssertEqual(info.cachedEntryCount, 0)
    }

    // MARK: - Clear Memory Only

    /// Verifies clearMemoryOnly removes memory cache.
    ///
    /// Expected: Cached image is nil.
    func testClearMemoryOnlyRemovesMemoryCache() async {
        await MemoryCache.shared.store(testImage, for: testURL, thumb: false)

        await CacheManager.shared.clearMemoryOnly()

        let cached = await MemoryCache.shared.image(for: testURL, thumb: false)
        XCTAssertNil(cached)
    }

    /// Verifies clearMemoryOnly preserves metadata.
    ///
    /// Metadata is on disk, not affected by memory clear.
    ///
    /// Expected: Metadata is still present.
    func testClearMemoryOnlyPreservesMetadata() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)

        await CacheManager.shared.clearMemoryOnly()

        let metadata = await MetadataStore.shared.metadata(for: testURL, thumb: false)
        XCTAssertNotNil(metadata)
    }

    // MARK: - Remove Entry

    /// Verifies removeEntry removes from memory cache.
    ///
    /// Expected: Cached image is nil.
    func testRemoveEntryRemovesFromMemoryCache() async {
        await MemoryCache.shared.store(testImage, for: testURL, thumb: false)

        await CacheManager.shared.removeEntry(for: testURL, thumb: false)

        let cached = await MemoryCache.shared.image(for: testURL, thumb: false)
        XCTAssertNil(cached)
    }

    /// Verifies removeEntry removes from metadata store.
    ///
    /// Expected: Metadata is nil.
    func testRemoveEntryRemovesFromMetadataStore() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)

        await CacheManager.shared.removeEntry(for: testURL, thumb: false)

        let metadata = await MetadataStore.shared.metadata(for: testURL, thumb: false)
        XCTAssertNil(metadata)
    }

    /// Verifies removeEntry doesn't affect other entries.
    ///
    /// Expected: Other URL's metadata is preserved.
    func testRemoveEntryDoesNotAffectOtherEntries() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)
        await MetadataStore.shared.store(testMetadata, for: alternateURL, thumb: false)

        await CacheManager.shared.removeEntry(for: testURL, thumb: false)

        let removedMetadata = await MetadataStore.shared.metadata(for: testURL, thumb: false)
        let preservedMetadata = await MetadataStore.shared.metadata(for: alternateURL, thumb: false)

        XCTAssertNil(removedMetadata)
        XCTAssertNotNil(preservedMetadata)
    }

    /// Verifies removing thumbnail doesn't affect full-size.
    ///
    /// Thumbnail and full-size are separate entries.
    ///
    /// Expected: Full-size remains after thumbnail removal.
    func testRemoveEntryThumbnailDoesNotAffectFullSize() async {
        await MemoryCache.shared.store(testImage, for: testURL, thumb: false)
        await MemoryCache.shared.store(testImage, for: testURL, thumb: true)
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: true)

        await CacheManager.shared.removeEntry(for: testURL, thumb: true)

        let fullSizeImage = await MemoryCache.shared.image(for: testURL, thumb: false)
        let thumbnailImage = await MemoryCache.shared.image(for: testURL, thumb: true)
        let fullSizeMetadata = await MetadataStore.shared.metadata(for: testURL, thumb: false)
        let thumbnailMetadata = await MetadataStore.shared.metadata(for: testURL, thumb: true)

        XCTAssertNotNil(fullSizeImage)
        XCTAssertNil(thumbnailImage)
        XCTAssertNotNil(fullSizeMetadata)
        XCTAssertNil(thumbnailMetadata)
    }

    // MARK: - Get All Entries

    /// Verifies getAllEntries returns empty array when no entries.
    ///
    /// Expected: Empty array.
    func testGetAllEntriesReturnsEmptyWhenNoEntries() async {
        let entries = await CacheManager.shared.getAllEntries()

        XCTAssertTrue(entries.isEmpty)
    }

    /// Verifies getAllEntries returns stored entries.
    ///
    /// Expected: Array count matches stored count.
    func testGetAllEntriesReturnsStoredEntries() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)
        await MetadataStore.shared.store(testMetadata, for: alternateURL, thumb: false)

        let entries = await CacheManager.shared.getAllEntries()

        XCTAssertEqual(entries.count, 2)
    }

    /// Verifies getAllEntries includes thumbnails.
    ///
    /// Both full-size and thumbnail entries should be returned.
    ///
    /// Expected: Array count is 2, contains both variants.
    func testGetAllEntriesIncludesThumbnails() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: true)

        let entries = await CacheManager.shared.getAllEntries()

        XCTAssertEqual(entries.count, 2)

        let thumbnailEntry = entries.first { $0.isThumb }
        let fullSizeEntry = entries.first { !$0.isThumb }

        XCTAssertNotNil(thumbnailEntry)
        XCTAssertNotNil(fullSizeEntry)
    }

    /// Verifies getAllEntries contains correct URLs.
    ///
    /// Expected: Entry URL matches stored URL.
    func testGetAllEntriesContainsCorrectURLs() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)

        let entries = await CacheManager.shared.getAllEntries()

        XCTAssertEqual(entries.first?.url, testURL)
    }

    /// Verifies getAllEntries contains metadata.
    ///
    /// Expected: Entry metadata matches stored values.
    func testGetAllEntriesContainsMetadata() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)

        let entries = await CacheManager.shared.getAllEntries()

        XCTAssertEqual(entries.first?.metadata?.etag, testMetadata.etag)
    }

    /// Verifies getAllEntries sorts by date, newest first.
    ///
    /// Expected: Newer entry comes first in array.
    func testGetAllEntriesSortedByDateNewestFirst() async {
        let olderMetadata = Metadata(
            etag: "old",
            lastModified: nil,
            cachedAt: Date(timeIntervalSinceNow: -3600)
        )
        let newerMetadata = Metadata(
            etag: "new",
            lastModified: nil,
            cachedAt: Date()
        )

        await MetadataStore.shared.store(olderMetadata, for: testURL, thumb: false)
        await MetadataStore.shared.store(newerMetadata, for: alternateURL, thumb: false)

        let entries = await CacheManager.shared.getAllEntries()

        XCTAssertEqual(entries.first?.metadata?.etag, "new")
        XCTAssertEqual(entries.last?.metadata?.etag, "old")
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
        let renderer = UIGraphicsImageRenderer(size: size)
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
