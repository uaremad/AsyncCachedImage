//
//  AsyncCachedImage
//
//  Copyright © 2026 Jan-Hendrik Damerau.
//  https://github.com/uaremad/AsyncCachedImage
//
//  Licensed under the MIT License
//  Free to use without restrictions. See LICENSE file for full terms.
//

import Foundation
import XCTest
@testable import AsyncCachedImage

// MARK: - RevalidationThrottlerTests

/// Tests for the RevalidationThrottler which prevents excessive revalidation requests.
///
/// RevalidationThrottler.isThrottled() determines if revalidation should be skipped:
/// - Returns false (not throttled) if lastRevalidation is nil (never revalidated)
/// - Returns false (not throttled) if enough time has passed since lastRevalidation
/// - Returns true (throttled) if within the throttle interval
///
/// This prevents excessive HEAD requests when views appear/disappear frequently.
final class RevalidationThrottlerTests: XCTestCase {
    // MARK: - Nil Last Revalidation

    /// Tests first revalidation (nil lastRevalidation) is not throttled.
    ///
    /// Images that have never been revalidated should revalidate immediately.
    ///
    /// Expected: Returns false (not throttled).
    func testNotThrottledWhenNeverRevalidated() {
        let result = RevalidationThrottler.isThrottled(lastRevalidation: nil, interval: 5.0)

        XCTAssertFalse(result)
    }

    /// Tests nil lastRevalidation with zero interval.
    ///
    /// Expected: Returns false (not throttled).
    func testNotThrottledWithNilAndZeroInterval() {
        let result = RevalidationThrottler.isThrottled(lastRevalidation: nil, interval: 0.0)

        XCTAssertFalse(result)
    }

    /// Tests nil lastRevalidation with large interval.
    ///
    /// Expected: Returns false (not throttled).
    func testNotThrottledWithNilAndLargeInterval() {
        let result = RevalidationThrottler.isThrottled(lastRevalidation: nil, interval: 3600.0)

        XCTAssertFalse(result)
    }

    // MARK: - Within Interval (Throttled)

    /// Tests recent revalidation within interval is throttled.
    ///
    /// Revalidation that just happened should be throttled.
    ///
    /// Expected: Returns true (throttled).
    func testThrottledWhenWithinInterval() {
        let lastRevalidation = Date()

        let result = RevalidationThrottler.isThrottled(lastRevalidation: lastRevalidation, interval: 5.0)

        XCTAssertTrue(result)
    }

    /// Tests revalidation at 4.9 seconds (within 5 second interval).
    ///
    /// Expected: Returns true (throttled).
    func testThrottledAtExactInterval() {
        let lastRevalidation = Date(timeIntervalSinceNow: -4.9)

        let result = RevalidationThrottler.isThrottled(lastRevalidation: lastRevalidation, interval: 5.0)

        XCTAssertTrue(result)
    }

    /// Tests revalidation at 30 seconds (within 60 second interval).
    ///
    /// Expected: Returns true (throttled).
    func testThrottledWithLongInterval() {
        let lastRevalidation = Date(timeIntervalSinceNow: -30)

        let result = RevalidationThrottler.isThrottled(lastRevalidation: lastRevalidation, interval: 60.0)

        XCTAssertTrue(result)
    }

    /// Tests very small time differences are throttled.
    ///
    /// Even 1ms ago should be throttled if within a 100ms interval.
    ///
    /// Expected: Returns true (throttled).
    func testThrottledWithVerySmallInterval() {
        let lastRevalidation = Date(timeIntervalSinceNow: -0.001)

        let result = RevalidationThrottler.isThrottled(lastRevalidation: lastRevalidation, interval: 0.1)

        XCTAssertTrue(result)
    }

    // MARK: - After Interval (Not Throttled)

    /// Tests revalidation after interval has passed is not throttled.
    ///
    /// 10 seconds ago with 5 second interval should allow revalidation.
    ///
    /// Expected: Returns false (not throttled).
    func testNotThrottledWhenIntervalPassed() {
        let lastRevalidation = Date(timeIntervalSinceNow: -10.0)

        let result = RevalidationThrottler.isThrottled(lastRevalidation: lastRevalidation, interval: 5.0)

        XCTAssertFalse(result)
    }

    /// Tests revalidation just past the interval boundary.
    ///
    /// 5.1 seconds ago with 5 second interval should allow revalidation.
    ///
    /// Expected: Returns false (not throttled).
    func testNotThrottledJustAfterInterval() {
        let lastRevalidation = Date(timeIntervalSinceNow: -5.1)

        let result = RevalidationThrottler.isThrottled(lastRevalidation: lastRevalidation, interval: 5.0)

        XCTAssertFalse(result)
    }

    /// Tests very old revalidation is not throttled.
    ///
    /// 1 hour ago should definitely allow revalidation.
    ///
    /// Expected: Returns false (not throttled).
    func testNotThrottledWithVeryOldRevalidation() {
        let lastRevalidation = Date(timeIntervalSinceNow: -3600)

        let result = RevalidationThrottler.isThrottled(lastRevalidation: lastRevalidation, interval: 5.0)

        XCTAssertFalse(result)
    }

    /// Tests short interval allows frequent revalidation.
    ///
    /// 1 second ago with 0.5 second interval should allow revalidation.
    ///
    /// Expected: Returns false (not throttled).
    func testNotThrottledWithShortInterval() {
        let lastRevalidation = Date(timeIntervalSinceNow: -1.0)

        let result = RevalidationThrottler.isThrottled(lastRevalidation: lastRevalidation, interval: 0.5)

        XCTAssertFalse(result)
    }

    // MARK: - Zero Interval

    /// Tests zero interval means never throttle.
    ///
    /// Zero interval allows revalidation on every request.
    ///
    /// Expected: Returns false (not throttled).
    func testNotThrottledWithZeroInterval() {
        let lastRevalidation = Date()

        let result = RevalidationThrottler.isThrottled(lastRevalidation: lastRevalidation, interval: 0.0)

        XCTAssertFalse(result)
    }

    /// Tests zero interval with old revalidation.
    ///
    /// Expected: Returns false (not throttled).
    func testNotThrottledWithZeroIntervalAndOldRevalidation() {
        let lastRevalidation = Date(timeIntervalSinceNow: -100)

        let result = RevalidationThrottler.isThrottled(lastRevalidation: lastRevalidation, interval: 0.0)

        XCTAssertFalse(result)
    }

    // MARK: - Negative Interval

    /// Tests negative interval is treated as zero.
    ///
    /// Negative intervals don't make sense and should allow revalidation.
    ///
    /// Expected: Returns false (not throttled).
    func testNotThrottledWithNegativeInterval() {
        let lastRevalidation = Date()

        let result = RevalidationThrottler.isThrottled(lastRevalidation: lastRevalidation, interval: -1.0)

        XCTAssertFalse(result)
    }

    /// Tests negative interval with old revalidation.
    ///
    /// Expected: Returns false (not throttled).
    func testNotThrottledWithNegativeIntervalAndOldRevalidation() {
        let lastRevalidation = Date(timeIntervalSinceNow: -10.0)

        let result = RevalidationThrottler.isThrottled(lastRevalidation: lastRevalidation, interval: -5.0)

        XCTAssertFalse(result)
    }

    // MARK: - Future Revalidation (Edge Case)

    /// Tests future revalidation timestamp is throttled.
    ///
    /// Clock skew could cause future timestamps. These should be throttled
    /// to prevent issues.
    ///
    /// Expected: Returns true (throttled).
    func testThrottledWithFutureRevalidation() {
        let lastRevalidation = Date(timeIntervalSinceNow: 10.0)

        let result = RevalidationThrottler.isThrottled(lastRevalidation: lastRevalidation, interval: 5.0)

        XCTAssertTrue(result)
    }

    /// Tests far future revalidation with large interval.
    ///
    /// Expected: Returns true (throttled).
    func testThrottledWithFutureRevalidationAndLargeInterval() {
        let lastRevalidation = Date(timeIntervalSinceNow: 100.0)

        let result = RevalidationThrottler.isThrottled(lastRevalidation: lastRevalidation, interval: 60.0)

        XCTAssertTrue(result)
    }

    // MARK: - Boundary Conditions

    /// Tests just inside the throttle boundary.
    ///
    /// 4.999 seconds ago with 5 second interval should be throttled.
    ///
    /// Expected: Returns true (throttled).
    func testThrottledAtExactBoundary() {
        let interval: TimeInterval = 5.0
        let lastRevalidation = Date(timeIntervalSinceNow: -interval + 0.001)

        let result = RevalidationThrottler.isThrottled(lastRevalidation: lastRevalidation, interval: interval)

        XCTAssertTrue(result)
    }

    /// Tests just past the throttle boundary.
    ///
    /// 5.001 seconds ago with 5 second interval should not be throttled.
    ///
    /// Expected: Returns false (not throttled).
    func testNotThrottledJustPastBoundary() {
        let interval: TimeInterval = 5.0
        let lastRevalidation = Date(timeIntervalSinceNow: -interval - 0.001)

        let result = RevalidationThrottler.isThrottled(lastRevalidation: lastRevalidation, interval: interval)

        XCTAssertFalse(result)
    }

    // MARK: - Large Values

    /// Tests very large interval (1 week).
    ///
    /// 1 day ago with 1 week interval should still be throttled.
    ///
    /// Expected: Returns true (throttled).
    func testNotThrottledWithVeryLargeInterval() {
        let lastRevalidation = Date(timeIntervalSinceNow: -86400)

        let result = RevalidationThrottler.isThrottled(lastRevalidation: lastRevalidation, interval: 604_800)

        XCTAssertTrue(result)
    }

    /// Tests Date.distantPast is not throttled.
    ///
    /// distantPast represents a very old date and should allow revalidation.
    ///
    /// Expected: Returns false (not throttled).
    func testNotThrottledWithDistantPast() {
        let lastRevalidation = Date.distantPast

        let result = RevalidationThrottler.isThrottled(lastRevalidation: lastRevalidation, interval: 5.0)

        XCTAssertFalse(result)
    }
}
