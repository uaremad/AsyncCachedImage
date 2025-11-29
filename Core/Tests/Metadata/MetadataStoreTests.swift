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

// MARK: - MetadataStoreTests

/// Tests for the MetadataStore actor which persists cache metadata as JSON files.
///
/// MetadataStore responsibilities:
/// - Store/retrieve Metadata keyed by URL and thumbnail flag
/// - Persist as base64-encoded JSON files in Caches/Metadata/
/// - Provide entry count and list all entries for cache browser
/// - Thread-safe via actor isolation
final class MetadataStoreTests: XCTestCase {
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

    private var testMetadata: Metadata {
        Metadata(etag: "test-etag-123", lastModified: "Mon, 01 Jan 2025 00:00:00 GMT")
    }

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        await MetadataStore.shared.removeAll()
    }

    override func tearDown() async throws {
        await MetadataStore.shared.removeAll()
        try await super.tearDown()
    }

    // MARK: - Shared Instance

    /// Verifies shared singleton instance exists.
    ///
    /// Expected: MetadataStore.shared is not nil.
    func testSharedInstanceExists() async {
        let store = MetadataStore.shared
        XCTAssertNotNil(store)
    }

    /// Verifies shared instance is a true singleton.
    ///
    /// Both references should point to the same underlying storage.
    ///
    /// Expected: Entry counts are identical.
    func testSharedInstanceIsSingleton() async {
        let store1 = MetadataStore.shared
        let store2 = MetadataStore.shared

        let count1 = await store1.entryCount()
        let count2 = await store2.entryCount()

        XCTAssertEqual(count1, count2)
    }

    // MARK: - Store and Retrieve

    /// Verifies basic store and retrieve functionality.
    ///
    /// Expected: Retrieved metadata matches stored metadata.
    func testStoreAndRetrieveMetadata() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)

        let retrieved = await MetadataStore.shared.metadata(for: testURL, thumb: false)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.etag, testMetadata.etag)
        XCTAssertEqual(retrieved?.lastModified, testMetadata.lastModified)
    }

    /// Verifies thumbnail metadata is stored separately.
    ///
    /// Expected: Thumbnail metadata can be stored and retrieved.
    func testStoreAndRetrieveThumbnailMetadata() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: true)

        let retrieved = await MetadataStore.shared.metadata(for: testURL, thumb: true)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved?.etag, testMetadata.etag)
    }

    /// Verifies retrieval of non-existent metadata returns nil.
    ///
    /// Expected: Returns nil for URLs that haven't been stored.
    func testRetrieveNonExistentMetadata() async {
        let retrieved = await MetadataStore.shared.metadata(for: testURL, thumb: false)

        XCTAssertNil(retrieved)
    }

    /// Verifies thumbnail and full-size are stored independently.
    ///
    /// The same URL can have different metadata for thumb vs full-size.
    ///
    /// Expected: Each variant has its own distinct metadata.
    func testThumbnailAndFullSizeStoredSeparately() async {
        let fullMetadata = Metadata(etag: "full-etag", lastModified: nil)
        let thumbMetadata = Metadata(etag: "thumb-etag", lastModified: nil)

        await MetadataStore.shared.store(fullMetadata, for: testURL, thumb: false)
        await MetadataStore.shared.store(thumbMetadata, for: testURL, thumb: true)

        let retrievedFull = await MetadataStore.shared.metadata(for: testURL, thumb: false)
        let retrievedThumb = await MetadataStore.shared.metadata(for: testURL, thumb: true)

        XCTAssertEqual(retrievedFull?.etag, "full-etag")
        XCTAssertEqual(retrievedThumb?.etag, "thumb-etag")
    }

    // MARK: - Overwrite Behavior

    /// Verifies storing overwrites existing metadata.
    ///
    /// Expected: Second store replaces first store's metadata.
    func testStoreOverwritesExistingMetadata() async {
        let originalMetadata = Metadata(etag: "original", lastModified: nil)
        let updatedMetadata = Metadata(etag: "updated", lastModified: nil)

        await MetadataStore.shared.store(originalMetadata, for: testURL, thumb: false)
        await MetadataStore.shared.store(updatedMetadata, for: testURL, thumb: false)

        let retrieved = await MetadataStore.shared.metadata(for: testURL, thumb: false)

        XCTAssertEqual(retrieved?.etag, "updated")
    }

    // MARK: - Remove

    /// Verifies remove deletes metadata for a URL.
    ///
    /// Expected: Metadata returns nil after removal.
    func testRemoveMetadata() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)
        await MetadataStore.shared.remove(for: testURL, thumb: false)

        let retrieved = await MetadataStore.shared.metadata(for: testURL, thumb: false)

        XCTAssertNil(retrieved)
    }

    /// Verifies removing thumbnail doesn't affect full-size.
    ///
    /// Expected: Full-size remains after thumbnail removal.
    func testRemoveThumbnailDoesNotAffectFullSize() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: true)

        await MetadataStore.shared.remove(for: testURL, thumb: true)

        let fullSize = await MetadataStore.shared.metadata(for: testURL, thumb: false)
        let thumbnail = await MetadataStore.shared.metadata(for: testURL, thumb: true)

        XCTAssertNotNil(fullSize)
        XCTAssertNil(thumbnail)
    }

    /// Verifies removing non-existent metadata doesn't throw.
    ///
    /// Defensive behavior - remove should be safe for any URL.
    ///
    /// Expected: No error is thrown.
    func testRemoveNonExistentMetadataDoesNotThrow() async {
        await MetadataStore.shared.remove(for: testURL, thumb: false)
    }

    // MARK: - Remove All

    /// Verifies removeAll clears all stored metadata.
    ///
    /// Expected: Entry count is 0 after removeAll.
    func testRemoveAll() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: true)
        await MetadataStore.shared.store(testMetadata, for: alternateURL, thumb: false)

        await MetadataStore.shared.removeAll()

        let count = await MetadataStore.shared.entryCount()
        XCTAssertEqual(count, 0)
    }

    /// Verifies removeAll on empty store doesn't throw.
    ///
    /// Expected: No error, count remains 0.
    func testRemoveAllOnEmptyStore() async {
        await MetadataStore.shared.removeAll()

        let count = await MetadataStore.shared.entryCount()
        XCTAssertEqual(count, 0)
    }

    // MARK: - Entry Count

    /// Verifies empty store has count of 0.
    ///
    /// Expected: entryCount returns 0.
    func testEntryCountEmpty() async {
        let count = await MetadataStore.shared.entryCount()
        XCTAssertEqual(count, 0)
    }

    /// Verifies count increments after storing.
    ///
    /// Expected: entryCount returns 1.
    func testEntryCountAfterStoring() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)

        let count = await MetadataStore.shared.entryCount()
        XCTAssertEqual(count, 1)
    }

    /// Verifies count reflects all stored entries.
    ///
    /// Each URL + thumb combination is a separate entry.
    ///
    /// Expected: entryCount returns 3.
    func testEntryCountWithMultipleEntries() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: true)
        await MetadataStore.shared.store(testMetadata, for: alternateURL, thumb: false)

        let count = await MetadataStore.shared.entryCount()
        XCTAssertEqual(count, 3)
    }

    /// Verifies count decrements after removal.
    ///
    /// Expected: entryCount returns 1 after removing one of two entries.
    func testEntryCountAfterRemoval() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)
        await MetadataStore.shared.store(testMetadata, for: alternateURL, thumb: false)
        await MetadataStore.shared.remove(for: testURL, thumb: false)

        let count = await MetadataStore.shared.entryCount()
        XCTAssertEqual(count, 1)
    }

    // MARK: - All Entries

    /// Verifies allEntries returns empty array for empty store.
    ///
    /// Expected: Empty array.
    func testAllEntriesEmpty() async {
        let entries = await MetadataStore.shared.allEntries()
        XCTAssertTrue(entries.isEmpty)
    }

    /// Verifies allEntries returns all stored entries.
    ///
    /// Expected: Array count matches stored entry count.
    func testAllEntriesReturnsStoredEntries() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)
        await MetadataStore.shared.store(testMetadata, for: alternateURL, thumb: false)

        let entries = await MetadataStore.shared.allEntries()

        XCTAssertEqual(entries.count, 2)
    }

    /// Verifies allEntries returns correct cache keys.
    ///
    /// Thumbnails have #thumb suffix in their key.
    ///
    /// Expected: Both keys are present in returned entries.
    func testAllEntriesContainsCorrectKeys() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: true)

        let entries = await MetadataStore.shared.allEntries()
        let keys = entries.map(\.key)

        XCTAssertTrue(keys.contains(testURL.absoluteString))
        XCTAssertTrue(keys.contains(testURL.absoluteString + "#thumb"))
    }

    /// Verifies allEntries returns correct metadata values.
    ///
    /// Expected: Metadata properties match stored values.
    func testAllEntriesContainsCorrectMetadata() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)

        let entries = await MetadataStore.shared.allEntries()

        XCTAssertEqual(entries.first?.metadata.etag, testMetadata.etag)
        XCTAssertEqual(entries.first?.metadata.lastModified, testMetadata.lastModified)
    }

    // MARK: - URL Edge Cases

    /// Verifies URLs with query parameters work correctly.
    ///
    /// Query parameters are part of the URL identity.
    ///
    /// Expected: Metadata is stored and retrieved successfully.
    func testURLWithQueryParameters() async {
        guard let urlWithQuery = URL(string: "https://example.com/image.jpg?size=large") else {
            XCTFail("Invalid URL")
            return
        }

        await MetadataStore.shared.store(testMetadata, for: urlWithQuery, thumb: false)
        let retrieved = await MetadataStore.shared.metadata(for: urlWithQuery, thumb: false)

        XCTAssertNotNil(retrieved)
    }

    /// Verifies URLs with special characters work correctly.
    ///
    /// URL-encoded characters like %20 should be handled properly.
    ///
    /// Expected: Metadata is stored and retrieved successfully.
    func testURLWithSpecialCharacters() async {
        guard let urlWithSpecial = URL(string: "https://example.com/image%20name.jpg") else {
            XCTFail("Invalid URL")
            return
        }

        await MetadataStore.shared.store(testMetadata, for: urlWithSpecial, thumb: false)
        let retrieved = await MetadataStore.shared.metadata(for: urlWithSpecial, thumb: false)

        XCTAssertNotNil(retrieved)
    }

    // MARK: - Persistence

    /// Verifies metadata persists across accesses.
    ///
    /// Since MetadataStore uses file storage, data should persist.
    ///
    /// Expected: Multiple retrievals return identical data.
    func testMetadataPersistsAcrossAccesses() async {
        await MetadataStore.shared.store(testMetadata, for: testURL, thumb: false)

        let retrieved1 = await MetadataStore.shared.metadata(for: testURL, thumb: false)
        let retrieved2 = await MetadataStore.shared.metadata(for: testURL, thumb: false)

        XCTAssertEqual(retrieved1?.etag, retrieved2?.etag)
    }

    // MARK: - Concurrency

    /// Verifies concurrent store operations complete successfully.
    ///
    /// Actor isolation should prevent race conditions.
    ///
    /// Expected: All 10 entries are stored.
    func testConcurrentStoreOperations() async {
        let urlsAndMetadata: [(URL, Metadata)] = (0 ..< 10).compactMap { index in
            guard let url = URL(string: "https://cdn.manasuite.com/card_sets/artwork/sld_\(index)_landscape.jpg") else {
                return nil
            }
            let metadata = Metadata(etag: "etag-\(index)", lastModified: nil)
            return (url, metadata)
        }

        await withTaskGroup(of: Void.self) { group in
            for (url, metadata) in urlsAndMetadata {
                group.addTask {
                    await MetadataStore.shared.store(metadata, for: url, thumb: false)
                }
            }
        }

        let count = await MetadataStore.shared.entryCount()
        XCTAssertEqual(count, 10)
    }

    /// Verifies concurrent read/write operations don't cause issues.
    ///
    /// Actor isolation should serialize access safely.
    ///
    /// Expected: Final retrieval returns valid metadata.
    func testConcurrentReadWriteOperations() async {
        let url = testURL
        let initialMetadata = testMetadata
        let newMetadataList = (0 ..< 5).map { _ in Metadata(etag: UUID().uuidString, lastModified: nil) }

        await MetadataStore.shared.store(initialMetadata, for: url, thumb: false)

        await withTaskGroup(of: Void.self) { group in
            for newMetadata in newMetadataList {
                group.addTask {
                    _ = await MetadataStore.shared.metadata(for: url, thumb: false)
                }
                group.addTask {
                    await MetadataStore.shared.store(newMetadata, for: url, thumb: false)
                }
            }
        }

        let retrieved = await MetadataStore.shared.metadata(for: url, thumb: false)
        XCTAssertNotNil(retrieved)
    }
}
