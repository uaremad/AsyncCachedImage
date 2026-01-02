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

/// Default logger that prints to stdout.
///
/// Useful for local debugging or demos where a lightweight logger is enough.
public struct DebugLogger: LogProtocol {
    public let level: LogLevel

    /// Creates a new logger with the given level.
    public init(_ level: LogLevel) {
        self.level = level
    }
}
