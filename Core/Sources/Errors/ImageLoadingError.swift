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

// MARK: - ImageLoadingError

/// Errors that can occur during image loading.
///
/// Provides detailed error information including the URL that failed
/// and any associated HTTP status codes.
///
/// Use with the `.onImageError()` modifier to handle failures:
/// ```swift
/// AsyncCachedImage(url: imageURL) { ... }
///     .onImageError { error in
///         logger.error("Image failed: \(error)")
///     }
/// ```
public enum ImageLoadingError: Error, Equatable, Sendable {
    /// The server response was not a valid HTTP response.
    case invalidResponse(url: URL)

    /// The server returned an error status code (e.g., 404, 500).
    case httpError(url: URL, statusCode: Int)

    /// The server returned empty data.
    case emptyData(url: URL)

    /// The image data could not be decoded.
    case decodingFailed(url: URL)

    /// The decoded image has invalid dimensions (0x0 or 1x1).
    case invalidImageDimensions(url: URL)

    /// A network error occurred.
    case networkError(url: URL, underlyingError: Error)

    /// The URL was nil.
    case missingURL

    /// The URL for the failed image.
    ///
    /// Returns nil only for `.missingURL` errors.
    public var url: URL? {
        switch self {
        case let .invalidResponse(url),
             let .httpError(url, _),
             let .emptyData(url),
             let .decodingFailed(url),
             let .invalidImageDimensions(url),
             let .networkError(url, _):
            url
        case .missingURL:
            nil
        }
    }

    /// HTTP status code if this was an HTTP error.
    ///
    /// Returns nil for non-HTTP errors.
    public var statusCode: Int? {
        if case let .httpError(_, statusCode) = self {
            return statusCode
        }
        return nil
    }
}

// MARK: - ImageLoadingError + LocalizedError

extension ImageLoadingError: LocalizedError {
    /// A localized description of the error.
    public var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Invalid server response"
        case let .httpError(_, statusCode):
            "HTTP error \(statusCode)"
        case .emptyData:
            "Empty response data"
        case .decodingFailed:
            "Failed to decode image"
        case .invalidImageDimensions:
            "Invalid image dimensions"
        case let .networkError(_, underlyingError):
            "Network error: \(underlyingError.localizedDescription)"
        case .missingURL:
            "Image URL is missing"
        }
    }
}

// MARK: - ImageLoadingError + Equatable

public extension ImageLoadingError {
    static func == (lhs: ImageLoadingError, rhs: ImageLoadingError) -> Bool {
        switch (lhs, rhs) {
        case let (.invalidResponse(lhsURL), .invalidResponse(rhsURL)):
            lhsURL == rhsURL
        case let (.httpError(lhsURL, lhsCode), .httpError(rhsURL, rhsCode)):
            lhsURL == rhsURL && lhsCode == rhsCode
        case let (.emptyData(lhsURL), .emptyData(rhsURL)):
            lhsURL == rhsURL
        case let (.decodingFailed(lhsURL), .decodingFailed(rhsURL)):
            lhsURL == rhsURL
        case let (.invalidImageDimensions(lhsURL), .invalidImageDimensions(rhsURL)):
            lhsURL == rhsURL
        case let (.networkError(lhsURL, lhsError), .networkError(rhsURL, rhsError)):
            lhsURL == rhsURL && lhsError.localizedDescription == rhsError.localizedDescription
        case (.missingURL, .missingURL):
            true
        default:
            false
        }
    }
}
