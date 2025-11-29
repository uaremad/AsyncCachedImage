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

// MARK: - MetadataTests

/// Tests for the Metadata struct which stores HTTP cache headers.
///
/// Metadata contains:
/// - `etag`: Server-provided resource version identifier
/// - `lastModified`: Server-provided modification timestamp
/// - `cachedAt`: Local timestamp when content was cached
///
/// This data is used for HTTP conditional requests to revalidate cached content.
final class MetadataTests: XCTestCase {
    // MARK: - Initialization

    /// Verifies initialization with all parameters set.
    ///
    /// Expected: All properties are correctly stored.
    func testInitWithAllParameters() {
        let date = Date()
        let metadata = Metadata(etag: "abc123", lastModified: "Mon, 01 Jan 2025 00:00:00 GMT", cachedAt: date)

        XCTAssertEqual(metadata.etag, "abc123")
        XCTAssertEqual(metadata.lastModified, "Mon, 01 Jan 2025 00:00:00 GMT")
        XCTAssertEqual(metadata.cachedAt, date)
    }

    /// Verifies initialization with nil etag.
    ///
    /// Some servers don't provide ETags, only Last-Modified.
    ///
    /// Expected: etag is nil, lastModified is preserved.
    func testInitWithNilEtag() {
        let metadata = Metadata(etag: nil, lastModified: "Mon, 01 Jan 2025 00:00:00 GMT")

        XCTAssertNil(metadata.etag)
        XCTAssertEqual(metadata.lastModified, "Mon, 01 Jan 2025 00:00:00 GMT")
    }

    /// Verifies initialization with nil lastModified.
    ///
    /// Some servers don't provide Last-Modified, only ETags.
    ///
    /// Expected: lastModified is nil, etag is preserved.
    func testInitWithNilLastModified() {
        let metadata = Metadata(etag: "abc123", lastModified: nil)

        XCTAssertEqual(metadata.etag, "abc123")
        XCTAssertNil(metadata.lastModified)
    }

    /// Verifies initialization with both header values nil.
    ///
    /// Servers that don't support caching headers may return neither.
    /// The cachedAt timestamp is still useful for time-based expiration.
    ///
    /// Expected: Both optional values are nil.
    func testInitWithBothNil() {
        let metadata = Metadata(etag: nil, lastModified: nil)

        XCTAssertNil(metadata.etag)
        XCTAssertNil(metadata.lastModified)
    }

    /// Verifies cachedAt defaults to current date when not specified.
    ///
    /// This is the common case when creating metadata from a fresh download.
    ///
    /// Expected: cachedAt is approximately the current time.
    func testInitWithDefaultCachedAt() {
        let beforeInit = Date()
        let metadata = Metadata(etag: "abc123", lastModified: nil)
        let afterInit = Date()

        XCTAssertGreaterThanOrEqual(metadata.cachedAt, beforeInit)
        XCTAssertLessThanOrEqual(metadata.cachedAt, afterInit)
    }

    // MARK: - Protocol Conformance

    /// Verifies Metadata conforms to Sendable protocol.
    ///
    /// Sendable conformance is required for Swift 6 concurrency safety.
    ///
    /// Expected: Can be assigned to Sendable type.
    func testConformsToSendableProtocol() {
        let metadata: Sendable = Metadata(etag: "test", lastModified: nil)
        XCTAssertNotNil(metadata)
    }

    /// Verifies Metadata conforms to Codable protocol.
    ///
    /// Codable conformance enables JSON persistence in MetadataStore.
    ///
    /// Expected: Can be assigned to Codable type.
    func testConformsToCodableProtocol() {
        let metadata: Codable = Metadata(etag: "test", lastModified: nil)
        XCTAssertNotNil(metadata)
    }

    // MARK: - Codable Encoding

    /// Verifies Metadata can be encoded to JSON.
    ///
    /// This is essential for MetadataStore file persistence.
    ///
    /// Expected: Encoding produces non-empty data.
    func testEncodeToJSON() throws {
        let date = Date(timeIntervalSince1970: 1_704_067_200)
        let metadata = Metadata(etag: "abc123", lastModified: "Mon, 01 Jan 2024 00:00:00 GMT", cachedAt: date)

        let encoder = JSONEncoder()
        let data = try encoder.encode(metadata)

        XCTAssertFalse(data.isEmpty)
    }

    /// Verifies Metadata survives encode/decode round-trip.
    ///
    /// All properties must be preserved through JSON serialization.
    ///
    /// Expected: Decoded values match original values.
    func testDecodeFromJSON() throws {
        let date = Date(timeIntervalSince1970: 1_704_067_200)
        let original = Metadata(etag: "abc123", lastModified: "Mon, 01 Jan 2024 00:00:00 GMT", cachedAt: date)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Metadata.self, from: data)

        XCTAssertEqual(decoded.etag, original.etag)
        XCTAssertEqual(decoded.lastModified, original.lastModified)
        XCTAssertEqual(decoded.cachedAt.timeIntervalSince1970, original.cachedAt.timeIntervalSince1970, accuracy: 0.001)
    }

    /// Verifies nil values survive encode/decode round-trip.
    ///
    /// JSON null handling must work correctly for optional fields.
    ///
    /// Expected: Decoded nil values remain nil.
    func testDecodeWithNilValues() throws {
        let original = Metadata(etag: nil, lastModified: nil)

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(Metadata.self, from: data)

        XCTAssertNil(decoded.etag)
        XCTAssertNil(decoded.lastModified)
    }

    // MARK: - ETag Formats

    /// Verifies weak ETag format is preserved.
    ///
    /// Weak ETags (prefixed with W/) indicate semantic equivalence
    /// rather than byte-for-byte identity.
    ///
    /// Expected: W/ prefix is preserved.
    func testEtagWithWeakPrefix() {
        let metadata = Metadata(etag: "W/\"abc123\"", lastModified: nil)
        XCTAssertEqual(metadata.etag, "W/\"abc123\"")
    }

    /// Verifies strong ETag format is preserved.
    ///
    /// Strong ETags (quoted without W/ prefix) indicate
    /// byte-for-byte identical content.
    ///
    /// Expected: Quoted format is preserved.
    func testEtagWithStrongFormat() {
        let metadata = Metadata(etag: "\"abc123\"", lastModified: nil)
        XCTAssertEqual(metadata.etag, "\"abc123\"")
    }

    /// Verifies long ETag hashes are preserved.
    ///
    /// Some servers use SHA-256 or similar for ETags.
    ///
    /// Expected: Full 64-character hash is preserved.
    func testEtagWithLongHash() {
        let longHash = String(repeating: "a", count: 64)
        let metadata = Metadata(etag: longHash, lastModified: nil)
        XCTAssertEqual(metadata.etag, longHash)
    }

    // MARK: - Last-Modified Formats

    /// Verifies RFC 1123 date format is preserved.
    ///
    /// This is the standard HTTP date format specified in RFC 7231.
    ///
    /// Expected: Full date string is preserved.
    func testLastModifiedWithRFC1123Format() {
        let lastModified = "Sun, 06 Nov 1994 08:49:37 GMT"
        let metadata = Metadata(etag: nil, lastModified: lastModified)
        XCTAssertEqual(metadata.lastModified, lastModified)
    }

    /// Verifies timezone variations are preserved.
    ///
    /// While GMT is standard, some servers use UTC or other zones.
    ///
    /// Expected: Full date string including timezone is preserved.
    func testLastModifiedWithDifferentTimezones() {
        let lastModified = "Mon, 01 Jan 2025 12:00:00 UTC"
        let metadata = Metadata(etag: nil, lastModified: lastModified)
        XCTAssertEqual(metadata.lastModified, lastModified)
    }

    // MARK: - Edge Cases

    /// Verifies empty string ETag is preserved.
    ///
    /// While unusual, empty string is technically valid.
    ///
    /// Expected: Empty string is preserved, not converted to nil.
    func testEmptyEtag() {
        let metadata = Metadata(etag: "", lastModified: nil)
        XCTAssertEqual(metadata.etag, "")
    }

    /// Verifies empty string lastModified is preserved.
    ///
    /// While unusual, empty string is technically valid.
    ///
    /// Expected: Empty string is preserved, not converted to nil.
    func testEmptyLastModified() {
        let metadata = Metadata(etag: nil, lastModified: "")
        XCTAssertEqual(metadata.lastModified, "")
    }

    /// Verifies special characters in ETag are preserved.
    ///
    /// ETags can contain various characters including /, +, =.
    ///
    /// Expected: Special characters are preserved.
    func testSpecialCharactersInEtag() {
        let etag = "abc/123+456=789"
        let metadata = Metadata(etag: etag, lastModified: nil)
        XCTAssertEqual(metadata.etag, etag)
    }
}
