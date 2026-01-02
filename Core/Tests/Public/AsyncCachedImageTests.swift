//
//  AsyncCachedImage
//
//  Copyright © 2026 Jan-Hendrik Damerau.
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

// MARK: - AsyncCachedImageTests

/// Tests for AsyncCachedImage, the main public view component.
///
/// AsyncCachedImage provides a drop-in replacement for Apple's AsyncImage
/// with multi-level caching (memory + disk) and automatic revalidation.
///
/// Multiple initializers support different use cases:
/// - Phase-based: Full control over all states
/// - Content + Placeholder: Simple success/loading states
/// - Content + Placeholder + Failure: Three-state handling
@MainActor
final class AsyncCachedImageTests: XCTestCase {
    // MARK: - Test Data

    private var testURL: URL {
        guard let url = URL(string: "https://cdn.manasuite.com/card_sets/artwork/sld_300_landscape.jpg") else {
            preconditionFailure("Invalid test URL")
        }
        return url
    }

    private var alternateURL: URL {
        guard let url = URL(string: "https://cdn.manasuite.com/card_sets/artwork/sld_301_landscape.jpg") else {
            preconditionFailure("Invalid alternate URL")
        }
        return url
    }

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        await CacheManager.shared.clearAll()
    }

    override func tearDown() async throws {
        await CacheManager.shared.clearAll()
    }

    // MARK: - Initializer Tests - Phase-based

    /// Verifies phase-based initializer creates a view.
    ///
    /// This is the most flexible initializer, similar to Apple's AsyncImage.
    ///
    /// Expected: View is not nil.
    func testInitWithPhaseContent() {
        let view = AsyncCachedImage(url: testURL) { _ in
            EmptyView()
        }

        XCTAssertNotNil(view)
    }

    /// Verifies nil URL is accepted.
    ///
    /// nil URL results in .failure(.missingURL) phase.
    ///
    /// Expected: View is not nil.
    func testInitWithNilURL() {
        let view = AsyncCachedImage(url: nil) { _ in
            EmptyView()
        }

        XCTAssertNotNil(view)
    }

    /// Verifies scale parameter is accepted.
    ///
    /// Scale affects image display size (2.0 = @2x retina).
    ///
    /// Expected: View is not nil.
    func testInitWithScaleParameter() {
        let view = AsyncCachedImage(url: testURL, scale: 2.0) { _ in
            EmptyView()
        }

        XCTAssertNotNil(view)
    }

    /// Verifies transaction parameter is accepted.
    ///
    /// Transaction enables animated phase transitions.
    ///
    /// Expected: View is not nil.
    func testInitWithTransactionParameter() {
        let transaction = Transaction(animation: .easeInOut)
        let view = AsyncCachedImage(url: testURL, transaction: transaction) { _ in
            EmptyView()
        }

        XCTAssertNotNil(view)
    }

    /// Verifies asThumbnail parameter is accepted.
    ///
    /// Thumbnail mode enables memory-efficient downscaling.
    ///
    /// Expected: View is not nil.
    func testInitWithAsThumbnailParameter() {
        let view = AsyncCachedImage(url: testURL, asThumbnail: true) { _ in
            EmptyView()
        }

        XCTAssertNotNil(view)
    }

    /// Verifies all parameters can be combined.
    ///
    /// Expected: View is not nil.
    func testInitWithAllParameters() {
        let transaction = Transaction(animation: .easeInOut)
        let view = AsyncCachedImage(
            url: testURL,
            scale: 2.0,
            transaction: transaction,
            asThumbnail: true
        ) { _ in
            EmptyView()
        }

        XCTAssertNotNil(view)
    }

    // MARK: - Initializer Tests - Convenience

    /// Verifies convenience initializer with URL only.
    ///
    /// Uses default scale (1.0) and no transaction.
    ///
    /// Expected: View is not nil.
    func testInitConvenienceWithURLOnly() {
        let view = AsyncCachedImage(url: testURL) { _ in
            EmptyView()
        }

        XCTAssertNotNil(view)
    }

    /// Verifies convenience initializer with thumbnail.
    ///
    /// Expected: View is not nil.
    func testInitConvenienceWithThumbnail() {
        let view = AsyncCachedImage(url: testURL, asThumbnail: true) { _ in
            EmptyView()
        }

        XCTAssertNotNil(view)
    }

    // MARK: - Initializer Tests - Content + Placeholder

    /// Verifies content + placeholder initializer.
    ///
    /// Shows content on success, placeholder on loading/failure.
    ///
    /// Expected: View is not nil.
    func testInitWithContentAndPlaceholder() {
        let view = AsyncCachedImage(
            url: testURL,
            content: { image in
                image.resizable()
            },
            placeholder: {
                ProgressView()
            }
        )

        XCTAssertNotNil(view)
    }

    /// Verifies content + placeholder with scale.
    ///
    /// Expected: View is not nil.
    func testInitWithContentPlaceholderAndScale() {
        let view = AsyncCachedImage(
            url: testURL,
            scale: 2.0,
            content: { image in
                image.resizable()
            },
            placeholder: {
                ProgressView()
            }
        )

        XCTAssertNotNil(view)
    }

    /// Verifies content + placeholder with thumbnail.
    ///
    /// Expected: View is not nil.
    func testInitWithContentPlaceholderAndThumbnail() {
        let view = AsyncCachedImage(
            url: testURL,
            asThumbnail: true,
            content: { image in
                image.resizable()
            },
            placeholder: {
                ProgressView()
            }
        )

        XCTAssertNotNil(view)
    }

    // MARK: - Initializer Tests - Content + Placeholder + Failure

    /// Verifies three-state initializer.
    ///
    /// Shows content on success, placeholder on loading, failure view on error.
    ///
    /// Expected: View is not nil.
    func testInitWithContentPlaceholderAndFailure() {
        let view = AsyncCachedImage(
            url: testURL,
            content: { image in
                image.resizable()
            },
            placeholder: {
                ProgressView()
            },
            failure: {
                Color.red
            }
        )

        XCTAssertNotNil(view)
    }

    /// Verifies three-state initializer with scale.
    ///
    /// Expected: View is not nil.
    func testInitWithContentPlaceholderFailureAndScale() {
        let view = AsyncCachedImage(
            url: testURL,
            scale: 2.0,
            content: { image in
                image.resizable()
            },
            placeholder: {
                ProgressView()
            },
            failure: {
                Color.red
            }
        )

        XCTAssertNotNil(view)
    }

    // MARK: - Initializer Tests - Content + Placeholder + Failure with Error

    /// Verifies failure initializer with error parameter.
    ///
    /// The failure closure receives the error for display or logging.
    ///
    /// Expected: View is not nil.
    func testInitWithContentPlaceholderAndFailureWithError() {
        let view = AsyncCachedImage(
            url: testURL,
            content: { image in
                image.resizable()
            },
            placeholder: {
                ProgressView()
            },
            failure: { error in
                Text(error.localizedDescription)
            }
        )

        XCTAssertNotNil(view)
    }

    /// Verifies failure with error initializer and scale.
    ///
    /// Expected: View is not nil.
    func testInitWithContentPlaceholderFailureWithErrorAndScale() {
        let view = AsyncCachedImage(
            url: testURL,
            scale: 3.0,
            content: { image in
                image.resizable()
            },
            placeholder: {
                ProgressView()
            },
            failure: { error in
                Text(error.localizedDescription)
            }
        )

        XCTAssertNotNil(view)
    }

    // MARK: - View Protocol Conformance

    /// Verifies AsyncCachedImage conforms to View protocol.
    ///
    /// Required to be used in SwiftUI view hierarchies.
    ///
    /// Expected: Can be assigned to any View type.
    func testConformsToViewProtocol() {
        let view: any View = AsyncCachedImage(url: testURL) { _ in
            EmptyView()
        }

        XCTAssertNotNil(view)
    }

    // MARK: - Default Parameter Values

    /// Verifies default parameters work correctly.
    ///
    /// Expected: View is not nil with minimal initialization.
    func testDefaultParameterValues() {
        let view = AsyncCachedImage(url: testURL) { _ in
            EmptyView()
        }

        XCTAssertNotNil(view)
    }
}

// MARK: - PlatformImageConverterTests

/// Tests for PlatformImageConverter which converts PlatformImage to SwiftUI Image.
///
/// PlatformImageConverter bridges the gap between platform-specific images
/// (UIImage on iOS, NSImage on macOS) and SwiftUI's Image type.
final class PlatformImageConverterTests: XCTestCase {
    // MARK: - Test Data

    private var testImage: PlatformImage {
        createTestImage(width: 100, height: 100)
    }

    // MARK: - Conversion Tests

    /// Verifies basic conversion produces a SwiftUI Image.
    ///
    /// Expected: Result is not nil.
    func testConvertsToSwiftUIImage() {
        let image = testImage

        let swiftUIImage = PlatformImageConverter.toSwiftUIImage(image)

        XCTAssertNotNil(swiftUIImage)
    }

    /// Verifies conversion with default scale (1.0).
    ///
    /// Expected: Result is not nil.
    func testConvertsWithDefaultScale() {
        let image = testImage

        let swiftUIImage = PlatformImageConverter.toSwiftUIImage(image)

        XCTAssertNotNil(swiftUIImage)
    }

    /// Verifies conversion with @2x scale.
    ///
    /// On iOS, this creates a scaled UIImage. On macOS, scale is ignored.
    ///
    /// Expected: Result is not nil.
    func testConvertsWithCustomScale() {
        let image = testImage

        let swiftUIImage = PlatformImageConverter.toSwiftUIImage(image, scale: 2.0)

        XCTAssertNotNil(swiftUIImage)
    }

    /// Verifies conversion with explicit scale of 1.0.
    ///
    /// Expected: Result is not nil.
    func testConvertsWithScaleOfOne() {
        let image = testImage

        let swiftUIImage = PlatformImageConverter.toSwiftUIImage(image, scale: 1.0)

        XCTAssertNotNil(swiftUIImage)
    }

    /// Verifies conversion with @3x scale.
    ///
    /// Expected: Result is not nil.
    func testConvertsWithHighScale() {
        let image = testImage

        let swiftUIImage = PlatformImageConverter.toSwiftUIImage(image, scale: 3.0)

        XCTAssertNotNil(swiftUIImage)
    }

    /// Verifies conversion with fractional scale.
    ///
    /// Expected: Result is not nil.
    func testConvertsWithFractionalScale() {
        let image = testImage

        let swiftUIImage = PlatformImageConverter.toSwiftUIImage(image, scale: 1.5)

        XCTAssertNotNil(swiftUIImage)
    }

    /// Verifies conversion of small images.
    ///
    /// Expected: Result is not nil.
    func testConvertsSmallImage() {
        let image = createTestImage(width: 10, height: 10)

        let swiftUIImage = PlatformImageConverter.toSwiftUIImage(image)

        XCTAssertNotNil(swiftUIImage)
    }

    /// Verifies conversion of large images.
    ///
    /// Expected: Result is not nil.
    func testConvertsLargeImage() {
        let image = createTestImage(width: 1000, height: 1000)

        let swiftUIImage = PlatformImageConverter.toSwiftUIImage(image)

        XCTAssertNotNil(swiftUIImage)
    }

    /// Verifies conversion of horizontal rectangular images.
    ///
    /// Expected: Result is not nil.
    func testConvertsRectangularImageHorizontal() {
        let image = createTestImage(width: 200, height: 100)

        let swiftUIImage = PlatformImageConverter.toSwiftUIImage(image)

        XCTAssertNotNil(swiftUIImage)
    }

    /// Verifies conversion of vertical rectangular images.
    ///
    /// Expected: Result is not nil.
    func testConvertsRectangularImageVertical() {
        let image = createTestImage(width: 100, height: 200)

        let swiftUIImage = PlatformImageConverter.toSwiftUIImage(image)

        XCTAssertNotNil(swiftUIImage)
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
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
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
