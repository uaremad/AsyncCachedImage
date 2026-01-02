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
import SwiftUI

#if os(iOS)
import UIKit

/// Platform-specific image type for iOS.
///
/// On iOS, this is `UIImage`. On macOS, this is `NSImage`.
/// Used internally for caching and decoding operations.
public typealias PlatformImage = UIImage

#elseif os(macOS)
import AppKit

/// Platform-specific image type for macOS.
///
/// On iOS, this is `UIImage`. On macOS, this is `NSImage`.
/// Used internally for caching and decoding operations.
public typealias PlatformImage = NSImage

// MARK: - NSImage Sendable Conformance

// NSImage must be Sendable to be used in Sendable structs/enums like
// DownloadOutcome and InternalPhase. This retroactive conformance is
// safe because NSImage is immutable after creation in our usage pattern.
//
// The warning about Apple potentially adding this conformance in the future
// is suppressed because: if Apple adds it, we can simply remove this extension.
#if swift(>=6.0)
extension NSImage: @retroactive @unchecked Sendable {}
#else
extension NSImage: @unchecked Sendable {}
#endif

#endif
