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

// MARK: - ImageDecoderError

/// Errors that can occur during image decoding.
enum ImageDecoderError: Error, Equatable, Sendable {
    /// The provided data is empty.
    case emptyData

    /// Failed to create an image source from the data.
    case sourceCreationFailed

    /// Failed to create a thumbnail from the image source.
    case thumbnailCreationFailed

    /// Failed to create a platform image from the decoded data.
    case imageCreationFailed

    /// The decoded image has invalid dimensions (0x0 or 1x1).
    case invalidDimensions
}
