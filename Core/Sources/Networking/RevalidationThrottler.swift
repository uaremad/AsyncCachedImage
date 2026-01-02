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

// MARK: - RevalidationThrottler

/// Manages throttling of revalidation requests.
///
/// Prevents excessive network requests by enforcing a minimum interval
/// between revalidation attempts for the same image view.
enum RevalidationThrottler {
    /// Checks if revalidation should be throttled.
    ///
    /// - Parameters:
    ///   - lastRevalidation: The timestamp of the last revalidation, or nil if never revalidated.
    ///   - interval: The minimum interval between revalidations in seconds.
    /// - Returns: True if revalidation should be skipped, false if it should proceed.
    static func isThrottled(lastRevalidation: Date?, interval: TimeInterval) -> Bool {
        guard let last = lastRevalidation else { return false }
        return Date().timeIntervalSince(last) < interval
    }
}
