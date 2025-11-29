//
//  AsyncCachedImage
//
//  Copyright © 2025 Jan-Hendrik Damerau.
//  https://github.com/uaremad/AsyncCachedImage
//
//  Licensed under the MIT License
//  Free to use without restrictions. See LICENSE file for full terms.
//

import SwiftUI

// MARK: - AsyncCachedImagePhase

/// The current phase of the asynchronous image loading operation.
///
/// Similar to Apple's `AsyncImagePhase`, this enum represents the current state
/// of an image loading operation and provides access to the loaded image or error.
///
/// ## Usage
///
/// ```swift
/// AsyncCachedImage(url: imageURL) { phase in
///     switch phase {
///     case .empty:
///         ProgressView()
///     case .loading:
///         ProgressView()
///     case .success(let image):
///         image.resizable().scaledToFit()
///     case .failure(let error):
///         VStack {
///             Image(systemName: "exclamationmark.triangle")
///             Text(error.localizedDescription)
///         }
///     }
/// }
/// ```
public enum AsyncCachedImagePhase: Sendable {
    /// No image is loaded yet.
    ///
    /// This is the initial state before any loading begins.
    case empty

    /// The image is currently being loaded from cache or network.
    case loading

    /// The image loaded successfully.
    ///
    /// - Parameter image: The loaded SwiftUI Image ready for display.
    case success(Image)

    /// The image failed to load.
    ///
    /// - Parameter error: The error describing why the load failed.
    case failure(ImageLoadingError)

    /// The loaded image, if available.
    ///
    /// Returns the image for `.success` phase, nil for all other phases.
    public var image: Image? {
        if case let .success(image) = self {
            return image
        }
        return nil
    }

    /// The error that occurred, if any.
    ///
    /// Returns the error for `.failure` phase, nil for all other phases.
    public var error: ImageLoadingError? {
        if case let .failure(error) = self {
            return error
        }
        return nil
    }
}

// MARK: - InternalPhase

/// Internal phase representation with PlatformImage for caching.
///
/// Uses `PlatformImage` instead of SwiftUI `Image` to enable storage in NSCache.
/// Converted to `AsyncCachedImagePhase` when exposed to the content closure.
enum InternalPhase: Sendable, Equatable {
    /// No image is loaded yet.
    case empty

    /// The image is currently being loaded.
    case loading

    /// The image loaded successfully.
    case success(PlatformImage)

    /// The image failed to load with the given error.
    case failure(ImageLoadingError)

    /// Compares two phases for equality.
    ///
    /// Success phases are compared by image identity (reference equality).
    /// Failure phases are compared by error description.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side phase.
    ///   - rhs: The right-hand side phase.
    /// - Returns: True if the phases are equal.
    static func == (lhs: InternalPhase, rhs: InternalPhase) -> Bool {
        switch (lhs, rhs) {
        case (.empty, .empty), (.loading, .loading):
            true
        case let (.success(lhsImage), .success(rhsImage)):
            lhsImage === rhsImage
        case let (.failure(lhsError), .failure(rhsError)):
            lhsError.localizedDescription == rhsError.localizedDescription
        default:
            false
        }
    }

    /// Converts the internal phase to a public phase.
    ///
    /// Transforms `PlatformImage` to SwiftUI `Image` with the specified scale.
    ///
    /// - Parameter scale: The scale factor to apply to the image.
    /// - Returns: The corresponding public `AsyncCachedImagePhase`.
    func toPublicPhase(scale: CGFloat) -> AsyncCachedImagePhase {
        switch self {
        case .empty:
            return .empty
        case .loading:
            return .loading
        case let .success(platformImage):
            let image = PlatformImageConverter.toSwiftUIImage(platformImage, scale: scale)
            return .success(image)
        case let .failure(error):
            return .failure(error)
        }
    }
}
