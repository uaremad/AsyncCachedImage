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

// MARK: - MetadataEntryTests

/// Tests for the MetadataEntry struct which represents a single cache entry.
///
/// MetadataEntry combines:
/// - URL identification (id, url, isThumb)
/// - Cache metadata (etag, lastModified, cachedAt)
/// - Storage info (diskSizeBytes)
/// - Computed display properties (fileName, diskSizeFormatted)
///
/// Used by CacheManager.getAllEntries() for cache browser UIs.
final class MetadataEntryTests: XCTestCase {
    // MARK: - Test Data

    private var testURL: URL {
        guard let url = URL(string: "https://cdn.manasuite.com/card_sets/artwork/sld_300_landscape.jpg") else {
            preconditionFailure("Invalid test URL")
        }
        return url
    }

    private var testMetadata: Metadata {
        Metadata(etag: "abc123", lastModified: "Mon, 01 Jan 2025 00:00:00 GMT")
    }

    // MARK: - Initialization

    /// Verifies initialization with all parameters.
    ///
    /// Expected: All properties are correctly stored.
    func testInitWithAllParameters() {
        let entry = MetadataEntry(
            id: "test-id",
            url: testURL,
            isThumb: false,
            metadata: testMetadata,
            diskSizeBytes: 1024
        )

        XCTAssertEqual(entry.id, "test-id")
        XCTAssertEqual(entry.url, testURL)
        XCTAssertFalse(entry.isThumb)
        XCTAssertNotNil(entry.metadata)
        XCTAssertEqual(entry.diskSizeBytes, 1024)
    }

    /// Verifies initialization with thumbnail variant flag.
    ///
    /// Thumbnails use #thumb suffix in their ID to differentiate
    /// from full-size entries for the same URL.
    ///
    /// Expected: isThumb is true.
    func testInitWithThumbnailVariant() {
        let entry = MetadataEntry(
            id: "test-id#thumb",
            url: testURL,
            isThumb: true,
            metadata: testMetadata,
            diskSizeBytes: 512
        )

        XCTAssertTrue(entry.isThumb)
    }

    /// Verifies initialization with nil metadata.
    ///
    /// Metadata may be nil if it couldn't be loaded from disk.
    ///
    /// Expected: metadata property is nil.
    func testInitWithNilMetadata() {
        let entry = MetadataEntry(
            id: "test-id",
            url: testURL,
            isThumb: false,
            metadata: nil,
            diskSizeBytes: 1024
        )

        XCTAssertNil(entry.metadata)
    }

    /// Verifies initialization with zero disk size.
    ///
    /// Zero size may occur for entries where data couldn't be measured.
    ///
    /// Expected: diskSizeBytes is 0.
    func testInitWithZeroDiskSize() {
        let entry = MetadataEntry(
            id: "test-id",
            url: testURL,
            isThumb: false,
            metadata: testMetadata,
            diskSizeBytes: 0
        )

        XCTAssertEqual(entry.diskSizeBytes, 0)
    }

    // MARK: - Protocol Conformance

    /// Verifies MetadataEntry conforms to Identifiable protocol.
    ///
    /// Identifiable conformance enables use in SwiftUI ForEach.
    ///
    /// Expected: id property returns the initialized value.
    func testConformsToIdentifiableProtocol() {
        let entry = MetadataEntry(
            id: "unique-id",
            url: testURL,
            isThumb: false,
            metadata: nil,
            diskSizeBytes: 0
        )

        XCTAssertEqual(entry.id, "unique-id")
    }

    /// Verifies MetadataEntry conforms to Sendable protocol.
    ///
    /// Sendable conformance is required for Swift 6 concurrency safety.
    ///
    /// Expected: Can be assigned to Sendable type.
    func testConformsToSendableProtocol() {
        let entry: Sendable = MetadataEntry(
            id: "test-id",
            url: testURL,
            isThumb: false,
            metadata: nil,
            diskSizeBytes: 0
        )
        XCTAssertNotNil(entry)
    }

    // MARK: - Computed Properties - diskSizeFormatted

    /// Verifies small sizes display as bytes.
    ///
    /// Uses ByteCountFormatter for human-readable formatting.
    ///
    /// Expected: Contains "bytes" or "B".
    func testDiskSizeFormattedBytes() {
        let entry = MetadataEntry(
            id: "test",
            url: testURL,
            isThumb: false,
            metadata: nil,
            diskSizeBytes: 500
        )

        XCTAssertTrue(entry.diskSizeFormatted.contains("bytes") || entry.diskSizeFormatted.contains("B"))
    }

    /// Verifies kilobyte-range sizes format correctly.
    ///
    /// Expected: Contains "KB" or "kB".
    func testDiskSizeFormattedKilobytes() {
        let entry = MetadataEntry(
            id: "test",
            url: testURL,
            isThumb: false,
            metadata: nil,
            diskSizeBytes: 1024
        )

        XCTAssertTrue(entry.diskSizeFormatted.contains("KB") || entry.diskSizeFormatted.contains("kB"))
    }

    /// Verifies megabyte-range sizes format correctly.
    ///
    /// Expected: Contains "MB".
    func testDiskSizeFormattedMegabytes() {
        let entry = MetadataEntry(
            id: "test",
            url: testURL,
            isThumb: false,
            metadata: nil,
            diskSizeBytes: 1_500_000
        )

        XCTAssertTrue(entry.diskSizeFormatted.contains("MB"))
    }

    /// Verifies zero size produces non-empty string.
    ///
    /// Expected: Returns a valid formatted string (e.g., "Zero KB").
    func testDiskSizeFormattedZero() {
        let entry = MetadataEntry(
            id: "test",
            url: testURL,
            isThumb: false,
            metadata: nil,
            diskSizeBytes: 0
        )

        XCTAssertFalse(entry.diskSizeFormatted.isEmpty)
    }

    // MARK: - Computed Properties - fileName

    /// Verifies fileName extracts the last path component.
    ///
    /// Expected: Returns "sld_300_landscape.jpg".
    func testFileNameFromURL() {
        let entry = MetadataEntry(
            id: "test",
            url: testURL,
            isThumb: false,
            metadata: nil,
            diskSizeBytes: 0
        )

        XCTAssertEqual(entry.fileName, "sld_300_landscape.jpg")
    }

    /// Verifies fileName works with different file extensions.
    ///
    /// Expected: Returns "photo.png".
    func testFileNameWithDifferentExtension() {
        guard let pngURL = URL(string: "https://example.com/images/photo.png") else {
            XCTFail("Invalid URL")
            return
        }

        let entry = MetadataEntry(
            id: "test",
            url: pngURL,
            isThumb: false,
            metadata: nil,
            diskSizeBytes: 0
        )

        XCTAssertEqual(entry.fileName, "photo.png")
    }

    /// Verifies fileName works with deeply nested paths.
    ///
    /// Only the last path component should be returned.
    ///
    /// Expected: Returns "image.webp".
    func testFileNameWithComplexPath() {
        guard let complexURL = URL(string: "https://example.com/a/b/c/d/image.webp") else {
            XCTFail("Invalid URL")
            return
        }

        let entry = MetadataEntry(
            id: "test",
            url: complexURL,
            isThumb: false,
            metadata: nil,
            diskSizeBytes: 0
        )

        XCTAssertEqual(entry.fileName, "image.webp")
    }

    /// Verifies fileName excludes query parameters.
    ///
    /// Query parameters are not part of the file name.
    ///
    /// Expected: Returns "image.jpg" without query string.
    func testFileNameWithQueryParameters() {
        guard let urlWithQuery = URL(string: "https://example.com/image.jpg?size=large&format=webp") else {
            XCTFail("Invalid URL")
            return
        }

        let entry = MetadataEntry(
            id: "test",
            url: urlWithQuery,
            isThumb: false,
            metadata: nil,
            diskSizeBytes: 0
        )

        XCTAssertEqual(entry.fileName, "image.jpg")
    }

    // MARK: - Large Values

    /// Verifies large disk sizes format as gigabytes.
    ///
    /// Expected: diskSizeBytes is preserved, formatted contains "GB".
    func testLargeDiskSize() {
        let tenGigabytes: Int64 = 10 * 1024 * 1024 * 1024
        let entry = MetadataEntry(
            id: "test",
            url: testURL,
            isThumb: false,
            metadata: nil,
            diskSizeBytes: tenGigabytes
        )

        XCTAssertEqual(entry.diskSizeBytes, tenGigabytes)
        XCTAssertTrue(entry.diskSizeFormatted.contains("GB"))
    }
}
