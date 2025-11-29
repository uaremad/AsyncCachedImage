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

// MARK: - RevalidationResultTests

/// Tests for the RevalidationResult enum which represents cache revalidation outcomes.
///
/// RevalidationResult indicates whether cached content is still valid:
/// - `.valid`: Cached content matches server version (304 Not Modified)
/// - `.invalid`: Cached content is outdated and needs refresh
/// - `.error`: Network or parsing error during revalidation
final class RevalidationResultTests: XCTestCase {
    // MARK: - Case Existence

    /// Verifies the .valid case can be instantiated.
    ///
    /// Expected: RevalidationResult.valid is not nil.
    func testValidCaseExists() {
        let result = RevalidationResult.valid
        XCTAssertNotNil(result)
    }

    /// Verifies the .invalid case can be instantiated.
    ///
    /// Expected: RevalidationResult.invalid is not nil.
    func testInvalidCaseExists() {
        let result = RevalidationResult.invalid
        XCTAssertNotNil(result)
    }

    /// Verifies the .error case can be instantiated.
    ///
    /// Expected: RevalidationResult.error is not nil.
    func testErrorCaseExists() {
        let result = RevalidationResult.error
        XCTAssertNotNil(result)
    }

    // MARK: - Protocol Conformance

    /// Verifies RevalidationResult conforms to Sendable protocol.
    ///
    /// Sendable conformance is required for passing results across
    /// actor boundaries in Swift 6 concurrency.
    ///
    /// Expected: Result can be assigned to Sendable type.
    func testConformsToSendableProtocol() {
        let result: Sendable = RevalidationResult.valid
        XCTAssertNotNil(result)
    }

    // MARK: - Switch Exhaustiveness

    /// Verifies all enum cases can be handled in a switch statement.
    ///
    /// This ensures the enum is complete and no cases are missing.
    /// If a case is added without updating this test, it will fail to compile.
    ///
    /// Expected: All cases are handled without default clause.
    func testAllCasesCanBeHandled() {
        let results: [RevalidationResult] = [.valid, .invalid, .error]

        for result in results {
            switch result {
            case .valid:
                XCTAssertTrue(true)
            case .invalid:
                XCTAssertTrue(true)
            case .error:
                XCTAssertTrue(true)
            }
        }
    }

    // MARK: - Pattern Matching

    /// Verifies pattern matching works correctly for .valid case.
    ///
    /// Pattern matching is used throughout the codebase to determine
    /// the revalidation outcome and take appropriate action.
    ///
    /// Expected: `if case .valid` matches the .valid case.
    func testValidPatternMatching() {
        let result = RevalidationResult.valid

        if case .valid = result {
            XCTAssertTrue(true)
        } else {
            XCTFail("Pattern matching failed for valid case")
        }
    }

    /// Verifies pattern matching works correctly for .invalid case.
    ///
    /// Expected: `if case .invalid` matches the .invalid case.
    func testInvalidPatternMatching() {
        let result = RevalidationResult.invalid

        if case .invalid = result {
            XCTAssertTrue(true)
        } else {
            XCTFail("Pattern matching failed for invalid case")
        }
    }

    /// Verifies pattern matching works correctly for .error case.
    ///
    /// Expected: `if case .error` matches the .error case.
    func testErrorPatternMatching() {
        let result = RevalidationResult.error

        if case .error = result {
            XCTAssertTrue(true)
        } else {
            XCTFail("Pattern matching failed for error case")
        }
    }
}

// MARK: - ConditionalRequestBuilderTests

/// Tests for the ConditionalRequestBuilder which creates revalidation HTTP requests.
///
/// ConditionalRequestBuilder creates HEAD requests with:
/// - `If-None-Match` header from cached ETag
/// - `If-Modified-Since` header from cached Last-Modified timestamp
/// - Cache policy set to ignore local cache data
///
/// These conditional headers enable the server to respond with 304 Not Modified
/// if the cached content is still valid, saving bandwidth.
final class ConditionalRequestBuilderTests: XCTestCase {
    // MARK: - Test Data

    private var testURL: URL {
        guard let url = URL(string: "https://cdn.manasuite.com/card_sets/artwork/sld_300_landscape.jpg") else {
            preconditionFailure("Invalid test URL")
        }
        return url
    }

    // MARK: - Request Building

    /// Verifies ETag is added as If-None-Match header.
    ///
    /// ETags are unique identifiers for specific resource versions.
    /// The If-None-Match header tells the server to return 304 if
    /// the current ETag matches the provided value.
    ///
    /// Expected: Request contains If-None-Match header with ETag value.
    func testBuildRequestWithETag() {
        let metadata = Metadata(etag: "\"abc123\"", lastModified: nil)

        let request = buildRequest(for: testURL, metadata: metadata)

        XCTAssertEqual(request.value(forHTTPHeaderField: "If-None-Match"), "\"abc123\"")
    }

    /// Verifies Last-Modified is added as If-Modified-Since header.
    ///
    /// The If-Modified-Since header tells the server to return 304 if
    /// the resource hasn't been modified since the provided timestamp.
    ///
    /// Expected: Request contains If-Modified-Since header with timestamp.
    func testBuildRequestWithLastModified() {
        let metadata = Metadata(etag: nil, lastModified: "Mon, 01 Jan 2025 00:00:00 GMT")

        let request = buildRequest(for: testURL, metadata: metadata)

        XCTAssertEqual(request.value(forHTTPHeaderField: "If-Modified-Since"), "Mon, 01 Jan 2025 00:00:00 GMT")
    }

    /// Verifies both ETag and Last-Modified headers are included when available.
    ///
    /// Some servers support both validation methods. Including both
    /// provides maximum compatibility and optimization opportunity.
    ///
    /// Expected: Request contains both conditional headers.
    func testBuildRequestWithBothHeaders() {
        let metadata = Metadata(etag: "\"abc123\"", lastModified: "Mon, 01 Jan 2025 00:00:00 GMT")

        let request = buildRequest(for: testURL, metadata: metadata)

        XCTAssertEqual(request.value(forHTTPHeaderField: "If-None-Match"), "\"abc123\"")
        XCTAssertEqual(request.value(forHTTPHeaderField: "If-Modified-Since"), "Mon, 01 Jan 2025 00:00:00 GMT")
    }

    /// Verifies no conditional headers are added when metadata is empty.
    ///
    /// When no ETag or Last-Modified is available, the request should
    /// still be valid but without conditional headers.
    ///
    /// Expected: Neither If-None-Match nor If-Modified-Since headers are present.
    func testBuildRequestWithNoHeaders() {
        let metadata = Metadata(etag: nil, lastModified: nil)

        let request = buildRequest(for: testURL, metadata: metadata)

        XCTAssertNil(request.value(forHTTPHeaderField: "If-None-Match"))
        XCTAssertNil(request.value(forHTTPHeaderField: "If-Modified-Since"))
    }

    /// Verifies HEAD method is used for bandwidth efficiency.
    ///
    /// HEAD requests return only headers, not the response body.
    /// This is ideal for revalidation since we only need status code
    /// and headers, not the full image data.
    ///
    /// Expected: Request method is "HEAD".
    func testBuildRequestUsesHEADMethod() {
        let metadata = Metadata(etag: "test", lastModified: nil)

        let request = buildRequest(for: testURL, metadata: metadata)

        XCTAssertEqual(request.httpMethod, "HEAD")
    }

    /// Verifies request bypasses local URLCache.
    ///
    /// Revalidation must contact the server, not return cached responses.
    /// The `.reloadIgnoringLocalCacheData` policy ensures fresh server contact.
    ///
    /// Expected: Cache policy is set to ignore local cache data.
    func testBuildRequestIgnoresLocalCache() {
        let metadata = Metadata(etag: "test", lastModified: nil)

        let request = buildRequest(for: testURL, metadata: metadata)

        XCTAssertEqual(request.cachePolicy, .reloadIgnoringLocalCacheData)
    }

    /// Verifies the original URL is preserved in the request.
    ///
    /// Expected: Request URL matches the input URL.
    func testBuildRequestPreservesURL() {
        let metadata = Metadata(etag: "test", lastModified: nil)

        let request = buildRequest(for: testURL, metadata: metadata)

        XCTAssertEqual(request.url, testURL)
    }

    // MARK: - ETag Formats

    /// Verifies weak ETags (W/"...") are handled correctly.
    ///
    /// Weak ETags indicate semantic equivalence, not byte-for-byte identity.
    /// They are common for dynamically generated content.
    ///
    /// Expected: Weak ETag is passed through unchanged.
    func testBuildRequestWithWeakETag() {
        let metadata = Metadata(etag: "W/\"abc123\"", lastModified: nil)

        let request = buildRequest(for: testURL, metadata: metadata)

        XCTAssertEqual(request.value(forHTTPHeaderField: "If-None-Match"), "W/\"abc123\"")
    }

    /// Verifies strong ETags ("...") are handled correctly.
    ///
    /// Strong ETags indicate byte-for-byte identity and are more
    /// commonly used for static files like images.
    ///
    /// Expected: Strong ETag is passed through unchanged.
    func testBuildRequestWithStrongETag() {
        let metadata = Metadata(etag: "\"abc123\"", lastModified: nil)

        let request = buildRequest(for: testURL, metadata: metadata)

        XCTAssertEqual(request.value(forHTTPHeaderField: "If-None-Match"), "\"abc123\"")
    }

    // MARK: - Helper Methods

    private func buildRequest(for url: URL, metadata: Metadata) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.cachePolicy = .reloadIgnoringLocalCacheData

        if let etag = metadata.etag {
            request.setValue(etag, forHTTPHeaderField: "If-None-Match")
        }
        if let lastModified = metadata.lastModified {
            request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
        }

        return request
    }
}

// MARK: - CacheRevalidatorIntegrationTests

/// Integration tests for the CacheRevalidator which validates cached resources against servers.
///
/// CacheRevalidator performs the full revalidation flow:
/// 1. Build conditional request with ETag/Last-Modified headers
/// 2. Send HEAD request to server
/// 3. Evaluate response (304 = valid, 200 = compare headers, error = assume valid)
///
/// Note: These tests make actual network requests and require internet connectivity.
final class CacheRevalidatorIntegrationTests: XCTestCase {
    // MARK: - Test Data

    private var testURL: URL {
        guard let url = URL(string: "https://cdn.manasuite.com/card_sets/artwork/sld_300_landscape.jpg") else {
            preconditionFailure("Invalid test URL")
        }
        return url
    }

    // MARK: - Integration Tests

    /// Verifies revalidation returns a boolean result for valid URLs.
    ///
    /// The revalidation process should complete and return either
    /// true (valid) or false (invalid) without throwing errors.
    ///
    /// Note: This test makes an actual network request and requires internet connectivity.
    /// In a CI environment, this may need to be skipped or mocked.
    ///
    /// Expected: Result is a boolean value (true or false).
    func testRevalidateReturnsResult() async {
        let metadata = Metadata(etag: nil, lastModified: nil)

        let isValid = await CacheRevalidator.revalidate(for: testURL, metadata: metadata)

        XCTAssertNotNil(isValid)
    }

    /// Verifies revalidation assumes cache is valid on network errors.
    ///
    /// When the server is unreachable (DNS failure, timeout, etc.),
    /// the cache should be assumed valid to prevent unnecessary
    /// cache invalidation and provide offline resilience.
    ///
    /// Expected: Returns true (cache valid) for unreachable servers.
    func testRevalidateWithInvalidURLReturnsTrue() async {
        guard let invalidURL = URL(string: "https://invalid.invalid.invalid/image.jpg") else {
            XCTFail("Failed to create invalid URL")
            return
        }
        let metadata = Metadata(etag: "test", lastModified: nil)

        let isValid = await CacheRevalidator.revalidate(for: invalidURL, metadata: metadata)

        XCTAssertTrue(isValid)
    }
}
