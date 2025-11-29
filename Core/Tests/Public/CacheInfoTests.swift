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

// MARK: - CacheInfoTests

/// Tests for CacheInfo which provides aggregated cache statistics.
///
/// CacheInfo contains:
/// - Disk usage and capacity (from URLCache)
/// - Memory usage and capacity (from URLCache memory layer)
/// - Cached entry count (from MetadataStore)
/// - Formatted display properties for UI
///
/// Retrieved via `CacheManager.shared.info`.
final class CacheInfoTests: XCTestCase {
    // MARK: - Initialization

    /// Verifies initialization with all parameters.
    ///
    /// Expected: All properties are correctly stored.
    func testInitWithAllParameters() {
        let info = CacheInfo(
            diskUsedBytes: 1000,
            diskCapacityBytes: 10000,
            memoryUsedBytes: 500,
            memoryCapacityBytes: 5000,
            cachedEntryCount: 10
        )

        XCTAssertEqual(info.diskUsedBytes, 1000)
        XCTAssertEqual(info.diskCapacityBytes, 10000)
        XCTAssertEqual(info.memoryUsedBytes, 500)
        XCTAssertEqual(info.memoryCapacityBytes, 5000)
        XCTAssertEqual(info.cachedEntryCount, 10)
    }

    /// Verifies initialization with zero values.
    ///
    /// Empty cache should have all zeros.
    ///
    /// Expected: All values are 0.
    func testInitWithZeroValues() {
        let info = CacheInfo(
            diskUsedBytes: 0,
            diskCapacityBytes: 0,
            memoryUsedBytes: 0,
            memoryCapacityBytes: 0,
            cachedEntryCount: 0
        )

        XCTAssertEqual(info.diskUsedBytes, 0)
        XCTAssertEqual(info.cachedEntryCount, 0)
    }

    /// Verifies initialization with large values.
    ///
    /// Cache can hold gigabytes of data.
    ///
    /// Expected: Large values are correctly stored.
    func testInitWithLargeValues() {
        let tenGigabytes: Int64 = 10 * 1024 * 1024 * 1024
        let info = CacheInfo(
            diskUsedBytes: tenGigabytes,
            diskCapacityBytes: tenGigabytes * 10,
            memoryUsedBytes: 1024 * 1024 * 1024,
            memoryCapacityBytes: 2 * 1024 * 1024 * 1024,
            cachedEntryCount: 10000
        )

        XCTAssertEqual(info.diskUsedBytes, tenGigabytes)
        XCTAssertEqual(info.cachedEntryCount, 10000)
    }

    // MARK: - Protocol Conformance

    /// Verifies CacheInfo conforms to Sendable.
    ///
    /// Required for Swift 6 concurrency safety.
    ///
    /// Expected: Can be assigned to Sendable type.
    func testConformsToSendableProtocol() {
        let info: Sendable = CacheInfo(
            diskUsedBytes: 0,
            diskCapacityBytes: 0,
            memoryUsedBytes: 0,
            memoryCapacityBytes: 0,
            cachedEntryCount: 0
        )
        XCTAssertNotNil(info)
    }

    // MARK: - Formatted Properties - Disk

    /// Verifies small disk sizes format correctly.
    ///
    /// Uses ByteCountFormatter for human-readable output.
    ///
    /// Expected: Non-empty formatted string.
    func testDiskUsedFormattedBytes() {
        let info = CacheInfo(
            diskUsedBytes: 500,
            diskCapacityBytes: 1000,
            memoryUsedBytes: 0,
            memoryCapacityBytes: 0,
            cachedEntryCount: 0
        )

        XCTAssertFalse(info.diskUsedFormatted.isEmpty)
    }

    /// Verifies kilobyte-range disk sizes format correctly.
    ///
    /// Expected: Contains "KB" or "kB".
    func testDiskUsedFormattedKilobytes() {
        let info = CacheInfo(
            diskUsedBytes: 1024,
            diskCapacityBytes: 10240,
            memoryUsedBytes: 0,
            memoryCapacityBytes: 0,
            cachedEntryCount: 0
        )

        XCTAssertTrue(info.diskUsedFormatted.contains("KB") || info.diskUsedFormatted.contains("kB"))
    }

    /// Verifies megabyte-range disk sizes format correctly.
    ///
    /// Expected: Contains "MB".
    func testDiskUsedFormattedMegabytes() {
        let info = CacheInfo(
            diskUsedBytes: 1_500_000,
            diskCapacityBytes: 10_000_000,
            memoryUsedBytes: 0,
            memoryCapacityBytes: 0,
            cachedEntryCount: 0
        )

        XCTAssertTrue(info.diskUsedFormatted.contains("MB"))
    }

    /// Verifies disk capacity formats correctly.
    ///
    /// Expected: Contains "MB".
    func testDiskCapacityFormattedMegabytes() {
        let fiveHundredMB: Int64 = 500 * 1024 * 1024
        let info = CacheInfo(
            diskUsedBytes: 0,
            diskCapacityBytes: fiveHundredMB,
            memoryUsedBytes: 0,
            memoryCapacityBytes: 0,
            cachedEntryCount: 0
        )

        XCTAssertTrue(info.diskCapacityFormatted.contains("MB"))
    }

    // MARK: - Formatted Properties - Memory

    /// Verifies small memory sizes format correctly.
    ///
    /// Expected: Non-empty formatted string.
    func testMemoryUsedFormattedBytes() {
        let info = CacheInfo(
            diskUsedBytes: 0,
            diskCapacityBytes: 0,
            memoryUsedBytes: 500,
            memoryCapacityBytes: 1000,
            cachedEntryCount: 0
        )

        XCTAssertFalse(info.memoryUsedFormatted.isEmpty)
    }

    /// Verifies memory capacity formats correctly.
    ///
    /// Expected: Contains "MB".
    func testMemoryCapacityFormattedMegabytes() {
        let oneHundredMB: Int64 = 100 * 1024 * 1024
        let info = CacheInfo(
            diskUsedBytes: 0,
            diskCapacityBytes: 0,
            memoryUsedBytes: 0,
            memoryCapacityBytes: oneHundredMB,
            cachedEntryCount: 0
        )

        XCTAssertTrue(info.memoryCapacityFormatted.contains("MB"))
    }

    // MARK: - Summary

    /// Verifies summary contains disk information.
    ///
    /// Expected: Contains "Disk:".
    func testSummaryContainsDiskInfo() {
        let info = CacheInfo(
            diskUsedBytes: 1_000_000,
            diskCapacityBytes: 10_000_000,
            memoryUsedBytes: 500_000,
            memoryCapacityBytes: 5_000_000,
            cachedEntryCount: 50
        )

        XCTAssertTrue(info.summary.contains("Disk:"))
    }

    /// Verifies summary contains memory information.
    ///
    /// Expected: Contains "Memory:".
    func testSummaryContainsMemoryInfo() {
        let info = CacheInfo(
            diskUsedBytes: 1_000_000,
            diskCapacityBytes: 10_000_000,
            memoryUsedBytes: 500_000,
            memoryCapacityBytes: 5_000_000,
            cachedEntryCount: 50
        )

        XCTAssertTrue(info.summary.contains("Memory:"))
    }

    /// Verifies summary contains entry count.
    ///
    /// Expected: Contains "Entries:" and the count value.
    func testSummaryContainsEntryCount() {
        let info = CacheInfo(
            diskUsedBytes: 1_000_000,
            diskCapacityBytes: 10_000_000,
            memoryUsedBytes: 500_000,
            memoryCapacityBytes: 5_000_000,
            cachedEntryCount: 127
        )

        XCTAssertTrue(info.summary.contains("Entries:"))
        XCTAssertTrue(info.summary.contains("127"))
    }

    /// Verifies summary format includes separators.
    ///
    /// Format: "Disk: X / Y, Memory: Z, Entries: N"
    ///
    /// Expected: Contains "/" and ",".
    func testSummaryFormat() {
        let info = CacheInfo(
            diskUsedBytes: 0,
            diskCapacityBytes: 0,
            memoryUsedBytes: 0,
            memoryCapacityBytes: 0,
            cachedEntryCount: 0
        )

        XCTAssertTrue(info.summary.contains("/"))
        XCTAssertTrue(info.summary.contains(","))
    }

    // MARK: - Edge Cases

    /// Verifies zero entry count is displayed.
    ///
    /// Expected: cachedEntryCount is 0, summary contains "0".
    func testZeroEntryCount() {
        let info = CacheInfo(
            diskUsedBytes: 1000,
            diskCapacityBytes: 10000,
            memoryUsedBytes: 500,
            memoryCapacityBytes: 5000,
            cachedEntryCount: 0
        )

        XCTAssertEqual(info.cachedEntryCount, 0)
        XCTAssertTrue(info.summary.contains("0"))
    }

    /// Verifies all zero values still produce valid formatted strings.
    ///
    /// Expected: All formatted properties are non-empty.
    func testAllZeroFormatted() {
        let info = CacheInfo(
            diskUsedBytes: 0,
            diskCapacityBytes: 0,
            memoryUsedBytes: 0,
            memoryCapacityBytes: 0,
            cachedEntryCount: 0
        )

        XCTAssertFalse(info.diskUsedFormatted.isEmpty)
        XCTAssertFalse(info.diskCapacityFormatted.isEmpty)
        XCTAssertFalse(info.memoryUsedFormatted.isEmpty)
        XCTAssertFalse(info.memoryCapacityFormatted.isEmpty)
        XCTAssertFalse(info.summary.isEmpty)
    }
}
