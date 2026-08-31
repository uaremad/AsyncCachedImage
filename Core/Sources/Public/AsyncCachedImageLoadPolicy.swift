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

// MARK: - AsyncCachedImageLoadPolicy

/// Decides whether a URL change requires a new load.
enum AsyncCachedImageLoadPolicy {
    /// The action the loader should take for the current state.
    enum Decision: Equatable {
        /// Do nothing because the current success already belongs to the requested URL.
        case skip

        /// Enter a failure phase because no URL was provided.
        case missingURL

        /// Load the requested URL from memory, disk, or network.
        case load(URL)
    }

    /// Resolves the next loader action.
    ///
    /// A `.success` phase only suppresses loading when its tracked `loadedURL`
    /// exactly matches the requested URL.
    ///
    /// - Parameters:
    ///   - url: The requested URL.
    ///   - phase: The current internal image phase.
    ///   - loadedURL: The URL associated with the current successful image.
    /// - Returns: The loader decision for this state.
    static func decision(
        for url: URL?,
        phase: InternalPhase,
        loadedURL: URL?
    ) -> Decision {
        guard let url else { return .missingURL }

        if case .success = phase, loadedURL == url {
            return .skip
        }

        return .load(url)
    }
}
