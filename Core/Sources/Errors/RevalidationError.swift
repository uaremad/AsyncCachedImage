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
enum RevalidationError: Error, Equatable, Sendable {
    /// The server response was not a valid HTTP response.
    case invalidResponse

    /// A network error occurred during revalidation.
    ///
    /// - Parameter message: A description of the network failure.
    case networkFailure(String)
}
