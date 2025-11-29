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

// MARK: - ImageLoadingOptions Environment Key

/// Environment key for passing ImageLoadingOptions through the view hierarchy.
private struct ImageLoadingOptionsKey: EnvironmentKey {
    static let defaultValue: ImageLoadingOptions = .default
}

// MARK: - ImageErrorHandler Environment Key

/// Environment key for passing error handler through the view hierarchy.
private struct ImageErrorHandlerKey: EnvironmentKey {
    static let defaultValue: (@Sendable (ImageLoadingError) -> Void)? = nil
}

// MARK: - Environment Values Extension

public extension EnvironmentValues {
    /// The image loading options for AsyncCachedImage views.
    ///
    /// Use the `.imageConfiguration(_:)` modifier to set this value.
    var imageLoadingOptions: ImageLoadingOptions {
        get { self[ImageLoadingOptionsKey.self] }
        set { self[ImageLoadingOptionsKey.self] = newValue }
    }

    /// The error handler for AsyncCachedImage views.
    ///
    /// Use the `.onImageError(_:)` modifier to set this value.
    var imageErrorHandler: (@Sendable (ImageLoadingError) -> Void)? {
        get { self[ImageErrorHandlerKey.self] }
        set { self[ImageErrorHandlerKey.self] = newValue }
    }
}

// MARK: - View Modifiers

public extension View {
    /// Configures loading options for AsyncCachedImage views in this hierarchy.
    ///
    /// Options set here override the global `AsyncCachedImageConfiguration.shared` settings.
    ///
    /// ## Usage
    ///
    /// Apply to a single image:
    /// ```swift
    /// AsyncCachedImage(url: heroImageURL) { image in
    ///     image.resizable()
    /// } placeholder: {
    ///     ProgressView()
    /// }
    /// .imageConfiguration(.hero)
    /// ```
    ///
    /// Apply to a group of images:
    /// ```swift
    /// LazyVGrid(columns: columns) {
    ///     ForEach(thumbnails) { item in
    ///         AsyncCachedImage(url: item.url) { ... }
    ///     }
    /// }
    /// .imageConfiguration(ImageLoadingOptions(
    ///     revalidationThrottleInterval: 30,
    ///     priority: .low
    /// ))
    /// ```
    ///
    /// - Parameter options: The loading options to apply.
    /// - Returns: A view with the specified image loading options.
    func imageConfiguration(_ options: ImageLoadingOptions) -> some View {
        environment(\.imageLoadingOptions, options)
    }

    /// Handles errors from AsyncCachedImage views in this hierarchy.
    ///
    /// Use this to log errors, report to analytics, or show user feedback.
    ///
    /// ## Usage
    ///
    /// ```swift
    /// AsyncCachedImage(url: imageURL) { image in
    ///     image.resizable()
    /// } placeholder: {
    ///     ProgressView()
    /// }
    /// .onImageError { error in
    ///     logger.error("Image load failed: \(error)")
    ///
    ///     // Report to Crashlytics
    ///     Crashlytics.log("Image error: \(error.url?.absoluteString ?? "unknown")")
    /// }
    /// ```
    ///
    /// The error includes useful information:
    /// ```swift
    /// .onImageError { error in
    ///     print("URL: \(error.url?.absoluteString ?? "nil")")
    ///     print("Description: \(error.localizedDescription)")
    ///
    ///     if let statusCode = error.statusCode {
    ///         print("HTTP Status: \(statusCode)")
    ///     }
    /// }
    /// ```
    ///
    /// - Parameter handler: A closure called when an image fails to load.
    /// - Returns: A view with the specified error handler.
    func onImageError(_ handler: @escaping @Sendable (ImageLoadingError) -> Void) -> some View {
        environment(\.imageErrorHandler, handler)
    }
}
