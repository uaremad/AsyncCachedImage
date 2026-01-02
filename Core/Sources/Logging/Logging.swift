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

/// Shared logging configuration and helpers.
public enum Logging {
    private static let storage = LoggerStorage()

    /// The current logger instance. Set to `nil` to reset to `.none`.
    public static var log: LogProtocol? {
        get { storage.log }
        set { storage.log = newValue }
    }

    /// Enables logging with the given level.
    public static func setLogLevel(_ level: LogLevel) {
        log = DebugLogger(level)
        log?.trace("Logging enabled with level: \(level)")
    }
}

/// Thread-safe storage for the shared logger instance.
private final class LoggerStorage: @unchecked Sendable {
    private let lock = NSLock()
    private var storedLog: LogProtocol? = DebugLogger(.none)

    var log: LogProtocol? {
        get {
            lock.lock()
            defer { lock.unlock() }
            return storedLog
        }
        set {
            lock.lock()
            storedLog = newValue ?? DebugLogger(.none)
            lock.unlock()
        }
    }
}
