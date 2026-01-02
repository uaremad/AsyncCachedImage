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

// MARK: - ImageDecoderErrorTests

/// Tests for the ImageDecoderError enum which represents image decoding failures.
///
/// ImageDecoderError cases:
/// - `.emptyData`: Input data has zero bytes
/// - `.sourceCreationFailed`: CGImageSource could not be created from data
/// - `.thumbnailCreationFailed`: Thumbnail generation failed
/// - `.imageCreationFailed`: Platform image (UIImage/NSImage) creation failed
/// - `.invalidDimensions`: Decoded image has 0x0 or 1x1 dimensions
final class ImageDecoderErrorTests: XCTestCase {
    // MARK: - Error Case Existence

    /// Verifies .emptyData case can be instantiated.
    ///
    /// This error occurs when decode() is called with empty Data.
    ///
    /// Expected: Error is not nil.
    func testEmptyDataErrorExists() {
        let error = ImageDecoderError.emptyData
        XCTAssertNotNil(error)
    }

    /// Verifies .sourceCreationFailed case can be instantiated.
    ///
    /// This error occurs when CGImageSourceCreateWithData returns nil,
    /// typically because the data doesn't contain valid image format headers.
    ///
    /// Expected: Error is not nil.
    func testSourceCreationFailedErrorExists() {
        let error = ImageDecoderError.sourceCreationFailed
        XCTAssertNotNil(error)
    }

    /// Verifies .thumbnailCreationFailed case can be instantiated.
    ///
    /// This error occurs when CGImageSourceCreateThumbnailAtIndex fails,
    /// which can happen with corrupted or unsupported image formats.
    ///
    /// Expected: Error is not nil.
    func testThumbnailCreationFailedErrorExists() {
        let error = ImageDecoderError.thumbnailCreationFailed
        XCTAssertNotNil(error)
    }

    /// Verifies .imageCreationFailed case can be instantiated.
    ///
    /// This error occurs when UIImage(data:) or NSImage(data:) returns nil,
    /// even if CGImageSource succeeded.
    ///
    /// Expected: Error is not nil.
    func testImageCreationFailedErrorExists() {
        let error = ImageDecoderError.imageCreationFailed
        XCTAssertNotNil(error)
    }

    /// Verifies .invalidDimensions case can be instantiated.
    ///
    /// This error occurs when decoded image has dimensions <= 1 pixel,
    /// which typically indicates a decoding failure or placeholder image.
    ///
    /// Expected: Error is not nil.
    func testInvalidDimensionsErrorExists() {
        let error = ImageDecoderError.invalidDimensions
        XCTAssertNotNil(error)
    }

    // MARK: - Protocol Conformance

    /// Verifies ImageDecoderError conforms to Error protocol.
    ///
    /// Expected: Can be assigned to Error type.
    func testConformsToErrorProtocol() {
        let error: Error = ImageDecoderError.emptyData
        XCTAssertNotNil(error)
    }

    /// Verifies ImageDecoderError conforms to Sendable protocol.
    ///
    /// Sendable conformance is required for Swift 6 concurrency safety.
    ///
    /// Expected: Can be assigned to Sendable type.
    func testConformsToSendableProtocol() {
        let error: Sendable = ImageDecoderError.emptyData
        XCTAssertNotNil(error)
    }

    // MARK: - Equality

    /// Verifies same error cases are equal.
    ///
    /// Expected: Each case equals itself.
    func testSameErrorsAreEqual() {
        XCTAssertEqual(ImageDecoderError.emptyData, .emptyData)
        XCTAssertEqual(ImageDecoderError.sourceCreationFailed, .sourceCreationFailed)
        XCTAssertEqual(ImageDecoderError.thumbnailCreationFailed, .thumbnailCreationFailed)
        XCTAssertEqual(ImageDecoderError.imageCreationFailed, .imageCreationFailed)
        XCTAssertEqual(ImageDecoderError.invalidDimensions, .invalidDimensions)
    }

    /// Verifies different error cases are not equal.
    ///
    /// Each error case represents a distinct failure point in the decode process.
    ///
    /// Expected: Different cases are not equal.
    func testDifferentErrorsAreNotEqual() {
        XCTAssertNotEqual(ImageDecoderError.emptyData, .sourceCreationFailed)
        XCTAssertNotEqual(ImageDecoderError.sourceCreationFailed, .thumbnailCreationFailed)
        XCTAssertNotEqual(ImageDecoderError.thumbnailCreationFailed, .imageCreationFailed)
        XCTAssertNotEqual(ImageDecoderError.imageCreationFailed, .invalidDimensions)
    }

    // MARK: - Switch Exhaustiveness

    /// Verifies all error cases can be handled in a switch statement.
    ///
    /// Expected: All cases are handled without default clause.
    func testAllCasesCanBeHandled() {
        let errors: [ImageDecoderError] = [
            .emptyData,
            .sourceCreationFailed,
            .thumbnailCreationFailed,
            .imageCreationFailed,
            .invalidDimensions
        ]

        for error in errors {
            switch error {
            case .emptyData:
                XCTAssertEqual(error, .emptyData)
            case .sourceCreationFailed:
                XCTAssertEqual(error, .sourceCreationFailed)
            case .thumbnailCreationFailed:
                XCTAssertEqual(error, .thumbnailCreationFailed)
            case .imageCreationFailed:
                XCTAssertEqual(error, .imageCreationFailed)
            case .invalidDimensions:
                XCTAssertEqual(error, .invalidDimensions)
            }
        }
    }

    // MARK: - Error Casting

    /// Verifies ImageDecoderError can be cast from generic Error type.
    ///
    /// Expected: Cast succeeds and preserves the error case.
    func testCanCastFromGenericError() {
        let genericError: Error = ImageDecoderError.emptyData

        guard let decoderError = genericError as? ImageDecoderError else {
            XCTFail("Failed to cast Error to ImageDecoderError")
            return
        }

        XCTAssertEqual(decoderError, .emptyData)
    }
}
