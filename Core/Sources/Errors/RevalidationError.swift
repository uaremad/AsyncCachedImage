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

// MARK: - RevalidationError

/// Errors that can occur during cache revalidation.
///
/// These errors are surfaced when a cached resource cannot be checked
/// against the server using conditional headers.
enum RevalidationError: Error, Equatable, Sendable {
    /// The server response was not a valid HTTP response.
    case invalidResponse

    /// A network error occurred during revalidation.
    ///
    /// - Parameter message: A description of the network failure.
    case networkFailure(String)
}

// MARK: - RevalidationError + LocalizedError

extension RevalidationError: LocalizedError {
    /// Human-readable description for logging or UI surfaces.
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            "Invalid server response during revalidation"
        case let .networkFailure(message):
            message.isEmpty ? "Network error during revalidation" : message
        }
    }
}
