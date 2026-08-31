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

#endif
