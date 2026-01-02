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

// MARK: - ImageLoadingErrorTests

/// Tests for the ImageLoadingError enum which represents public-facing loading failures.
///
/// ImageLoadingError is the user-visible error type exposed through:
/// - `.onImageError()` modifier callback
/// - `AsyncCachedImagePhase.failure(error)`
///
/// Each case includes the URL that failed (except `.missingURL`) for debugging.
final class ImageLoadingErrorTests: XCTestCase {
    // MARK: - Test Data

    private var testURL: URL {
        guard let url = URL(string: "https://cdn.manasuite.com/card_sets/artwork/sld_300_landscape.jpg") else {
            preconditionFailure("Invalid test URL")
        }
        return url
    }

    // MARK: - Error Case Existence

    /// Verifies .invalidResponse case can be instantiated.
    ///
    /// This error occurs when the server response is not an HTTPURLResponse.
    ///
    /// Expected: Error is not nil.
    func testInvalidResponseErrorExists() {
        let error = ImageLoadingError.invalidResponse(url: testURL)
        XCTAssertNotNil(error)
    }

    /// Verifies .httpError case can be instantiated.
    ///
    /// This error occurs for non-2xx HTTP status codes (404, 500, etc.).
    ///
    /// Expected: Error is not nil.
    func testHttpErrorExists() {
        let error = ImageLoadingError.httpError(url: testURL, statusCode: 404)
        XCTAssertNotNil(error)
    }

    /// Verifies .emptyData case can be instantiated.
    ///
    /// This error occurs when server returns 200 OK but with zero bytes.
    ///
    /// Expected: Error is not nil.
    func testEmptyDataErrorExists() {
        let error = ImageLoadingError.emptyData(url: testURL)
        XCTAssertNotNil(error)
    }

    /// Verifies .decodingFailed case can be instantiated.
    ///
    /// This error occurs when ImageDecoder cannot decode the downloaded data.
    ///
    /// Expected: Error is not nil.
    func testDecodingFailedErrorExists() {
        let error = ImageLoadingError.decodingFailed(url: testURL)
        XCTAssertNotNil(error)
    }

    /// Verifies .invalidImageDimensions case can be instantiated.
    ///
    /// This error occurs when decoded image has 0x0 or 1x1 dimensions.
    ///
    /// Expected: Error is not nil.
    func testInvalidImageDimensionsErrorExists() {
        let error = ImageLoadingError.invalidImageDimensions(url: testURL)
        XCTAssertNotNil(error)
    }

    /// Verifies .networkError case can be instantiated.
    ///
    /// This error wraps underlying URLSession errors (timeout, DNS, etc.).
    ///
    /// Expected: Error is not nil.
    func testNetworkErrorExists() {
        let underlyingError = NSError(domain: "test", code: -1)
        let error = ImageLoadingError.networkError(url: testURL, underlyingError: underlyingError)
        XCTAssertNotNil(error)
    }

    /// Verifies .missingURL case can be instantiated.
    ///
    /// This error occurs when AsyncCachedImage is initialized with nil URL.
    ///
    /// Expected: Error is not nil.
    func testMissingURLErrorExists() {
        let error = ImageLoadingError.missingURL
        XCTAssertNotNil(error)
    }

    // MARK: - Protocol Conformance

    /// Verifies ImageLoadingError conforms to Error protocol.
    ///
    /// Expected: Can be assigned to Error type.
    func testConformsToErrorProtocol() {
        let error: Error = ImageLoadingError.missingURL
        XCTAssertNotNil(error)
    }

    /// Verifies ImageLoadingError conforms to Sendable protocol.
    ///
    /// Required for passing errors across actor boundaries.
    ///
    /// Expected: Can be assigned to Sendable type.
    func testConformsToSendableProtocol() {
        let error: Sendable = ImageLoadingError.missingURL
        XCTAssertNotNil(error)
    }

    /// Verifies ImageLoadingError conforms to LocalizedError protocol.
    ///
    /// LocalizedError provides user-readable error descriptions.
    ///
    /// Expected: errorDescription is not nil.
    func testConformsToLocalizedErrorProtocol() {
        let error: LocalizedError = ImageLoadingError.missingURL
        XCTAssertNotNil(error.errorDescription)
    }

    // MARK: - URL Property

    /// Verifies .invalidResponse includes the URL.
    ///
    /// Expected: url property returns the associated URL.
    func testInvalidResponseReturnsURL() {
        let error = ImageLoadingError.invalidResponse(url: testURL)
        XCTAssertEqual(error.url, testURL)
    }

    /// Verifies .httpError includes the URL.
    ///
    /// Expected: url property returns the associated URL.
    func testHttpErrorReturnsURL() {
        let error = ImageLoadingError.httpError(url: testURL, statusCode: 500)
        XCTAssertEqual(error.url, testURL)
    }

    /// Verifies .emptyData includes the URL.
    ///
    /// Expected: url property returns the associated URL.
    func testEmptyDataReturnsURL() {
        let error = ImageLoadingError.emptyData(url: testURL)
        XCTAssertEqual(error.url, testURL)
    }

    /// Verifies .decodingFailed includes the URL.
    ///
    /// Expected: url property returns the associated URL.
    func testDecodingFailedReturnsURL() {
        let error = ImageLoadingError.decodingFailed(url: testURL)
        XCTAssertEqual(error.url, testURL)
    }

    /// Verifies .invalidImageDimensions includes the URL.
    ///
    /// Expected: url property returns the associated URL.
    func testInvalidImageDimensionsReturnsURL() {
        let error = ImageLoadingError.invalidImageDimensions(url: testURL)
        XCTAssertEqual(error.url, testURL)
    }

    /// Verifies .networkError includes the URL.
    ///
    /// Expected: url property returns the associated URL.
    func testNetworkErrorReturnsURL() {
        let underlyingError = NSError(domain: "test", code: -1)
        let error = ImageLoadingError.networkError(url: testURL, underlyingError: underlyingError)
        XCTAssertEqual(error.url, testURL)
    }

    /// Verifies .missingURL returns nil for URL property.
    ///
    /// This is the only case without an associated URL.
    ///
    /// Expected: url property is nil.
    func testMissingURLReturnsNil() {
        let error = ImageLoadingError.missingURL
        XCTAssertNil(error.url)
    }

    // MARK: - Status Code Property

    /// Verifies .httpError includes the status code.
    ///
    /// Expected: statusCode property returns 404.
    func testHttpErrorReturnsStatusCode() {
        let error = ImageLoadingError.httpError(url: testURL, statusCode: 404)
        XCTAssertEqual(error.statusCode, 404)
    }

    /// Verifies .httpError preserves 500 status code.
    ///
    /// Expected: statusCode property returns 500.
    func testHttpErrorReturnsStatusCode500() {
        let error = ImageLoadingError.httpError(url: testURL, statusCode: 500)
        XCTAssertEqual(error.statusCode, 500)
    }

    /// Verifies non-HTTP errors return nil for statusCode.
    ///
    /// Only .httpError has a meaningful status code.
    ///
    /// Expected: statusCode is nil for all other cases.
    func testNonHttpErrorReturnsNilStatusCode() {
        let errors: [ImageLoadingError] = [
            .invalidResponse(url: testURL),
            .emptyData(url: testURL),
            .decodingFailed(url: testURL),
            .invalidImageDimensions(url: testURL),
            .missingURL
        ]

        for error in errors {
            XCTAssertNil(error.statusCode, "Expected nil statusCode for \(error)")
        }
    }

    // MARK: - Localized Description

    /// Verifies .invalidResponse provides a readable description.
    ///
    /// Expected: Returns "Invalid server response".
    func testInvalidResponseDescription() {
        let error = ImageLoadingError.invalidResponse(url: testURL)
        XCTAssertEqual(error.errorDescription, "Invalid server response")
    }

    /// Verifies .httpError includes the status code in description.
    ///
    /// Expected: Returns "HTTP error 404".
    func testHttpErrorDescription() {
        let error = ImageLoadingError.httpError(url: testURL, statusCode: 404)
        XCTAssertEqual(error.errorDescription, "HTTP error 404")
    }

    /// Verifies .emptyData provides a readable description.
    ///
    /// Expected: Returns "Empty response data".
    func testEmptyDataDescription() {
        let error = ImageLoadingError.emptyData(url: testURL)
        XCTAssertEqual(error.errorDescription, "Empty response data")
    }

    /// Verifies .decodingFailed provides a readable description.
    ///
    /// Expected: Returns "Failed to decode image".
    func testDecodingFailedDescription() {
        let error = ImageLoadingError.decodingFailed(url: testURL)
        XCTAssertEqual(error.errorDescription, "Failed to decode image")
    }

    /// Verifies .invalidImageDimensions provides a readable description.
    ///
    /// Expected: Returns "Invalid image dimensions".
    func testInvalidImageDimensionsDescription() {
        let error = ImageLoadingError.invalidImageDimensions(url: testURL)
        XCTAssertEqual(error.errorDescription, "Invalid image dimensions")
    }

    /// Verifies .missingURL provides a readable description.
    ///
    /// Expected: Returns "Image URL is missing".
    func testMissingURLDescription() {
        let error = ImageLoadingError.missingURL
        XCTAssertEqual(error.errorDescription, "Image URL is missing")
    }

    /// Verifies .networkError includes the underlying error description.
    ///
    /// This helps users understand what network issue occurred.
    ///
    /// Expected: Description contains the underlying error message.
    func testNetworkErrorDescriptionContainsUnderlyingError() {
        let underlyingError = NSError(domain: "TestDomain", code: 42, userInfo: [
            NSLocalizedDescriptionKey: "Connection failed"
        ])
        let error = ImageLoadingError.networkError(url: testURL, underlyingError: underlyingError)
        XCTAssertTrue(error.errorDescription?.contains("Connection failed") ?? false)
    }

    // MARK: - Switch Exhaustiveness

    /// Verifies all error cases can be handled in a switch statement.
    ///
    /// Expected: All cases are handled without default clause.
    func testAllCasesCanBeHandled() {
        let underlyingError = NSError(domain: "test", code: -1)
        let errors: [ImageLoadingError] = [
            .invalidResponse(url: testURL),
            .httpError(url: testURL, statusCode: 404),
            .emptyData(url: testURL),
            .decodingFailed(url: testURL),
            .invalidImageDimensions(url: testURL),
            .networkError(url: testURL, underlyingError: underlyingError),
            .missingURL
        ]

        for error in errors {
            switch error {
            case .invalidResponse:
                XCTAssertNotNil(error.url)
            case .httpError:
                XCTAssertNotNil(error.statusCode)
            case .emptyData:
                XCTAssertNotNil(error.url)
            case .decodingFailed:
                XCTAssertNotNil(error.url)
            case .invalidImageDimensions:
                XCTAssertNotNil(error.url)
            case .networkError:
                XCTAssertNotNil(error.url)
            case .missingURL:
                XCTAssertNil(error.url)
            }
        }
    }
}
