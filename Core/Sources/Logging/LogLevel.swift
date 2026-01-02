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

/// Defines log levels for AsyncCachedImage logging.
///
/// Lower raw values indicate more verbosity. A logger configured
/// with `.trace` will emit all messages, while `.none` emits nothing.
public enum LogLevel: Int, Sendable {
    /// Most verbose level; prints trace, warn, and error statements.
    case trace = 0
    /// Medium level; prints warn and error statements.
    case warn
    /// Highest level; prints only error statements.
    case error
    /// No logging; suppresses all messages.
    case none
}
