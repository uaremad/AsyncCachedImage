//
//  AsyncCachedImage
//
//  Copyright © 2026 Jan-Hendrik Damerau.
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

// MARK: - MemoryCacheStorageTests

/// Tests for the MemoryCacheStorage class which provides synchronous cache access.
///
/// MemoryCacheStorage is responsible for:
/// - Thread-safe synchronous access to cached images
/// - Enabling flicker-free view initialization
/// - Sharing storage backend with MemoryCache actor
///
/// These tests verify that synchronous access works correctly and is
/// safe to use during SwiftUI view initialization.
final class MemoryCacheStorageTests: XCTestCase {
    // MARK: - Test Data

    private var testURL: URL {
        guard let url = URL(string: "https://cdn.manasuite.com/card_sets/artwork/sld_300_landscape.jpg") else {
            preconditionFailure("Invalid test URL")
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
    /// Expected: MemoryCacheStorage.shared returns a non-nil instance.
    func testSharedInstanceExists() {
        let storage = MemoryCacheStorage.shared
        XCTAssertNotNil(storage)
    }

    // MARK: - Synchronous Access

    /// Verifies synchronous storage access returns stored image.
    ///
    /// MemoryCacheStorage provides sync access for view initialization,
    /// preventing flicker during re-renders.
    ///
    /// Expected: Synchronous lookup returns the stored image.
    func testSyncAccessReturnsStoredImage() async {
        let image = testImage

        await MemoryCache.shared.store(image, for: testURL, thumb: false)

        let retrieved = MemoryCacheStorage.shared.image(for: testURL, thumb: false)

        XCTAssertNotNil(retrieved)
    }

    /// Verifies synchronous storage returns nil for non-existent entries.
    ///
    /// Expected: Returns nil when no image is stored.
    func testSyncAccessReturnsNilForNonExistent() {
        let retrieved = MemoryCacheStorage.shared.image(for: testURL, thumb: false)

        XCTAssertNil(retrieved)
    }

    /// Verifies synchronous storage respects thumb flag.
    ///
    /// Full-size and thumbnail variants are stored separately.
    /// Sync access must return the correct variant.
    ///
    /// Expected: Correct variant is returned based on thumb flag.
    func testSyncAccessRespectsThumbnailFlag() async {
        let fullImage = createTestImage(width: 200, height: 200)
        let thumbImage = createTestImage(width: 50, height: 50)

        await MemoryCache.shared.store(fullImage, for: testURL, thumb: false)
        await MemoryCache.shared.store(thumbImage, for: testURL, thumb: true)

        let retrievedFull = MemoryCacheStorage.shared.image(for: testURL, thumb: false)
        let retrievedThumb = MemoryCacheStorage.shared.image(for: testURL, thumb: true)

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

    // MARK: - Storage Consistency

    /// Verifies synchronous and async APIs access the same underlying storage.
    ///
    /// Both MemoryCache (async) and MemoryCacheStorage (sync) should
    /// return the same images for the same keys.
    ///
    /// Expected: Both methods return identical images.
    func testStorageAndCacheShareSameData() async {
        let image = testImage

        await MemoryCache.shared.store(image, for: testURL, thumb: false)

        let syncResult = MemoryCacheStorage.shared.image(for: testURL, thumb: false)
        let asyncResult = await MemoryCache.shared.image(for: testURL, thumb: false)

        XCTAssertNotNil(syncResult)
        XCTAssertNotNil(asyncResult)
        XCTAssertTrue(syncResult === asyncResult)
    }

    // MARK: - Thread Safety

    /// Verifies synchronous access is safe during concurrent async writes.
    ///
    /// NSCache is thread-safe, so sync reads during concurrent async writes
    /// should not crash.
    ///
    /// Expected: No crashes and final result is valid.
    func testSyncAccessDuringConcurrentWrites() async {
        let images = (0 ..< 5).map { _ in createTestImage(width: 50, height: 50) }
        let url = testURL

        await withTaskGroup(of: Void.self) { group in
            for image in images {
                group.addTask {
                    await MemoryCache.shared.store(image, for: url, thumb: false)
                }
                group.addTask {
                    _ = MemoryCacheStorage.shared.image(for: url, thumb: false)
                }
            }
        }

        let finalResult = MemoryCacheStorage.shared.image(for: testURL, thumb: false)
        XCTAssertNotNil(finalResult)
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
