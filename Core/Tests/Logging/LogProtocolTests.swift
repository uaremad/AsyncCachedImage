//
//  AsyncCachedImage
//
//  Copyright © 2026 Jan-Hendrik Damerau.
//  https://github.com/uaremad/AsyncCachedImage
//
//  Licensed under the MIT License
//  Free to use without restrictions. See LICENSE file for full terms.
//

import Darwin
import Foundation
import XCTest
@testable import AsyncCachedImage

final class LogProtocolTests: XCTestCase {
    func testTraceLogsWhenLevelIsTrace() {
        let logger = DefaultLogger(level: .trace)

        let output = captureStdout {
            logger.trace("hello")
        }

        XCTAssertTrue(output.contains("[TRACE]"))
    }

    func testTraceDoesNotLogWhenLevelIsWarn() {
        let logger = DefaultLogger(level: .warn)

        let output = captureStdout {
            logger.trace("hello")
        }

        XCTAssertTrue(output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    func testWarnLogsWhenLevelIsWarn() {
        let logger = DefaultLogger(level: .warn)

        let output = captureStdout {
            logger.warn("careful")
        }

        XCTAssertTrue(output.contains("[WARN]"))
    }

    func testErrorLogsWhenLevelIsError() {
        let logger = DefaultLogger(level: .error)

        let output = captureStdout {
            logger.error("boom")
        }

        XCTAssertTrue(output.contains("[ERROR]"))
    }

    func testWarnDoesNotLogWhenLevelIsError() {
        let logger = DefaultLogger(level: .error)

        let output = captureStdout {
            logger.warn("nope")
        }

        XCTAssertTrue(output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }

    func testNoLogsWhenLevelIsNone() {
        let logger = DefaultLogger(level: .none)

        let output = captureStdout {
            logger.trace("t")
            logger.warn("w")
            logger.error("e")
        }

        XCTAssertTrue(output.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
    }
}

private struct DefaultLogger: LogProtocol {
    let level: LogLevel
}

private func captureStdout(_ block: () -> Void) -> String {
    let pipe = Pipe()
    let stdoutFD = dup(STDOUT_FILENO)

    dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
    block()
    fflush(stdout)

    dup2(stdoutFD, STDOUT_FILENO)
    close(stdoutFD)
    pipe.fileHandleForWriting.closeFile()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    return String(data: data, encoding: .utf8) ?? ""
}
