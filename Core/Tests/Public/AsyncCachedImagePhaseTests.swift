//
//  AsyncCachedImage
//
//  Copyright © 2025 Jan-Hendrik Damerau.
//  https://github.com/uaremad/AsyncCachedImage
//
//  Licensed under the MIT License
//  Free to use without restrictions. See LICENSE file for full terms.
//

import SwiftUI
import XCTest
@testable import AsyncCachedImage

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - AsyncCachedImagePhaseTests

/// Tests for AsyncCachedImagePhase which represents loading states.
///
/// AsyncCachedImagePhase mirrors Apple's AsyncImagePhase:
/// - `.empty`: Initial state, no loading has started
/// - `.loading`: Image is being fetched from cache or network
/// - `.success(Image)`: Image loaded successfully
/// - `.failure(ImageLoadingError)`: Loading failed with error
///
/// Used in the phase-based content closure of AsyncCachedImage.
final class AsyncCachedImagePhaseTests: XCTestCase {
    // MARK: - Test Data

    private var testURL: URL {
        guard let url = URL(string: "https://cdn.manasuite.com/card_sets/artwork/sld_300_landscape.jpg") else {
            preconditionFailure("Invalid test URL")
        }
        return url
    }

    // MARK: - Case Existence

    /// Verifies empty case can be instantiated.
    ///
    /// Expected: Phase is not nil.
    func testEmptyCaseExists() {
        let phase = AsyncCachedImagePhase.empty
        XCTAssertNotNil(phase)
    }

    /// Verifies loading case can be instantiated.
    ///
    /// Expected: Phase is not nil.
    func testLoadingCaseExists() {
        let phase = AsyncCachedImagePhase.loading
        XCTAssertNotNil(phase)
    }

    /// Verifies success case can be instantiated with an Image.
    ///
    /// Expected: Phase is not nil.
    func testSuccessCaseExists() {
        let image = Image(systemName: "star")
        let phase = AsyncCachedImagePhase.success(image)
        XCTAssertNotNil(phase)
    }

    /// Verifies failure case can be instantiated with an error.
    ///
    /// Expected: Phase is not nil.
    func testFailureCaseExists() {
        let error = ImageLoadingError.missingURL
        let phase = AsyncCachedImagePhase.failure(error)
        XCTAssertNotNil(phase)
    }

    // MARK: - Protocol Conformance

    /// Verifies AsyncCachedImagePhase conforms to Sendable.
    ///
    /// Required for Swift 6 concurrency safety.
    ///
    /// Expected: Can be assigned to Sendable type.
    func testConformsToSendableProtocol() {
        let phase: Sendable = AsyncCachedImagePhase.empty
        XCTAssertNotNil(phase)
    }

    // MARK: - Image Property

    /// Verifies image property returns nil for empty phase.
    ///
    /// Expected: image is nil.
    func testImagePropertyReturnsNilForEmpty() {
        let phase = AsyncCachedImagePhase.empty

        XCTAssertNil(phase.image)
    }

    /// Verifies image property returns nil for loading phase.
    ///
    /// Expected: image is nil.
    func testImagePropertyReturnsNilForLoading() {
        let phase = AsyncCachedImagePhase.loading

        XCTAssertNil(phase.image)
    }

    /// Verifies image property returns the image for success phase.
    ///
    /// Expected: image is not nil.
    func testImagePropertyReturnsImageForSuccess() {
        let image = Image(systemName: "star")
        let phase = AsyncCachedImagePhase.success(image)

        XCTAssertNotNil(phase.image)
    }

    /// Verifies image property returns nil for failure phase.
    ///
    /// Expected: image is nil.
    func testImagePropertyReturnsNilForFailure() {
        let error = ImageLoadingError.missingURL
        let phase = AsyncCachedImagePhase.failure(error)

        XCTAssertNil(phase.image)
    }

    // MARK: - Error Property

    /// Verifies error property returns nil for empty phase.
    ///
    /// Expected: error is nil.
    func testErrorPropertyReturnsNilForEmpty() {
        let phase = AsyncCachedImagePhase.empty

        XCTAssertNil(phase.error)
    }

    /// Verifies error property returns nil for loading phase.
    ///
    /// Expected: error is nil.
    func testErrorPropertyReturnsNilForLoading() {
        let phase = AsyncCachedImagePhase.loading

        XCTAssertNil(phase.error)
    }

    /// Verifies error property returns nil for success phase.
    ///
    /// Expected: error is nil.
    func testErrorPropertyReturnsNilForSuccess() {
        let image = Image(systemName: "star")
        let phase = AsyncCachedImagePhase.success(image)

        XCTAssertNil(phase.error)
    }

    /// Verifies error property returns the error for failure phase.
    ///
    /// Expected: error is not nil.
    func testErrorPropertyReturnsErrorForFailure() {
        let error = ImageLoadingError.missingURL
        let phase = AsyncCachedImagePhase.failure(error)

        XCTAssertNotNil(phase.error)
    }

    /// Verifies error property preserves error details.
    ///
    /// Associated values like statusCode should be accessible.
    ///
    /// Expected: statusCode is 404.
    func testErrorPropertyPreservesErrorType() {
        let error = ImageLoadingError.httpError(url: testURL, statusCode: 404)
        let phase = AsyncCachedImagePhase.failure(error)

        if case let .httpError(_, statusCode) = phase.error {
            XCTAssertEqual(statusCode, 404)
        } else {
            XCTFail("Expected httpError")
        }
    }

    // MARK: - Switch Exhaustiveness

    /// Verifies all cases can be handled in a switch without default.
    ///
    /// This ensures new cases would cause compile errors.
    ///
    /// Expected: All cases are handled.
    func testAllCasesCanBeHandled() {
        let image = Image(systemName: "star")
        let error = ImageLoadingError.missingURL

        let phases: [AsyncCachedImagePhase] = [
            .empty,
            .loading,
            .success(image),
            .failure(error)
        ]

        for phase in phases {
            switch phase {
            case .empty:
                XCTAssertTrue(true)
            case .loading:
                XCTAssertTrue(true)
            case .success:
                XCTAssertTrue(true)
            case .failure:
                XCTAssertTrue(true)
            }
        }
    }
}

// MARK: - InternalPhaseTests

/// Tests for InternalPhase which uses PlatformImage for caching.
///
/// InternalPhase stores PlatformImage (UIImage/NSImage) instead of SwiftUI Image
/// because NSCache requires reference types. It is converted to AsyncCachedImagePhase
/// when exposed to the content closure.
final class InternalPhaseTests: XCTestCase {
    // MARK: - Test Data

    private var testURL: URL {
        guard let url = URL(string: "https://cdn.manasuite.com/card_sets/artwork/sld_300_landscape.jpg") else {
            preconditionFailure("Invalid test URL")
        }
        return url
    }

    private var testImage: PlatformImage {
        createTestImage(width: 100, height: 100)
    }

    // MARK: - Case Existence

    /// Verifies empty case can be instantiated.
    ///
    /// Expected: Phase is not nil.
    func testEmptyCaseExists() {
        let phase = InternalPhase.empty
        XCTAssertNotNil(phase)
    }

    /// Verifies loading case can be instantiated.
    ///
    /// Expected: Phase is not nil.
    func testLoadingCaseExists() {
        let phase = InternalPhase.loading
        XCTAssertNotNil(phase)
    }

    /// Verifies success case can be instantiated with PlatformImage.
    ///
    /// Expected: Phase is not nil.
    func testSuccessCaseExists() {
        let phase = InternalPhase.success(testImage)
        XCTAssertNotNil(phase)
    }

    /// Verifies failure case can be instantiated with error.
    ///
    /// Expected: Phase is not nil.
    func testFailureCaseExists() {
        let error = ImageLoadingError.missingURL
        let phase = InternalPhase.failure(error)
        XCTAssertNotNil(phase)
    }

    // MARK: - Protocol Conformance

    /// Verifies InternalPhase conforms to Sendable.
    ///
    /// Required for Swift 6 concurrency safety.
    ///
    /// Expected: Can be assigned to Sendable type.
    func testConformsToSendableProtocol() {
        let phase: Sendable = InternalPhase.empty
        XCTAssertNotNil(phase)
    }

    /// Verifies InternalPhase conforms to Equatable.
    ///
    /// Equatable is used to detect phase changes and avoid unnecessary updates.
    ///
    /// Expected: Can be assigned to Equatable type.
    func testConformsToEquatableProtocol() {
        let phase1: any Equatable = InternalPhase.empty
        XCTAssertNotNil(phase1)
    }

    // MARK: - Equality

    /// Verifies empty equals empty.
    ///
    /// Expected: Phases are equal.
    func testEmptyEqualsEmpty() {
        let phase1 = InternalPhase.empty
        let phase2 = InternalPhase.empty

        XCTAssertEqual(phase1, phase2)
    }

    /// Verifies loading equals loading.
    ///
    /// Expected: Phases are equal.
    func testLoadingEqualsLoading() {
        let phase1 = InternalPhase.loading
        let phase2 = InternalPhase.loading

        XCTAssertEqual(phase1, phase2)
    }

    /// Verifies success with same image reference are equal.
    ///
    /// Uses reference equality (===) for images.
    ///
    /// Expected: Phases are equal.
    func testSuccessWithSameImageAreEqual() {
        let image = testImage
        let phase1 = InternalPhase.success(image)
        let phase2 = InternalPhase.success(image)

        XCTAssertEqual(phase1, phase2)
    }

    /// Verifies success with different image instances are not equal.
    ///
    /// Different instances have different references.
    ///
    /// Expected: Phases are not equal.
    func testSuccessWithDifferentImagesAreNotEqual() {
        let image1 = createTestImage(width: 100, height: 100)
        let image2 = createTestImage(width: 100, height: 100)
        let phase1 = InternalPhase.success(image1)
        let phase2 = InternalPhase.success(image2)

        XCTAssertNotEqual(phase1, phase2)
    }

    /// Verifies failures with same error description are equal.
    ///
    /// Compares by localizedDescription string.
    ///
    /// Expected: Phases are equal.
    func testFailureWithSameErrorDescriptionAreEqual() {
        let error1 = ImageLoadingError.missingURL
        let error2 = ImageLoadingError.missingURL
        let phase1 = InternalPhase.failure(error1)
        let phase2 = InternalPhase.failure(error2)

        XCTAssertEqual(phase1, phase2)
    }

    /// Verifies empty does not equal loading.
    ///
    /// Expected: Phases are not equal.
    func testEmptyDoesNotEqualLoading() {
        let phase1 = InternalPhase.empty
        let phase2 = InternalPhase.loading

        XCTAssertNotEqual(phase1, phase2)
    }

    /// Verifies empty does not equal success.
    ///
    /// Expected: Phases are not equal.
    func testEmptyDoesNotEqualSuccess() {
        let phase1 = InternalPhase.empty
        let phase2 = InternalPhase.success(testImage)

        XCTAssertNotEqual(phase1, phase2)
    }

    /// Verifies empty does not equal failure.
    ///
    /// Expected: Phases are not equal.
    func testEmptyDoesNotEqualFailure() {
        let phase1 = InternalPhase.empty
        let phase2 = InternalPhase.failure(.missingURL)

        XCTAssertNotEqual(phase1, phase2)
    }

    // MARK: - toPublicPhase Conversion

    /// Verifies empty converts to public empty.
    ///
    /// Expected: Result is .empty case.
    func testEmptyConvertsToPublicEmpty() {
        let internal_ = InternalPhase.empty

        let public_ = internal_.toPublicPhase(scale: 1.0)

        if case .empty = public_ {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected empty phase")
        }
    }

    /// Verifies loading converts to public loading.
    ///
    /// Expected: Result is .loading case.
    func testLoadingConvertsToPublicLoading() {
        let internal_ = InternalPhase.loading

        let public_ = internal_.toPublicPhase(scale: 1.0)

        if case .loading = public_ {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected loading phase")
        }
    }

    /// Verifies success converts to public success.
    ///
    /// PlatformImage is converted to SwiftUI Image.
    ///
    /// Expected: Result is .success case.
    func testSuccessConvertsToPublicSuccess() {
        let internal_ = InternalPhase.success(testImage)

        let public_ = internal_.toPublicPhase(scale: 1.0)

        if case .success = public_ {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected success phase")
        }
    }

    /// Verifies failure converts to public failure.
    ///
    /// Expected: Result is .failure case.
    func testFailureConvertsToPublicFailure() {
        let error = ImageLoadingError.missingURL
        let internal_ = InternalPhase.failure(error)

        let public_ = internal_.toPublicPhase(scale: 1.0)

        if case .failure = public_ {
            XCTAssertTrue(true)
        } else {
            XCTFail("Expected failure phase")
        }
    }

    /// Verifies success conversion produces accessible image.
    ///
    /// Expected: public_.image is not nil.
    func testSuccessConversionPreservesImage() {
        let internal_ = InternalPhase.success(testImage)

        let public_ = internal_.toPublicPhase(scale: 1.0)

        XCTAssertNotNil(public_.image)
    }

    /// Verifies failure conversion preserves error details.
    ///
    /// Expected: statusCode is 500.
    func testFailureConversionPreservesError() {
        let error = ImageLoadingError.httpError(url: testURL, statusCode: 500)
        let internal_ = InternalPhase.failure(error)

        let public_ = internal_.toPublicPhase(scale: 1.0)

        XCTAssertNotNil(public_.error)
        XCTAssertEqual(public_.error?.statusCode, 500)
    }

    // MARK: - Helper Methods

    private func createTestImage(width: Int, height: Int) -> PlatformImage {
        #if os(iOS)
        return createUIImage(width: width, height: height)
        #elseif os(macOS)
        return createNSImage(width: width, height: height)
        #endif
    }

    #if os(iOS)
    private func createUIImage(width: Int, height: Int) -> UIImage {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    #endif

    #if os(macOS)
    private func createNSImage(width: Int, height: Int) -> NSImage {
        let size = NSSize(width: width, height: height)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return image
    }
    #endif
}
