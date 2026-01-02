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

final class LogLevelTests: XCTestCase {
    func testRawValuesMatchExpectedOrder() {
        XCTAssertEqual(LogLevel.trace.rawValue, 0)
        XCTAssertEqual(LogLevel.warn.rawValue, 1)
        XCTAssertEqual(LogLevel.error.rawValue, 2)
        XCTAssertEqual(LogLevel.none.rawValue, 3)
    }

    func testOrderingIsAscendingByVerbosity() {
        XCTAssertLessThan(LogLevel.trace.rawValue, LogLevel.warn.rawValue)
        XCTAssertLessThan(LogLevel.warn.rawValue, LogLevel.error.rawValue)
        XCTAssertLessThan(LogLevel.error.rawValue, LogLevel.none.rawValue)
    }
}
