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

final class LoggingTests: XCTestCase {
    func testDefaultLogLevelIsNone() {
        Logging.log = nil

        let logger = Logging.log as? DebugLogger
        XCTAssertNotNil(logger)
        XCTAssertEqual(logger?.level, LogLevel.none)
    }

    func testSetLogLevelCreatesDebugLogger() {
        defer { Logging.log = nil }

        Logging.setLogLevel(.trace)

        let logger = Logging.log as? DebugLogger
        XCTAssertNotNil(logger)
        XCTAssertEqual(logger?.level, .trace)
    }

    func testLogCanBeReplacedWithCustomLogger() {
        defer { Logging.log = nil }

        let customLogger = TestLogger(level: .warn)
        Logging.log = customLogger

        let stored = Logging.log as? TestLogger
        XCTAssertTrue(stored === customLogger)
        XCTAssertEqual(stored?.level, .warn)
    }

    func testLogResetsToNoneWhenCleared() {
        Logging.log = DebugLogger(.error)
        Logging.log = nil

        let logger = Logging.log as? DebugLogger
        XCTAssertNotNil(logger)
        XCTAssertEqual(logger?.level, LogLevel.none)
    }
}

private final class TestLogger: LogProtocol {
    let level: LogLevel

    init(level: LogLevel) {
        self.level = level
    }
}
