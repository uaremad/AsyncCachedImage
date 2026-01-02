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

// MARK: - DiskCacheError

/// Errors that can occur during disk cache operations.
enum DiskCacheError: Error, Equatable, Sendable {
    /// The URL cache is not available.
    case cacheUnavailable

    /// The cached data is empty.
    case dataEmpty

    /// The cached data could not be decoded as an image.
    case decodingFailed

    /// An error response was cached instead of image data.
    case errorResponseCached
}
