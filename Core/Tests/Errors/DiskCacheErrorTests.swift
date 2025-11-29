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

// MARK: - DiskCacheErrorTests

/// Tests for the DiskCacheError enum which represents disk cache operation failures.
///
/// DiskCacheError cases:
/// - `.cacheUnavailable`: URLCache is not configured or accessible
/// - `.dataEmpty`: Cached data exists but is empty
/// - `.decodingFailed`: Cached data could not be decoded as image
/// - `.errorResponseCached`: An HTTP error response was cached instead of image data
final class DiskCacheErrorTests: XCTestCase {
    // MARK: - Error Case Existence

    /// Verifies .cacheUnavailable case can be instantiated.
    ///
    /// This error occurs when URLCache is nil or not properly configured.
    ///
    /// Expected: Error is not nil.
    func testCacheUnavailableErrorExists() {
        let error = DiskCacheError.cacheUnavailable
        XCTAssertNotNil(error)
    }

    /// Verifies .dataEmpty case can be instantiated.
    ///
    /// This error occurs when cache contains an entry with zero bytes.
    ///
    /// Expected: Error is not nil.
    func testDataEmptyErrorExists() {
        let error = DiskCacheError.dataEmpty
        XCTAssertNotNil(error)
    }

    /// Verifies .decodingFailed case can be instantiated.
    ///
    /// This error occurs when cached data cannot be decoded by ImageDecoder.
    ///
    /// Expected: Error is not nil.
    func testDecodingFailedErrorExists() {
        let error = DiskCacheError.decodingFailed
        XCTAssertNotNil(error)
    }

    /// Verifies .errorResponseCached case can be instantiated.
    ///
    /// This error occurs when an HTTP error response (404, 500, etc.)
    /// was incorrectly cached as image data.
    ///
    /// Expected: Error is not nil.
    func testErrorResponseCachedErrorExists() {
        let error = DiskCacheError.errorResponseCached
        XCTAssertNotNil(error)
    }

    // MARK: - Protocol Conformance

    /// Verifies DiskCacheError conforms to Error protocol.
    ///
    /// Error conformance enables use with try/catch and error handling.
    ///
    /// Expected: Can be assigned to Error type.
    func testConformsToErrorProtocol() {
        let error: Error = DiskCacheError.cacheUnavailable
        XCTAssertNotNil(error)
    }

    /// Verifies DiskCacheError conforms to Sendable protocol.
    ///
    /// Sendable conformance is required for Swift 6 concurrency safety.
    ///
    /// Expected: Can be assigned to Sendable type.
    func testConformsToSendableProtocol() {
        let error: Sendable = DiskCacheError.cacheUnavailable
        XCTAssertNotNil(error)
    }

    // MARK: - Equality

    /// Verifies .cacheUnavailable equals itself.
    ///
    /// Expected: Same error case equals itself.
    func testCacheUnavailableEquality() {
        let error1 = DiskCacheError.cacheUnavailable
        let error2 = DiskCacheError.cacheUnavailable
        XCTAssertEqual(error1, error2)
    }

    /// Verifies .dataEmpty equals itself.
    ///
    /// Expected: Same error case equals itself.
    func testDataEmptyEquality() {
        let error1 = DiskCacheError.dataEmpty
        let error2 = DiskCacheError.dataEmpty
        XCTAssertEqual(error1, error2)
    }

    /// Verifies .decodingFailed equals itself.
    ///
    /// Expected: Same error case equals itself.
    func testDecodingFailedEquality() {
        let error1 = DiskCacheError.decodingFailed
        let error2 = DiskCacheError.decodingFailed
        XCTAssertEqual(error1, error2)
    }

    /// Verifies .errorResponseCached equals itself.
    ///
    /// Expected: Same error case equals itself.
    func testErrorResponseCachedEquality() {
        let error1 = DiskCacheError.errorResponseCached
        let error2 = DiskCacheError.errorResponseCached
        XCTAssertEqual(error1, error2)
    }

    /// Verifies different error cases are not equal.
    ///
    /// Each error case represents a distinct failure mode.
    ///
    /// Expected: Different cases are not equal.
    func testDifferentErrorsAreNotEqual() {
        XCTAssertNotEqual(DiskCacheError.cacheUnavailable, DiskCacheError.dataEmpty)
        XCTAssertNotEqual(DiskCacheError.dataEmpty, DiskCacheError.decodingFailed)
        XCTAssertNotEqual(DiskCacheError.decodingFailed, DiskCacheError.errorResponseCached)
        XCTAssertNotEqual(DiskCacheError.errorResponseCached, DiskCacheError.cacheUnavailable)
    }

    // MARK: - Switch Exhaustiveness

    /// Verifies all error cases can be handled in a switch statement.
    ///
    /// This ensures the enum is complete and switch statements
    /// won't need a default case, improving compile-time safety.
    ///
    /// Expected: All cases are handled without default clause.
    func testAllCasesCanBeHandled() {
        let errors: [DiskCacheError] = [
            .cacheUnavailable,
            .dataEmpty,
            .decodingFailed,
            .errorResponseCached
        ]

        for error in errors {
            switch error {
            case .cacheUnavailable:
                XCTAssertEqual(error, .cacheUnavailable)
            case .dataEmpty:
                XCTAssertEqual(error, .dataEmpty)
            case .decodingFailed:
                XCTAssertEqual(error, .decodingFailed)
            case .errorResponseCached:
                XCTAssertEqual(error, .errorResponseCached)
            }
        }
    }

    // MARK: - Error Casting

    /// Verifies DiskCacheError can be cast from generic Error type.
    ///
    /// This is important for error handling in catch blocks.
    ///
    /// Expected: Cast succeeds and preserves the error case.
    func testCanCastFromGenericError() {
        let genericError: Error = DiskCacheError.cacheUnavailable

        guard let diskCacheError = genericError as? DiskCacheError else {
            XCTFail("Failed to cast Error to DiskCacheError")
            return
        }

        XCTAssertEqual(diskCacheError, .cacheUnavailable)
    }

    /// Verifies all error cases can be cast from generic Error type.
    ///
    /// Expected: All casts succeed.
    func testCanCastAllCasesFromGenericError() {
        let errors: [Error] = [
            DiskCacheError.cacheUnavailable,
            DiskCacheError.dataEmpty,
            DiskCacheError.decodingFailed,
            DiskCacheError.errorResponseCached
        ]

        for error in errors {
            XCTAssertNotNil(error as? DiskCacheError, "Failed to cast \(error) to DiskCacheError")
        }
    }
}
