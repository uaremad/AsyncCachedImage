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

final class DebugLoggerTests: XCTestCase {
    func testInitStoresLevel() {
        let logger = DebugLogger(.warn)

        XCTAssertEqual(logger.level, .warn)
    }

    func testConformsToLogProtocol() {
        let logger: LogProtocol = DebugLogger(.trace)

        XCTAssertNotNil(logger)
    }
}
