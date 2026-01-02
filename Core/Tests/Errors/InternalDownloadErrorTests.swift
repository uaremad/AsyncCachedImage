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

// MARK: - InternalDownloadErrorTests

/// Tests for the InternalDownloadError enum used within the download pipeline.
///
/// InternalDownloadError is an internal error type without URL information.
/// It is mapped to ImageLoadingError (with URL) before being exposed publicly.
///
/// This separation allows the download pipeline to throw errors without
/// needing URL context at every level, simplifying error handling.
final class InternalDownloadErrorTests: XCTestCase {
    // MARK: - Error Case Existence

    /// Verifies .invalidResponse case can be instantiated.
    ///
    /// This error occurs when URLResponse cannot be cast to HTTPURLResponse.
    ///
    /// Expected: Error is not nil.
    func testInvalidResponseErrorExists() {
        let error = InternalDownloadError.invalidResponse
        XCTAssertNotNil(error)
    }

    /// Verifies .httpError case can be instantiated with status code.
    ///
    /// This error occurs for non-2xx HTTP status codes.
    /// The status code is preserved for mapping to ImageLoadingError.
    ///
    /// Expected: Error is not nil.
    func testHttpErrorExists() {
        let error = InternalDownloadError.httpError(statusCode: 404)
        XCTAssertNotNil(error)
    }

    /// Verifies .emptyData case can be instantiated.
    ///
    /// This error occurs when response body has zero bytes.
    ///
    /// Expected: Error is not nil.
    func testEmptyDataErrorExists() {
        let error = InternalDownloadError.emptyData
        XCTAssertNotNil(error)
    }

    /// Verifies .decodingFailed case can be instantiated.
    ///
    /// This error occurs when ImageDecoder returns nil.
    ///
    /// Expected: Error is not nil.
    func testDecodingFailedErrorExists() {
        let error = InternalDownloadError.decodingFailed
        XCTAssertNotNil(error)
    }

    /// Verifies .invalidImageDimensions case can be instantiated.
    ///
    /// This error occurs when decoded image has dimensions <= 1 pixel.
    ///
    /// Expected: Error is not nil.
    func testInvalidImageDimensionsErrorExists() {
        let error = InternalDownloadError.invalidImageDimensions
        XCTAssertNotNil(error)
    }

    // MARK: - Protocol Conformance

    /// Verifies InternalDownloadError conforms to Error protocol.
    ///
    /// Expected: Can be assigned to Error type.
    func testConformsToErrorProtocol() {
        let error: Error = InternalDownloadError.invalidResponse
        XCTAssertNotNil(error)
    }

    // MARK: - HTTP Error Status Codes

    /// Verifies .httpError preserves 404 status code.
    ///
    /// 404 Not Found is a common error when image URLs are outdated.
    ///
    /// Expected: Status code is extractable via pattern matching.
    func testHttpErrorStores404StatusCode() {
        let error = InternalDownloadError.httpError(statusCode: 404)
        if case let .httpError(statusCode) = error {
            XCTAssertEqual(statusCode, 404)
        } else {
            XCTFail("Expected httpError case")
        }
    }

    /// Verifies .httpError preserves 500 status code.
    ///
    /// 500 Internal Server Error indicates server-side issues.
    ///
    /// Expected: Status code is extractable via pattern matching.
    func testHttpErrorStores500StatusCode() {
        let error = InternalDownloadError.httpError(statusCode: 500)
        if case let .httpError(statusCode) = error {
            XCTAssertEqual(statusCode, 500)
        } else {
            XCTFail("Expected httpError case")
        }
    }

    /// Verifies .httpError preserves 403 status code.
    ///
    /// 403 Forbidden indicates access restrictions.
    ///
    /// Expected: Status code is extractable via pattern matching.
    func testHttpErrorStores403StatusCode() {
        let error = InternalDownloadError.httpError(statusCode: 403)
        if case let .httpError(statusCode) = error {
            XCTAssertEqual(statusCode, 403)
        } else {
            XCTFail("Expected httpError case")
        }
    }

    // MARK: - Equality

    /// Verifies simple error cases (without associated values) equal themselves.
    ///
    /// Expected: Each case equals itself.
    func testSameSimpleErrorsAreEqual() {
        XCTAssertEqual(InternalDownloadError.invalidResponse, .invalidResponse)
        XCTAssertEqual(InternalDownloadError.emptyData, .emptyData)
        XCTAssertEqual(InternalDownloadError.decodingFailed, .decodingFailed)
        XCTAssertEqual(InternalDownloadError.invalidImageDimensions, .invalidImageDimensions)
    }

    /// Verifies .httpError cases with same status code are equal.
    ///
    /// Expected: Same status codes produce equal errors.
    func testHttpErrorsWithSameStatusCodeAreEqual() {
        let error1 = InternalDownloadError.httpError(statusCode: 404)
        let error2 = InternalDownloadError.httpError(statusCode: 404)
        XCTAssertEqual(error1, error2)
    }

    /// Verifies .httpError cases with different status codes are not equal.
    ///
    /// Each status code represents a different failure mode.
    ///
    /// Expected: Different status codes produce different errors.
    func testHttpErrorsWithDifferentStatusCodesAreNotEqual() {
        let error1 = InternalDownloadError.httpError(statusCode: 404)
        let error2 = InternalDownloadError.httpError(statusCode: 500)
        XCTAssertNotEqual(error1, error2)
    }

    /// Verifies different error types are not equal.
    ///
    /// Expected: Different cases are not equal.
    func testDifferentErrorTypesAreNotEqual() {
        XCTAssertNotEqual(InternalDownloadError.invalidResponse, .emptyData)
        XCTAssertNotEqual(InternalDownloadError.emptyData, .decodingFailed)
        XCTAssertNotEqual(InternalDownloadError.decodingFailed, .invalidImageDimensions)
    }

    // MARK: - Switch Exhaustiveness

    /// Verifies all error cases can be handled in a switch statement.
    ///
    /// Expected: All cases are handled without default clause.
    func testAllCasesCanBeHandled() {
        let errors: [InternalDownloadError] = [
            .invalidResponse,
            .httpError(statusCode: 404),
            .emptyData,
            .decodingFailed,
            .invalidImageDimensions
        ]

        for error in errors {
            switch error {
            case .invalidResponse:
                XCTAssertEqual(error, .invalidResponse)
            case let .httpError(statusCode):
                XCTAssertEqual(statusCode, 404)
            case .emptyData:
                XCTAssertEqual(error, .emptyData)
            case .decodingFailed:
                XCTAssertEqual(error, .decodingFailed)
            case .invalidImageDimensions:
                XCTAssertEqual(error, .invalidImageDimensions)
            }
        }
    }

    // MARK: - Error Casting

    /// Verifies InternalDownloadError can be cast from generic Error type.
    ///
    /// Expected: Cast succeeds and preserves the error case.
    func testCanCastFromGenericError() {
        let genericError: Error = InternalDownloadError.invalidResponse

        guard let downloadError = genericError as? InternalDownloadError else {
            XCTFail("Failed to cast Error to InternalDownloadError")
            return
        }

        XCTAssertEqual(downloadError, .invalidResponse)
    }
}
