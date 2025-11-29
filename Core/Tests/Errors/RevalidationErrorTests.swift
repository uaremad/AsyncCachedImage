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

// MARK: - RevalidationErrorTests

/// Tests for the RevalidationError enum used during cache revalidation.
///
/// RevalidationError cases:
/// - `.invalidResponse`: Server response was not a valid HTTP response
/// - `.networkFailure(String)`: Network error occurred with descriptive message
///
/// These errors occur during the HEAD request used to check if cached
/// content is still valid via ETag or Last-Modified headers.
final class RevalidationErrorTests: XCTestCase {
    // MARK: - Error Case Existence

    /// Verifies .invalidResponse case can be instantiated.
    ///
    /// This error occurs when the revalidation HEAD request returns
    /// a response that cannot be cast to HTTPURLResponse.
    ///
    /// Expected: Error is not nil.
    func testInvalidResponseErrorExists() {
        let error = RevalidationError.invalidResponse
        XCTAssertNotNil(error)
    }

    /// Verifies .networkFailure case can be instantiated with a message.
    ///
    /// This error wraps network failures with a human-readable description.
    /// Examples: "Connection timeout", "DNS lookup failed", "No internet".
    ///
    /// Expected: Error is not nil.
    func testNetworkFailureErrorExists() {
        let error = RevalidationError.networkFailure("Connection timeout")
        XCTAssertNotNil(error)
    }

    // MARK: - Protocol Conformance

    /// Verifies RevalidationError conforms to Error protocol.
    ///
    /// Expected: Can be assigned to Error type.
    func testConformsToErrorProtocol() {
        let error: Error = RevalidationError.invalidResponse
        XCTAssertNotNil(error)
    }

    /// Verifies RevalidationError conforms to Sendable protocol.
    ///
    /// Sendable conformance is required for Swift 6 concurrency safety.
    ///
    /// Expected: Can be assigned to Sendable type.
    func testConformsToSendableProtocol() {
        let error: Sendable = RevalidationError.invalidResponse
        XCTAssertNotNil(error)
    }

    // MARK: - Network Failure Message

    /// Verifies .networkFailure stores the provided message.
    ///
    /// The message should be extractable for logging or display.
    ///
    /// Expected: Message is preserved and extractable.
    func testNetworkFailureStoresMessage() {
        let message = "Connection timeout"
        let error = RevalidationError.networkFailure(message)

        if case let .networkFailure(storedMessage) = error {
            XCTAssertEqual(storedMessage, message)
        } else {
            XCTFail("Expected networkFailure case")
        }
    }

    /// Verifies .networkFailure can store various message types.
    ///
    /// Different network failures should be distinguishable by message.
    ///
    /// Expected: All messages are preserved correctly.
    func testNetworkFailureStoresDifferentMessages() {
        let messages = [
            "Connection timeout",
            "DNS lookup failed",
            "Server unreachable",
            "SSL handshake failed"
        ]

        for message in messages {
            let error = RevalidationError.networkFailure(message)
            if case let .networkFailure(storedMessage) = error {
                XCTAssertEqual(storedMessage, message)
            } else {
                XCTFail("Expected networkFailure case for message: \(message)")
            }
        }
    }

    /// Verifies .networkFailure accepts empty string as message.
    ///
    /// While not ideal, empty messages should not cause crashes.
    ///
    /// Expected: Empty string is preserved.
    func testNetworkFailureWithEmptyMessage() {
        let error = RevalidationError.networkFailure("")

        if case let .networkFailure(storedMessage) = error {
            XCTAssertEqual(storedMessage, "")
        } else {
            XCTFail("Expected networkFailure case")
        }
    }

    // MARK: - Equality

    /// Verifies .invalidResponse equals itself.
    ///
    /// Expected: Same error case equals itself.
    func testInvalidResponseEquality() {
        let error1 = RevalidationError.invalidResponse
        let error2 = RevalidationError.invalidResponse
        XCTAssertEqual(error1, error2)
    }

    /// Verifies .networkFailure cases with same message are equal.
    ///
    /// Expected: Same messages produce equal errors.
    func testNetworkFailureWithSameMessageAreEqual() {
        let error1 = RevalidationError.networkFailure("timeout")
        let error2 = RevalidationError.networkFailure("timeout")
        XCTAssertEqual(error1, error2)
    }

    /// Verifies .networkFailure cases with different messages are not equal.
    ///
    /// Different failure reasons should be distinguishable.
    ///
    /// Expected: Different messages produce different errors.
    func testNetworkFailureWithDifferentMessagesAreNotEqual() {
        let error1 = RevalidationError.networkFailure("timeout")
        let error2 = RevalidationError.networkFailure("connection refused")
        XCTAssertNotEqual(error1, error2)
    }

    /// Verifies different error types are not equal.
    ///
    /// Expected: .invalidResponse != .networkFailure
    func testDifferentErrorTypesAreNotEqual() {
        let error1 = RevalidationError.invalidResponse
        let error2 = RevalidationError.networkFailure("error")
        XCTAssertNotEqual(error1, error2)
    }

    // MARK: - Switch Exhaustiveness

    /// Verifies all error cases can be handled in a switch statement.
    ///
    /// Expected: All cases are handled without default clause.
    func testAllCasesCanBeHandled() {
        let errors: [RevalidationError] = [
            .invalidResponse,
            .networkFailure("test error")
        ]

        for error in errors {
            switch error {
            case .invalidResponse:
                XCTAssertEqual(error, .invalidResponse)
            case let .networkFailure(message):
                XCTAssertEqual(message, "test error")
            }
        }
    }

    // MARK: - Error Casting

    /// Verifies RevalidationError can be cast from generic Error type.
    ///
    /// Expected: Cast succeeds and preserves the error case.
    func testCanCastFromGenericError() {
        let genericError: Error = RevalidationError.invalidResponse

        guard let revalidationError = genericError as? RevalidationError else {
            XCTFail("Failed to cast Error to RevalidationError")
            return
        }

        XCTAssertEqual(revalidationError, .invalidResponse)
    }

    /// Verifies .networkFailure can be cast from generic Error type.
    ///
    /// Expected: Cast succeeds and message is preserved.
    func testCanCastNetworkFailureFromGenericError() {
        let genericError: Error = RevalidationError.networkFailure("test")

        guard let revalidationError = genericError as? RevalidationError else {
            XCTFail("Failed to cast Error to RevalidationError")
            return
        }

        if case let .networkFailure(message) = revalidationError {
            XCTAssertEqual(message, "test")
        } else {
            XCTFail("Expected networkFailure case")
        }
    }
}
