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

// MARK: - InternalDownloadError

/// Internal error type without URL for use during download pipeline.
///
/// The URL is added when mapping to `ImageLoadingError` for public consumption.
enum InternalDownloadError: Error, Equatable, Sendable {
    /// The server response was not a valid HTTP response.
    case invalidResponse

    /// The server returned a non-2xx HTTP status code.
    case httpError(statusCode: Int)

    /// The server returned empty data.
    case emptyData

    /// The image data could not be decoded.
    case decodingFailed

    /// The decoded image has invalid dimensions.
    case invalidImageDimensions
}
