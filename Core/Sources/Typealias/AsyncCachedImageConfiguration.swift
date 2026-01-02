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

/// Convenience typealias for `Configuration` to avoid naming conflicts.
///
/// Use this when your project has its own `Configuration` type:
/// ```swift
/// AsyncCachedImageConfiguration.shared.revalidationInterval = 60
/// ```
public typealias AsyncCachedImageConfiguration = Configuration
