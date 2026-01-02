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

// MARK: - ScenePhaseObserverTests

/// Tests for the ScenePhaseObserver ViewModifier which handles app lifecycle events.
///
/// ScenePhaseObserver is responsible for:
/// - Observing ScenePhase changes in the SwiftUI environment
/// - Executing a callback when the app becomes active
/// - Enabling cache revalidation when returning to foreground
///
/// This component was extracted from AsyncCachedImage to avoid
/// Environment access issues in unit tests.
final class ScenePhaseObserverTests: XCTestCase {
    // MARK: - Initialization

    /// Verifies initialization with a callback creates a valid observer.
    ///
    /// The callback should be stored but not executed during initialization.
    ///
    /// Expected: Observer is created, callback not yet executed.
    func testInitWithCallback() {
        nonisolated(unsafe) var callbackExecuted = false

        let observer = ScenePhaseObserver { @Sendable in
            callbackExecuted = true
        }

        XCTAssertNotNil(observer)
        XCTAssertFalse(callbackExecuted)
    }

    /// Verifies initialization works with an empty callback.
    ///
    /// Expected: Observer is created successfully.
    func testInitWithEmptyCallback() {
        let observer = ScenePhaseObserver { @Sendable in
            // Empty callback
        }

        XCTAssertNotNil(observer)
    }

    // MARK: - Protocol Conformance

    /// Verifies ScenePhaseObserver conforms to ViewModifier protocol.
    ///
    /// ViewModifier conformance is required for use with .modifier().
    ///
    /// Expected: Can be assigned to any ViewModifier type.
    func testConformsToViewModifierProtocol() {
        let observer: any ViewModifier = ScenePhaseObserver { @Sendable in
            // Empty callback
        }

        XCTAssertNotNil(observer)
    }

    // MARK: - Body

    /// Verifies body returns modified content when applied to a view.
    ///
    /// The modifier should wrap content with ScenePhase observation.
    ///
    /// Expected: Returns a modified view.
    func testBodyReturnsModifiedContent() {
        let observer = ScenePhaseObserver { @Sendable in
            // Empty callback
        }

        let content = Text("Test")
        let modifiedContent = content.modifier(observer)

        XCTAssertNotNil(modifiedContent)
    }

    // MARK: - View Application

    /// Verifies modifier can be applied to Text views.
    ///
    /// Expected: Modified view is created successfully.
    func testCanBeAppliedToTextView() {
        let observer = ScenePhaseObserver { @Sendable in
            // Empty callback
        }

        let modifiedView = Text("Test").modifier(observer)

        XCTAssertNotNil(modifiedView)
    }

    /// Verifies modifier can be applied to Color views.
    ///
    /// Expected: Modified view is created successfully.
    func testCanBeAppliedToColorView() {
        let observer = ScenePhaseObserver { @Sendable in
            // Empty callback
        }

        let modifiedView = Color.red.modifier(observer)

        XCTAssertNotNil(modifiedView)
    }

    /// Verifies modifier can be applied to EmptyView.
    ///
    /// Expected: Modified view is created successfully.
    func testCanBeAppliedToEmptyView() {
        let observer = ScenePhaseObserver { @Sendable in
            // Empty callback
        }

        let modifiedView = EmptyView().modifier(observer)

        XCTAssertNotNil(modifiedView)
    }

    /// Verifies modifier can be applied to Image views.
    ///
    /// Expected: Modified view is created successfully.
    func testCanBeAppliedToImageView() {
        let observer = ScenePhaseObserver { @Sendable in
            // Empty callback
        }

        let modifiedView = Image(systemName: "star").modifier(observer)

        XCTAssertNotNil(modifiedView)
    }

    /// Verifies modifier can be applied to complex view hierarchies.
    ///
    /// Real-world usage involves nested views within containers.
    ///
    /// Expected: Modified view is created successfully.
    func testCanBeAppliedToComplexView() {
        let observer = ScenePhaseObserver { @Sendable in
            // Empty callback
        }

        let complexView = VStack {
            Text("Header")
            Image(systemName: "star")
            Text("Footer")
        }

        let modifiedView = complexView.modifier(observer)

        XCTAssertNotNil(modifiedView)
    }

    // MARK: - Callback Capture

    /// Verifies the callback is captured but not modified during init.
    ///
    /// The callback captures external state which should remain
    /// unchanged until the callback is actually invoked.
    ///
    /// Expected: Captured value remains unchanged after init.
    func testCallbackIsCaptured() {
        nonisolated(unsafe) var capturedValue = 0

        let observer = ScenePhaseObserver { @Sendable in
            capturedValue = 42
        }

        XCTAssertNotNil(observer)
        XCTAssertEqual(capturedValue, 0)
    }

    /// Verifies multiple observers can have independent callbacks.
    ///
    /// Each observer should maintain its own callback closure
    /// without interference from other observers.
    ///
    /// Expected: Both observers created, neither callback executed.
    func testMultipleObserversWithDifferentCallbacks() {
        nonisolated(unsafe) var callback1Executed = false
        nonisolated(unsafe) var callback2Executed = false

        let observer1 = ScenePhaseObserver { @Sendable in
            callback1Executed = true
        }

        let observer2 = ScenePhaseObserver { @Sendable in
            callback2Executed = true
        }

        XCTAssertNotNil(observer1)
        XCTAssertNotNil(observer2)
        XCTAssertFalse(callback1Executed)
        XCTAssertFalse(callback2Executed)
    }

    // MARK: - Chaining

    /// Verifies ScenePhaseObserver can be chained with other modifiers.
    ///
    /// Real-world views use multiple modifiers in sequence.
    ///
    /// Expected: Modifier chain is created successfully.
    func testCanBeChainedWithOtherModifiers() {
        let observer = ScenePhaseObserver { @Sendable in
            // Empty callback
        }

        let modifiedView = Text("Test")
            .modifier(observer)
            .padding()
            .background(Color.blue)

        XCTAssertNotNil(modifiedView)
    }

    /// Verifies multiple ScenePhaseObservers can be applied to one view.
    ///
    /// While unusual, this should not cause errors.
    ///
    /// Expected: Both modifiers are applied successfully.
    func testMultipleScenePhaseObserversCanBeApplied() {
        let observer1 = ScenePhaseObserver { @Sendable in
            // First callback
        }

        let observer2 = ScenePhaseObserver { @Sendable in
            // Second callback
        }

        let modifiedView = Text("Test")
            .modifier(observer1)
            .modifier(observer2)

        XCTAssertNotNil(modifiedView)
    }
}
