//
//  AsyncCachedImage
//
//  Copyright © 2025 Jan-Hendrik Damerau.
//  https://github.com/uaremad/AsyncCachedImage
//
//  Licensed under the MIT License
//  Free to use without restrictions. See LICENSE file for full terms.
//

import Foundation

// MARK: - MemoryCacheError

/// Errors that can occur during memory cache operations.
enum MemoryCacheError: Error, Equatable, Sendable {
    /// Failed to create a cache key from the URL.
    case keyCreationFailed
}
