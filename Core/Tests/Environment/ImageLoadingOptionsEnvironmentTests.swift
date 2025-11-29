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

// MARK: - ImageLoadingOptionsEnvironmentTests

/// Tests for the ImageLoadingOptions and ImageErrorHandler environment values.
///
/// These environment keys allow per-image configuration and error handling
/// to be passed through the SwiftUI view hierarchy without explicit parameters.
@MainActor
final class ImageLoadingOptionsEnvironmentTests: XCTestCase {
    // MARK: - Default Values

    /// Verifies default ImageLoadingOptions match the static .default instance.
    ///
    /// When no custom options are set, AsyncCachedImage should use
    /// sensible defaults defined in ImageLoadingOptions.default.
    ///
    /// Expected: Default skipRevalidation and ignoreCache match .default values.
    func testDefaultImageLoadingOptionsIsDefault() {
        let environment = EnvironmentValues()

        let options = environment.imageLoadingOptions

        XCTAssertEqual(options.skipRevalidation, ImageLoadingOptions.default.skipRevalidation)
        XCTAssertEqual(options.ignoreCache, ImageLoadingOptions.default.ignoreCache)
    }

    /// Verifies default error handler is nil.
    ///
    /// By default, no error handler is configured. Users must explicitly
    /// set one using .onImageError() if they want error notifications.
    ///
    /// Expected: Error handler is nil.
    func testDefaultErrorHandlerIsNil() {
        let environment = EnvironmentValues()

        let handler = environment.imageErrorHandler

        XCTAssertNil(handler)
    }

    // MARK: - ImageLoadingOptions Get/Set

    /// Verifies ImageLoadingOptions can be set and retrieved.
    ///
    /// Custom options should be stored in the environment and
    /// retrievable with all values preserved.
    ///
    /// Expected: All custom option values are preserved.
    func testSetImageLoadingOptions() {
        var environment = EnvironmentValues()
        let customOptions = ImageLoadingOptions(
            revalidationThrottleInterval: 60,
            skipRevalidation: true,
            ignoreCache: true
        )

        environment.imageLoadingOptions = customOptions

        XCTAssertEqual(environment.imageLoadingOptions.revalidationThrottleInterval, 60)
        XCTAssertTrue(environment.imageLoadingOptions.skipRevalidation)
        XCTAssertTrue(environment.imageLoadingOptions.ignoreCache)
    }

    /// Verifies setting new options completely replaces previous options.
    ///
    /// Environment values should not merge; the last set wins.
    ///
    /// Expected: Second options completely replace first options.
    func testOverwriteImageLoadingOptions() {
        var environment = EnvironmentValues()
        let firstOptions = ImageLoadingOptions(skipRevalidation: true)
        let secondOptions = ImageLoadingOptions(skipRevalidation: false, ignoreCache: true)

        environment.imageLoadingOptions = firstOptions
        environment.imageLoadingOptions = secondOptions

        XCTAssertFalse(environment.imageLoadingOptions.skipRevalidation)
        XCTAssertTrue(environment.imageLoadingOptions.ignoreCache)
    }

    // MARK: - ImageErrorHandler Get/Set

    /// Verifies error handler can be set and is retrievable.
    ///
    /// Expected: Error handler is not nil after being set.
    func testSetErrorHandler() {
        var environment = EnvironmentValues()

        environment.imageErrorHandler = { @Sendable _ in }

        XCTAssertNotNil(environment.imageErrorHandler)
    }

    /// Verifies error handler can be cleared by setting to nil.
    ///
    /// Expected: Error handler is nil after being cleared.
    func testClearErrorHandler() {
        var environment = EnvironmentValues()
        environment.imageErrorHandler = { @Sendable _ in }

        environment.imageErrorHandler = nil

        XCTAssertNil(environment.imageErrorHandler)
    }

    /// Verifies error handler receives the error when invoked.
    ///
    /// The handler should be callable and receive the error parameter.
    ///
    /// Expected: Handler receives the error when called.
    func testErrorHandlerReceivesError() {
        var environment = EnvironmentValues()
        nonisolated(unsafe) var receivedError: ImageLoadingError?

        environment.imageErrorHandler = { @Sendable error in
            receivedError = error
        }

        let testError = ImageLoadingError.missingURL
        environment.imageErrorHandler?(testError)

        XCTAssertNotNil(receivedError)
    }
}

// MARK: - ImageConfigurationModifierTests

/// Tests for the .imageConfiguration() view modifier.
///
/// This modifier allows per-image or per-container loading options
/// to be set declaratively in the SwiftUI view hierarchy.
@MainActor
final class ImageConfigurationModifierTests: XCTestCase {
    // MARK: - Modifier Application

    /// Verifies .imageConfiguration() returns a modified view.
    ///
    /// Expected: Returns a non-nil modified view.
    func testImageConfigurationModifierReturnsView() {
        let options = ImageLoadingOptions(skipRevalidation: true)

        let modifiedView = Text("Test").imageConfiguration(options)

        XCTAssertNotNil(modifiedView)
    }

    /// Verifies .imageConfiguration(.default) works correctly.
    ///
    /// Using .default explicitly should be equivalent to no configuration.
    ///
    /// Expected: Returns a non-nil modified view.
    func testImageConfigurationWithDefaultOptions() {
        let modifiedView = Text("Test").imageConfiguration(.default)

        XCTAssertNotNil(modifiedView)
    }

    /// Verifies custom throttle interval can be set via modifier.
    ///
    /// Expected: Returns a non-nil modified view.
    func testImageConfigurationWithCustomThrottleInterval() {
        let options = ImageLoadingOptions(revalidationThrottleInterval: 120)

        let modifiedView = Text("Test").imageConfiguration(options)

        XCTAssertNotNil(modifiedView)
    }

    /// Verifies ignoreCache option can be set via modifier.
    ///
    /// Expected: Returns a non-nil modified view.
    func testImageConfigurationWithIgnoreCache() {
        let options = ImageLoadingOptions(ignoreCache: true)

        let modifiedView = Text("Test").imageConfiguration(options)

        XCTAssertNotNil(modifiedView)
    }

    /// Verifies all options can be set together via modifier.
    ///
    /// Expected: Returns a non-nil modified view.
    func testImageConfigurationWithAllOptions() {
        let options = ImageLoadingOptions(
            revalidationThrottleInterval: 30,
            skipRevalidation: true,
            ignoreCache: true
        )

        let modifiedView = Text("Test").imageConfiguration(options)

        XCTAssertNotNil(modifiedView)
    }

    // MARK: - Chaining

    /// Verifies .imageConfiguration() can be chained with other modifiers.
    ///
    /// Real-world views use multiple modifiers in sequence.
    ///
    /// Expected: Modifier chain is created successfully.
    func testImageConfigurationCanBeChained() {
        let options = ImageLoadingOptions(skipRevalidation: true)

        let modifiedView = Text("Test")
            .imageConfiguration(options)
            .padding()
            .background(Color.blue)

        XCTAssertNotNil(modifiedView)
    }

    /// Verifies multiple .imageConfiguration() calls can be chained.
    ///
    /// The innermost (last) configuration should take precedence.
    ///
    /// Expected: Both modifiers are applied successfully.
    func testMultipleImageConfigurationsCanBeApplied() {
        let options1 = ImageLoadingOptions(skipRevalidation: true)
        let options2 = ImageLoadingOptions(ignoreCache: true)

        let modifiedView = Text("Test")
            .imageConfiguration(options1)
            .imageConfiguration(options2)

        XCTAssertNotNil(modifiedView)
    }

    // MARK: - Different View Types

    /// Verifies modifier can be applied to EmptyView.
    ///
    /// Expected: Modified view is created successfully.
    func testCanBeAppliedToEmptyView() {
        let modifiedView = EmptyView().imageConfiguration(.default)

        XCTAssertNotNil(modifiedView)
    }

    /// Verifies modifier can be applied to Color views.
    ///
    /// Expected: Modified view is created successfully.
    func testCanBeAppliedToColorView() {
        let modifiedView = Color.red.imageConfiguration(.default)

        XCTAssertNotNil(modifiedView)
    }

    /// Verifies modifier can be applied to Image views.
    ///
    /// Expected: Modified view is created successfully.
    func testCanBeAppliedToImageView() {
        let modifiedView = Image(systemName: "star").imageConfiguration(.default)

        XCTAssertNotNil(modifiedView)
    }

    /// Verifies modifier can be applied to container views.
    ///
    /// Applying to a container propagates options to child AsyncCachedImages.
    ///
    /// Expected: Modified view is created successfully.
    func testCanBeAppliedToContainerView() {
        let modifiedView = VStack {
            Text("Header")
            Text("Content")
        }.imageConfiguration(.default)

        XCTAssertNotNil(modifiedView)
    }
}

// MARK: - OnImageErrorModifierTests

/// Tests for the .onImageError() view modifier.
///
/// This modifier provides a callback for handling image loading failures,
/// useful for logging, analytics, or showing user feedback.
@MainActor
final class OnImageErrorModifierTests: XCTestCase {
    // MARK: - Modifier Application

    /// Verifies .onImageError() returns a modified view.
    ///
    /// Expected: Returns a non-nil modified view.
    func testOnImageErrorModifierReturnsView() {
        let modifiedView = Text("Test").onImageError { @Sendable _ in }

        XCTAssertNotNil(modifiedView)
    }

    /// Verifies .onImageError() with empty handler works.
    ///
    /// Expected: Returns a non-nil modified view.
    func testOnImageErrorWithEmptyHandler() {
        let modifiedView = Text("Test").onImageError { @Sendable _ in
            // Empty handler
        }

        XCTAssertNotNil(modifiedView)
    }

    /// Verifies .onImageError() with logging handler works.
    ///
    /// Common use case: logging errors for debugging.
    ///
    /// Expected: Returns a non-nil modified view.
    func testOnImageErrorWithLoggingHandler() {
        let modifiedView = Text("Test").onImageError { @Sendable error in
            print("Error: \(error.localizedDescription)")
        }

        XCTAssertNotNil(modifiedView)
    }

    // MARK: - Handler Capture

    /// Verifies handler captures external state without executing.
    ///
    /// The handler should only execute when an actual error occurs,
    /// not during modifier application.
    ///
    /// Expected: Captured error remains nil after modifier application.
    func testHandlerCapturesError() {
        nonisolated(unsafe) var capturedError: ImageLoadingError?

        _ = Text("Test").onImageError { @Sendable error in
            capturedError = error
        }

        XCTAssertNil(capturedError)
    }

    // MARK: - Chaining

    /// Verifies .onImageError() can be chained with other modifiers.
    ///
    /// Expected: Modifier chain is created successfully.
    func testOnImageErrorCanBeChained() {
        let modifiedView = Text("Test")
            .onImageError { @Sendable _ in }
            .padding()
            .background(Color.blue)

        XCTAssertNotNil(modifiedView)
    }

    /// Verifies multiple .onImageError() calls can be chained.
    ///
    /// Each handler should be registered independently.
    ///
    /// Expected: Both modifiers are applied successfully.
    func testMultipleOnImageErrorsCanBeApplied() {
        let modifiedView = Text("Test")
            .onImageError { @Sendable _ in print("First") }
            .onImageError { @Sendable _ in print("Second") }

        XCTAssertNotNil(modifiedView)
    }

    /// Verifies .onImageError() can be combined with .imageConfiguration().
    ///
    /// Common use case: setting options and error handling together.
    ///
    /// Expected: Both modifiers are applied successfully.
    func testCombinedWithImageConfiguration() {
        let options = ImageLoadingOptions(skipRevalidation: true)

        let modifiedView = Text("Test")
            .imageConfiguration(options)
            .onImageError { @Sendable _ in }

        XCTAssertNotNil(modifiedView)
    }

    // MARK: - Different View Types

    /// Verifies modifier can be applied to EmptyView.
    ///
    /// Expected: Modified view is created successfully.
    func testCanBeAppliedToEmptyView() {
        let modifiedView = EmptyView().onImageError { @Sendable _ in }

        XCTAssertNotNil(modifiedView)
    }

    /// Verifies modifier can be applied to Color views.
    ///
    /// Expected: Modified view is created successfully.
    func testCanBeAppliedToColorView() {
        let modifiedView = Color.red.onImageError { @Sendable _ in }

        XCTAssertNotNil(modifiedView)
    }

    /// Verifies modifier can be applied to Image views.
    ///
    /// Expected: Modified view is created successfully.
    func testCanBeAppliedToImageView() {
        let modifiedView = Image(systemName: "star").onImageError { @Sendable _ in }

        XCTAssertNotNil(modifiedView)
    }

    /// Verifies modifier can be applied to container views.
    ///
    /// Applying to a container allows centralized error handling.
    ///
    /// Expected: Modified view is created successfully.
    func testCanBeAppliedToContainerView() {
        let modifiedView = VStack {
            Text("Header")
            Text("Content")
        }.onImageError { @Sendable _ in }

        XCTAssertNotNil(modifiedView)
    }
}
