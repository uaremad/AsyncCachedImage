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

// MARK: - MetadataStoreErrorTests

/// Tests for the MetadataStoreError enum which represents metadata persistence failures.
///
/// MetadataStoreError cases:
/// - `.directoryCreationFailed`: Could not create the metadata storage directory
/// - `.encodingFailed`: Could not encode Metadata to JSON
/// - `.writeFailed`: Could not write JSON data to disk
/// - `.decodingFailed`: Could not decode JSON back to Metadata
///
/// These errors relate to the file-based JSON storage used for cache metadata.
final class MetadataStoreErrorTests: XCTestCase {
    // MARK: - Error Case Existence

    /// Verifies .directoryCreationFailed case can be instantiated.
    ///
    /// This error occurs when FileManager cannot create the Metadata directory,
    /// typically due to permission issues or disk full conditions.
    ///
    /// Expected: Error is not nil.
    func testDirectoryCreationFailedErrorExists() {
        let error = MetadataStoreError.directoryCreationFailed
        XCTAssertNotNil(error)
    }

    /// Verifies .encodingFailed case can be instantiated.
    ///
    /// This error occurs when JSONEncoder fails to encode the Metadata struct.
    /// This is rare since Metadata only contains Codable types (String?, Date).
    ///
    /// Expected: Error is not nil.
    func testEncodingFailedErrorExists() {
        let error = MetadataStoreError.encodingFailed
        XCTAssertNotNil(error)
    }

    /// Verifies .writeFailed case can be instantiated.
    ///
    /// This error occurs when Data.write(to:) fails, typically due to
    /// disk full, permission issues, or path problems.
    ///
    /// Expected: Error is not nil.
    func testWriteFailedErrorExists() {
        let error = MetadataStoreError.writeFailed
        XCTAssertNotNil(error)
    }

    /// Verifies .decodingFailed case can be instantiated.
    ///
    /// This error occurs when JSONDecoder cannot parse stored JSON,
    /// which can happen if the file was corrupted or schema changed.
    ///
    /// Expected: Error is not nil.
    func testDecodingFailedErrorExists() {
        let error = MetadataStoreError.decodingFailed
        XCTAssertNotNil(error)
    }

    // MARK: - Protocol Conformance

    /// Verifies MetadataStoreError conforms to Error protocol.
    ///
    /// Expected: Can be assigned to Error type.
    func testConformsToErrorProtocol() {
        let error: Error = MetadataStoreError.directoryCreationFailed
        XCTAssertNotNil(error)
    }

    /// Verifies MetadataStoreError conforms to Sendable protocol.
    ///
    /// Sendable conformance is required for Swift 6 concurrency safety.
    ///
    /// Expected: Can be assigned to Sendable type.
    func testConformsToSendableProtocol() {
        let error: Sendable = MetadataStoreError.directoryCreationFailed
        XCTAssertNotNil(error)
    }

    // MARK: - Equality

    /// Verifies same error cases are equal.
    ///
    /// Expected: Each case equals itself.
    func testSameErrorsAreEqual() {
        XCTAssertEqual(MetadataStoreError.directoryCreationFailed, .directoryCreationFailed)
        XCTAssertEqual(MetadataStoreError.encodingFailed, .encodingFailed)
        XCTAssertEqual(MetadataStoreError.writeFailed, .writeFailed)
        XCTAssertEqual(MetadataStoreError.decodingFailed, .decodingFailed)
    }

    /// Verifies different error cases are not equal.
    ///
    /// Each error represents a distinct failure point in the persistence pipeline.
    ///
    /// Expected: Different cases are not equal.
    func testDifferentErrorsAreNotEqual() {
        XCTAssertNotEqual(MetadataStoreError.directoryCreationFailed, .encodingFailed)
        XCTAssertNotEqual(MetadataStoreError.encodingFailed, .writeFailed)
        XCTAssertNotEqual(MetadataStoreError.writeFailed, .decodingFailed)
        XCTAssertNotEqual(MetadataStoreError.decodingFailed, .directoryCreationFailed)
    }

    // MARK: - Switch Exhaustiveness

    /// Verifies all error cases can be handled in a switch statement.
    ///
    /// Expected: All cases are handled without default clause.
    func testAllCasesCanBeHandled() {
        let errors: [MetadataStoreError] = [
            .directoryCreationFailed,
            .encodingFailed,
            .writeFailed,
            .decodingFailed
        ]

        for error in errors {
            switch error {
            case .directoryCreationFailed:
                XCTAssertEqual(error, .directoryCreationFailed)
            case .encodingFailed:
                XCTAssertEqual(error, .encodingFailed)
            case .writeFailed:
                XCTAssertEqual(error, .writeFailed)
            case .decodingFailed:
                XCTAssertEqual(error, .decodingFailed)
            }
        }
    }

    // MARK: - Error Casting

    /// Verifies MetadataStoreError can be cast from generic Error type.
    ///
    /// Expected: Cast succeeds and preserves the error case.
    func testCanCastFromGenericError() {
        let genericError: Error = MetadataStoreError.encodingFailed

        guard let storeError = genericError as? MetadataStoreError else {
            XCTFail("Failed to cast Error to MetadataStoreError")
            return
        }

        XCTAssertEqual(storeError, .encodingFailed)
    }

    /// Verifies all error cases can be cast from generic Error type.
    ///
    /// Expected: All casts succeed.
    func testCanCastAllCasesFromGenericError() {
        let errors: [Error] = [
            MetadataStoreError.directoryCreationFailed,
            MetadataStoreError.encodingFailed,
            MetadataStoreError.writeFailed,
            MetadataStoreError.decodingFailed
        ]

        for error in errors {
            XCTAssertNotNil(error as? MetadataStoreError, "Failed to cast \(error) to MetadataStoreError")
        }
    }
}
