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

// MARK: - DiskCacheTests

/// Tests for the DiskCache actor which provides persistent storage for downloaded images.
///
/// DiskCache is responsible for:
/// - Storing image data on disk using URLCache
/// - Filtering out error responses (404, 500, etc.) before caching
/// - Validating cached responses before returning data
/// - Thread-safe operations via actor isolation
final class DiskCacheTests: XCTestCase {
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

    private var testImageData: Data {
        createMinimalJPEGData()
    }

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        await DiskCache.shared.removeAll()
    }

    override func tearDown() async throws {
        await DiskCache.shared.removeAll()
        try await super.tearDown()
    }

    // MARK: - Shared Instance

    /// Verifies the singleton pattern is implemented correctly.
    ///
    /// Expected: DiskCache.shared returns a non-nil instance.
    func testSharedInstanceExists() async {
        let cache = DiskCache.shared
        XCTAssertNotNil(cache)
    }

    // MARK: - Store and Retrieve

    /// Verifies basic store and retrieve functionality.
    ///
    /// Stores image data with a successful HTTP response and verifies
    /// the same data can be retrieved using the same URL.
    ///
    /// Expected: Retrieved data equals the originally stored data.
    func testStoreAndRetrieveData() async {
        let data = testImageData
        let response = createSuccessResponse(for: testURL)

        await DiskCache.shared.store(data: data, response: response, for: testURL)
        let retrieved = await DiskCache.shared.cachedData(for: testURL)

        XCTAssertNotNil(retrieved)
        XCTAssertEqual(retrieved, data)
    }

    /// Verifies retrieval returns nil for URLs not in cache.
    ///
    /// Expected: Returns nil when no data has been stored for the URL.
    func testRetrieveNonExistentData() async {
        let retrieved = await DiskCache.shared.cachedData(for: testURL)

        XCTAssertNil(retrieved)
    }

    // MARK: - HTTP Status Code Filtering

    /// Verifies 404 Not Found responses are not cached.
    ///
    /// This prevents caching HTML error pages which would cause
    /// CGImageSource decoding failures when treated as image data.
    ///
    /// Expected: Data is not stored and retrieval returns nil.
    func testStoreRejectsErrorResponse404() async {
        let data = testImageData
        let response = createErrorResponse(for: testURL, statusCode: 404)

        await DiskCache.shared.store(data: data, response: response, for: testURL)
        let retrieved = await DiskCache.shared.cachedData(for: testURL)

        XCTAssertNil(retrieved)
    }

    /// Verifies 500 Internal Server Error responses are not cached.
    ///
    /// Server errors should trigger retry logic, not be cached as valid data.
    ///
    /// Expected: Data is not stored and retrieval returns nil.
    func testStoreRejectsErrorResponse500() async {
        let data = testImageData
        let response = createErrorResponse(for: testURL, statusCode: 500)

        await DiskCache.shared.store(data: data, response: response, for: testURL)
        let retrieved = await DiskCache.shared.cachedData(for: testURL)

        XCTAssertNil(retrieved)
    }

    /// Verifies 403 Forbidden responses are not cached.
    ///
    /// Access denied responses may be temporary and should not
    /// permanently prevent image loading.
    ///
    /// Expected: Data is not stored and retrieval returns nil.
    func testStoreRejectsErrorResponse403() async {
        let data = testImageData
        let response = createErrorResponse(for: testURL, statusCode: 403)

        await DiskCache.shared.store(data: data, response: response, for: testURL)
        let retrieved = await DiskCache.shared.cachedData(for: testURL)

        XCTAssertNil(retrieved)
    }

    /// Verifies 200 OK responses are cached successfully.
    ///
    /// Standard successful response should always be cached.
    ///
    /// Expected: Data is stored and can be retrieved.
    func testStoreAccepts200Response() async {
        let data = testImageData
        let response = createSuccessResponse(for: testURL, statusCode: 200)

        await DiskCache.shared.store(data: data, response: response, for: testURL)
        let retrieved = await DiskCache.shared.cachedData(for: testURL)

        XCTAssertNotNil(retrieved)
    }

    /// Verifies 201 Created responses are cached successfully.
    ///
    /// Some APIs return 201 for successful resource creation/retrieval.
    ///
    /// Expected: Data is stored and can be retrieved.
    func testStoreAccepts201Response() async {
        let data = testImageData
        let response = createSuccessResponse(for: testURL, statusCode: 201)

        await DiskCache.shared.store(data: data, response: response, for: testURL)
        let retrieved = await DiskCache.shared.cachedData(for: testURL)

        XCTAssertNotNil(retrieved)
    }

    /// Verifies 204 No Content responses are cached successfully.
    ///
    /// Edge case: 204 is a 2xx status and should be accepted,
    /// though unlikely for image responses.
    ///
    /// Expected: Data is stored and can be retrieved.
    func testStoreAccepts204Response() async {
        let data = testImageData
        let response = createSuccessResponse(for: testURL, statusCode: 204)

        await DiskCache.shared.store(data: data, response: response, for: testURL)
        let retrieved = await DiskCache.shared.cachedData(for: testURL)

        XCTAssertNotNil(retrieved)
    }

    // MARK: - Remove

    /// Verifies single entry removal works correctly.
    ///
    /// After storing data, removing it should make it unavailable.
    ///
    /// Expected: Retrieval returns nil after removal.
    func testRemoveData() async {
        let data = testImageData
        let response = createSuccessResponse(for: testURL)

        await DiskCache.shared.store(data: data, response: response, for: testURL)
        await DiskCache.shared.remove(for: testURL)

        let retrieved = await DiskCache.shared.cachedData(for: testURL)

        XCTAssertNil(retrieved)
    }

    /// Verifies removing non-existent data doesn't cause errors.
    ///
    /// Defensive behavior: removing a URL that was never cached
    /// should be a no-op, not throw an error.
    ///
    /// Expected: No crash or error occurs.
    func testRemoveNonExistentDataDoesNotThrow() async {
        await DiskCache.shared.remove(for: testURL)
    }

    // MARK: - Remove All

    /// Verifies complete cache clearing removes all entries.
    ///
    /// Stores multiple entries, clears the cache, and verifies
    /// all entries are removed.
    ///
    /// Expected: All previously stored data returns nil after removeAll.
    func testRemoveAll() async {
        let data = testImageData
        let response1 = createSuccessResponse(for: testURL)
        let response2 = createSuccessResponse(for: alternateURL)

        await DiskCache.shared.store(data: data, response: response1, for: testURL)
        await DiskCache.shared.store(data: data, response: response2, for: alternateURL)

        await DiskCache.shared.removeAll()

        let retrieved1 = await DiskCache.shared.cachedData(for: testURL)
        let retrieved2 = await DiskCache.shared.cachedData(for: alternateURL)

        XCTAssertNil(retrieved1)
        XCTAssertNil(retrieved2)
    }

    /// Verifies removeAll on empty cache doesn't cause errors.
    ///
    /// Expected: No crash or error occurs.
    func testRemoveAllOnEmptyCache() async {
        await DiskCache.shared.removeAll()
    }

    // MARK: - Cache Info

    /// Verifies disk capacity is configured with a positive value.
    ///
    /// URLCache requires a configured disk capacity for persistent storage.
    ///
    /// Expected: Disk capacity is greater than 0.
    func testDiskCapacityIsPositive() async {
        let capacity = await DiskCache.shared.diskCapacity

        XCTAssertGreaterThan(capacity, 0)
    }

    /// Verifies memory capacity is configured with a positive value.
    ///
    /// URLCache's memory cache provides fast access to recently used responses.
    ///
    /// Expected: Memory capacity is greater than 0.
    func testMemoryCapacityIsPositive() async {
        let capacity = await DiskCache.shared.memoryCapacity

        XCTAssertGreaterThan(capacity, 0)
    }

    /// Verifies disk usage reporting returns non-negative values.
    ///
    /// Usage should be 0 or positive, never negative.
    ///
    /// Expected: Current disk usage is >= 0.
    func testCurrentDiskUsageIsNonNegative() async {
        let usage = await DiskCache.shared.currentDiskUsage

        XCTAssertGreaterThanOrEqual(usage, 0)
    }

    /// Verifies memory usage reporting returns non-negative values.
    ///
    /// Expected: Current memory usage is >= 0.
    func testCurrentMemoryUsageIsNonNegative() async {
        let usage = await DiskCache.shared.currentMemoryUsage

        XCTAssertGreaterThanOrEqual(usage, 0)
    }

    // MARK: - URL Edge Cases

    /// Verifies URLs with query parameters are handled correctly.
    ///
    /// Query parameters are part of the URL identity and should
    /// differentiate cache entries (e.g., ?size=large vs ?size=small).
    ///
    /// Expected: Data is stored and retrieved correctly with query parameters.
    func testURLWithQueryParameters() async {
        guard let urlWithQuery = URL(string: "https://example.com/image.jpg?size=large") else {
            XCTFail("Invalid URL")
            return
        }
        let data = testImageData
        let response = createSuccessResponse(for: urlWithQuery)

        await DiskCache.shared.store(data: data, response: response, for: urlWithQuery)
        let retrieved = await DiskCache.shared.cachedData(for: urlWithQuery)

        XCTAssertNotNil(retrieved)
    }

    /// Verifies URLs with percent-encoded special characters work correctly.
    ///
    /// File names with spaces or special characters are common and must
    /// be handled properly (%20 = space).
    ///
    /// Expected: Data is stored and retrieved correctly with encoded characters.
    func testURLWithSpecialCharacters() async {
        guard let urlWithSpecial = URL(string: "https://example.com/image%20name.jpg") else {
            XCTFail("Invalid URL")
            return
        }
        let data = testImageData
        let response = createSuccessResponse(for: urlWithSpecial)

        await DiskCache.shared.store(data: data, response: response, for: urlWithSpecial)
        let retrieved = await DiskCache.shared.cachedData(for: urlWithSpecial)

        XCTAssertNotNil(retrieved)
    }

    // MARK: - Concurrency

    /// Verifies thread safety with concurrent store operations.
    ///
    /// Multiple tasks storing different URLs simultaneously must not
    /// cause data races or crashes. Actor isolation should handle this.
    ///
    /// Expected: All concurrent stores complete without error and data is retrievable.
    func testConcurrentStoreOperations() async {
        let testData: [(URL, Data, HTTPURLResponse)] = (0 ..< 10).compactMap { index in
            guard let url = URL(string: "https://cdn.manasuite.com/card_sets/artwork/sld_\(index)_landscape.jpg") else {
                return nil
            }
            let data = createMinimalJPEGData()
            let response = createSuccessResponse(for: url)
            return (url, data, response)
        }

        await withTaskGroup(of: Void.self) { group in
            for (url, data, response) in testData {
                group.addTask {
                    await DiskCache.shared.store(data: data, response: response, for: url)
                }
            }
        }

        guard let firstURL = testData.first?.0 else {
            XCTFail("Invalid URL")
            return
        }

        let retrieved = await DiskCache.shared.cachedData(for: firstURL)
        XCTAssertNotNil(retrieved)
    }

    /// Verifies thread safety with concurrent read and write operations.
    ///
    /// Real-world usage involves simultaneous reads and writes.
    /// The actor must serialize access correctly without deadlocks.
    ///
    /// Expected: All operations complete without error and final state is consistent.
    func testConcurrentReadWriteOperations() async {
        let url = testURL
        let data = testImageData
        let response = createSuccessResponse(for: url)

        let newDataList: [(Data, HTTPURLResponse)] = (0 ..< 5).map { _ in
            let newData = createMinimalJPEGData()
            let newResponse = createSuccessResponse(for: url)
            return (newData, newResponse)
        }

        await DiskCache.shared.store(data: data, response: response, for: url)

        await withTaskGroup(of: Void.self) { group in
            for (newData, newResponse) in newDataList {
                group.addTask {
                    _ = await DiskCache.shared.cachedData(for: url)
                }
                group.addTask {
                    await DiskCache.shared.store(data: newData, response: newResponse, for: url)
                }
            }
        }

        let retrieved = await DiskCache.shared.cachedData(for: url)
        XCTAssertNotNil(retrieved)
    }

    // MARK: - Helper Methods

    private func createSuccessResponse(for url: URL, statusCode: Int = 200) -> HTTPURLResponse {
        guard let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "image/jpeg"]
        ) else {
            preconditionFailure("Failed to create HTTPURLResponse")
        }
        return response
    }

    private func createErrorResponse(for url: URL, statusCode: Int) -> HTTPURLResponse {
        guard let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: ["Content-Type": "text/html"]
        ) else {
            preconditionFailure("Failed to create HTTPURLResponse")
        }
        return response
    }

    private func createMinimalJPEGData() -> Data {
        // Minimal valid JPEG header bytes
        Data([
            0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0x4A, 0x46,
            0x49, 0x46, 0x00, 0x01, 0x01, 0x00, 0x00, 0x01,
            0x00, 0x01, 0x00, 0x00, 0xFF, 0xD9
        ])
    }
}
