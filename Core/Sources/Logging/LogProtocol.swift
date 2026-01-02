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

/// Protocol for providing custom logging output.
///
/// Implement this to integrate with other logging backends
/// (e.g., OSLog, Crashlytics, or in-house systems).
public protocol LogProtocol {
    var level: LogLevel { get }

    func trace<T>(_ message: @autoclosure () -> T, filename: String, line: Int, function: String)
    func warn<T>(_ message: @autoclosure () -> T, filename: String, line: Int, function: String)
    func error<T>(_ message: @autoclosure () -> T, filename: String, line: Int, function: String)
}

public extension LogProtocol {
    /// Logs a verbose diagnostic message.
    func trace(
        _ message: @autoclosure () -> some Any,
        filename: String = #file,
        line: Int = #line,
        function _: String = #function
    ) {
        let logLevel = LogLevel.trace
        if logLevel.rawValue >= level.rawValue {
            print("[TRACE] \((filename as NSString).lastPathComponent) [\(line)]: \(message())")
        }
    }

    /// Logs a warning that should be visible for debugging.
    func warn(
        _ message: @autoclosure () -> some Any,
        filename: String = #file,
        line: Int = #line,
        function _: String = #function
    ) {
        let logLevel = LogLevel.warn
        if logLevel.rawValue >= level.rawValue {
            print("[WARN] \((filename as NSString).lastPathComponent) [\(line)]: \(message())")
        }
    }

    /// Logs an error that should be visible in production diagnostics.
    func error(
        _ message: @autoclosure () -> some Any,
        filename: String = #file,
        line: Int = #line,
        function _: String = #function
    ) {
        let logLevel = LogLevel.error
        if logLevel.rawValue >= level.rawValue {
            print("[ERROR] \((filename as NSString).lastPathComponent) [\(line)]: \(message())")
        }
    }
}
