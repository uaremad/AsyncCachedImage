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

// MARK: - MemoryCacheErrorTests

/// Tests for the MemoryCacheError enum which represents memory cache failures.
///
/// MemoryCacheError currently has only one case:
/// - `.keyCreationFailed`: Could not create a valid NSCache key from URL
///
/// This is a rare error that would only occur with malformed URLs that
/// cannot be converted to NSURL for use as cache keys.
final class MemoryCacheErrorTests: XCTestCase {
    // MARK: - Error Case Existence

    /// Verifies .keyCreationFailed case can be instantiated.
    ///
    /// This error occurs when URL cannot be converted to NSURL for cache key.
    /// In practice, this is extremely rare since URL to NSURL conversion
    /// almost always succeeds.
    ///
    /// Expected: Error is not nil.
    func testKeyCreationFailedErrorExists() {
        let error = MemoryCacheError.keyCreationFailed
        XCTAssertNotNil(error)
    }

    // MARK: - Protocol Conformance

    /// Verifies MemoryCacheError conforms to Error protocol.
    ///
    /// Expected: Can be assigned to Error type.
    func testConformsToErrorProtocol() {
        let error: Error = MemoryCacheError.keyCreationFailed
        XCTAssertNotNil(error)
    }

    /// Verifies MemoryCacheError conforms to Sendable protocol.
    ///
    /// Sendable conformance is required for Swift 6 concurrency safety.
    /// This allows the error to be passed across actor boundaries.
    ///
    /// Expected: Can be assigned to Sendable type.
    func testConformsToSendableProtocol() {
        let error: Sendable = MemoryCacheError.keyCreationFailed
        XCTAssertNotNil(error)
    }

    // MARK: - Equality

    /// Verifies .keyCreationFailed equals itself.
    ///
    /// Expected: Same error case equals itself.
    func testSameErrorsAreEqual() {
        let error1 = MemoryCacheError.keyCreationFailed
        let error2 = MemoryCacheError.keyCreationFailed
        XCTAssertEqual(error1, error2)
    }

    // MARK: - Switch Exhaustiveness

    /// Verifies all error cases can be handled in a switch statement.
    ///
    /// Even with only one case, this test ensures future cases
    /// will require updating switch statements.
    ///
    /// Expected: All cases are handled without default clause.
    func testAllCasesCanBeHandled() {
        let error = MemoryCacheError.keyCreationFailed

        switch error {
        case .keyCreationFailed:
            XCTAssertEqual(error, .keyCreationFailed)
        }
    }

    // MARK: - Error Casting

    /// Verifies MemoryCacheError can be cast from generic Error type.
    ///
    /// This is important for error handling in catch blocks.
    ///
    /// Expected: Cast succeeds and preserves the error case.
    func testCanCastFromGenericError() {
        let genericError: Error = MemoryCacheError.keyCreationFailed

        guard let cacheError = genericError as? MemoryCacheError else {
            XCTFail("Failed to cast Error to MemoryCacheError")
            return
        }

        XCTAssertEqual(cacheError, .keyCreationFailed)
    }
}
