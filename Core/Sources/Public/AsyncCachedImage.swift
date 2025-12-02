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

// MARK: - AsyncCachedImage

/// A SwiftUI view that loads and caches images asynchronously.
///
/// Supports multi-level caching (memory and disk) with automatic
/// revalidation based on ETag and Last-Modified headers.
///
/// ## Phase-based Usage (like Apple's AsyncImage)
///
/// ```swift
/// AsyncCachedImage(url: imageURL) { phase in
///     if let image = phase.image {
///         image.resizable().scaledToFit()
///     } else if phase.error != nil {
///         Color.red
///     } else {
///         ProgressView()
///     }
/// }
/// ```
///
/// ## With Scale and Transaction (Apple API parity)
///
/// ```swift
/// AsyncCachedImage(
///     url: imageURL,
///     scale: 2.0,
///     transaction: Transaction(animation: .easeInOut)
/// ) { phase in
///     switch phase {
///     case .empty, .loading:
///         ProgressView()
///     case .success(let image):
///         image.resizable()
///     case .failure:
///         Color.red
///     }
/// }
/// ```
///
/// ## Flicker-Free Re-rendering
///
/// When parent views re-render (e.g., due to SwiftData updates), this view
/// checks the memory cache synchronously during initialization. If the image
/// is already cached, it displays immediately without any loading state,
/// preventing visual flicker.
@MainActor
public struct AsyncCachedImage<Content: View>: View {
    /// The URL of the image to load, or nil if no image should be loaded.
    private let url: URL?

    /// The scale factor to apply to the loaded image.
    ///
    /// A value of 2.0 means the image is @2x and will display at half its pixel size.
    private let scale: CGFloat

    /// The transaction to use when the phase changes.
    ///
    /// Use this to animate transitions between loading states.
    private let transaction: Transaction

    /// Whether to decode the image as a downscaled thumbnail.
    private let asThumbnail: Bool

    /// The content builder that creates views for each phase.
    @ViewBuilder private var content: (AsyncCachedImagePhase) -> Content

    /// The current loading phase.
    ///
    /// Initialized from memory cache synchronously to prevent flicker.
    @State private var phase: InternalPhase

    /// The timestamp of the last revalidation attempt.
    @State private var lastRevalidation: Date?

    /// Per-image loading options from the environment.
    @Environment(\.imageLoadingOptions) private var loadingOptions

    /// Error handler callback from the environment.
    @Environment(\.imageErrorHandler) private var errorHandler

    /// Creates an AsyncCachedImage with phase-based content.
    ///
    /// This initializer provides full control over all loading states,
    /// similar to Apple's `AsyncImage(url:scale:transaction:content:)`.
    ///
    /// The initial phase is set synchronously from the memory cache if available,
    /// preventing flicker when parent views re-render.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load, or nil for no image.
    ///   - scale: The scale factor for the image. Default: 1.0.
    ///            A value of 2.0 means the image is @2x and displays at half its pixel size.
    ///   - transaction: The transaction to use when the phase changes. Default: no animation.
    ///   - asThumbnail: Whether to decode as a downscaled thumbnail. Default: false.
    ///   - content: A closure that returns the view for the current phase.
    public init(
        url: URL?,
        scale: CGFloat = 1.0,
        transaction: Transaction = Transaction(),
        asThumbnail: Bool = false,
        @ViewBuilder content: @escaping (AsyncCachedImagePhase) -> Content
    ) {
        self.url = url
        self.scale = scale
        self.transaction = transaction
        self.asThumbnail = asThumbnail
        self.content = content

        // Initialize phase from memory cache synchronously to prevent flicker
        let initialPhase = Self.resolveInitialPhase(url: url, asThumbnail: asThumbnail)
        _phase = State(initialValue: initialPhase)
    }

    /// The view body that renders the current phase.
    public var body: some View {
        content(phase.toPublicPhase(scale: scale))
            .task(id: url) {
                await loadFromCacheOrNetwork()
            }
            .onAppear {
                Task {
                    await revalidateIfNeeded()
                }
            }
            .modifier(ScenePhaseObserver(onBecameActive: revalidateIfNeeded))
            .onChange(of: phase) { oldPhase, newPhase in
                guard oldPhase != newPhase else { return }
                applyTransaction()
            }
    }

    // MARK: - Initial Phase Resolution

    /// Resolves the initial phase by checking the memory cache synchronously.
    ///
    /// This static method is called during view initialization to provide
    /// an immediate cached image if available, preventing flicker.
    ///
    /// - Parameters:
    ///   - url: The image URL to look up.
    ///   - asThumbnail: Whether to look up the thumbnail variant.
    /// - Returns: Success phase with cached image, or empty phase if not cached.
    private static func resolveInitialPhase(url: URL?, asThumbnail: Bool) -> InternalPhase {
        guard let url else { return .empty }

        if let cachedImage = MemoryCacheStorage.shared.image(for: url, thumb: asThumbnail) {
            return .success(cachedImage)
        }

        return .empty
    }

    /// Applies the transaction animation if configured.
    private func applyTransaction() {
        if transaction.animation != nil {
            withTransaction(transaction) {}
        }
    }
}

// MARK: - Convenience Initializer (without scale/transaction)

public extension AsyncCachedImage {
    /// Creates an AsyncCachedImage with phase-based content using default scale and transaction.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load.
    ///   - asThumbnail: Whether to decode as a thumbnail. Default: false.
    ///   - content: A closure that returns the view for the current phase.
    init(
        url: URL?,
        asThumbnail: Bool = false,
        @ViewBuilder content: @escaping (AsyncCachedImagePhase) -> Content
    ) {
        self.init(url: url, scale: 1.0, transaction: Transaction(), asThumbnail: asThumbnail, content: content)
    }
}

// MARK: - Content + Placeholder Initializer

public extension AsyncCachedImage where Content == AnyView {
    /// Creates an AsyncCachedImage with separate content and placeholder views.
    ///
    /// This is a convenience initializer for the common case where you want
    /// to show a placeholder while loading and the same view for errors.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load.
    ///   - scale: The scale factor for the image. Default: 1.0.
    ///   - asThumbnail: Whether to decode as a thumbnail. Default: false.
    ///   - content: A closure that returns the view to display when loaded.
    ///   - placeholder: A closure that returns the view to display while loading or on error.
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        asThumbnail: Bool = false,
        @ViewBuilder content: @escaping (Image) -> some View,
        @ViewBuilder placeholder: @escaping () -> some View
    ) {
        self.url = url
        self.scale = scale
        transaction = Transaction()
        self.asThumbnail = asThumbnail
        self.content = { phase in
            AnyView(
                Group {
                    if let image = phase.image {
                        content(image)
                    } else {
                        placeholder()
                    }
                }
            )
        }

        // Initialize phase from memory cache synchronously to prevent flicker
        let initialPhase = Self.resolveInitialPhase(url: url, asThumbnail: asThumbnail)
        _phase = State(initialValue: initialPhase)
    }
}

// MARK: - Content + Placeholder + Failure Initializer

public extension AsyncCachedImage where Content == AnyView {
    /// Creates an AsyncCachedImage with separate content, placeholder, and failure views.
    ///
    /// Use this initializer when you want different views for loading and error states.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load.
    ///   - scale: The scale factor for the image. Default: 1.0.
    ///   - asThumbnail: Whether to decode as a thumbnail. Default: false.
    ///   - content: A closure that returns the view to display when loaded.
    ///   - placeholder: A closure that returns the view to display while loading.
    ///   - failure: A closure that returns the view to display on error.
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        asThumbnail: Bool = false,
        @ViewBuilder content: @escaping (Image) -> some View,
        @ViewBuilder placeholder: @escaping () -> some View,
        @ViewBuilder failure: @escaping () -> some View
    ) {
        self.url = url
        self.scale = scale
        transaction = Transaction()
        self.asThumbnail = asThumbnail
        self.content = { phase in
            AnyView(
                Group {
                    switch phase {
                    case let .success(image):
                        content(image)
                    case .failure:
                        failure()
                    case .empty, .loading:
                        placeholder()
                    }
                }
            )
        }

        // Initialize phase from memory cache synchronously to prevent flicker
        let initialPhase = Self.resolveInitialPhase(url: url, asThumbnail: asThumbnail)
        _phase = State(initialValue: initialPhase)
    }
}

// MARK: - Content + Placeholder + Failure with Error Initializer

public extension AsyncCachedImage where Content == AnyView {
    /// Creates an AsyncCachedImage with separate content, placeholder, and failure views.
    ///
    /// The failure closure receives the error for display or logging.
    ///
    /// - Parameters:
    ///   - url: The URL of the image to load.
    ///   - scale: The scale factor for the image. Default: 1.0.
    ///   - asThumbnail: Whether to decode as a thumbnail. Default: false.
    ///   - content: A closure that returns the view to display when loaded.
    ///   - placeholder: A closure that returns the view to display while loading.
    ///   - failure: A closure that receives the error and returns the failure view.
    init(
        url: URL?,
        scale: CGFloat = 1.0,
        asThumbnail: Bool = false,
        @ViewBuilder content: @escaping (Image) -> some View,
        @ViewBuilder placeholder: @escaping () -> some View,
        @ViewBuilder failure: @escaping (ImageLoadingError) -> some View
    ) {
        self.url = url
        self.scale = scale
        transaction = Transaction()
        self.asThumbnail = asThumbnail
        self.content = { phase in
            AnyView(
                Group {
                    switch phase {
                    case let .success(image):
                        content(image)
                    case let .failure(error):
                        failure(error)
                    case .empty, .loading:
                        placeholder()
                    }
                }
            )
        }

        // Initialize phase from memory cache synchronously to prevent flicker
        let initialPhase = Self.resolveInitialPhase(url: url, asThumbnail: asThumbnail)
        _phase = State(initialValue: initialPhase)
    }
}

// MARK: - Cache and Network Loading

private extension AsyncCachedImage {
    /// Loads the image from cache or network as needed.
    ///
    /// This method handles the complete loading flow:
    /// 1. If already loaded (from sync init), skip
    /// 2. Check disk cache if not in memory
    /// 3. Load from network if not cached
    func loadFromCacheOrNetwork() async {
        // Already loaded from memory cache in init
        guard case .empty = phase else { return }

        guard let url else {
            let error = ImageLoadingError.missingURL
            handleError(error)
            updatePhase(.failure(error))
            return
        }

        // Try disk cache before network
        if let diskImage = await loadFromDiskCache(url: url) {
            updatePhase(.success(diskImage))
            return
        }

        // Load from network
        await loadFromNetwork(url: url)
    }

    /// Loads an image from the disk cache.
    ///
    /// - Parameter url: The URL to look up.
    /// - Returns: The cached image, or nil if not found.
    func loadFromDiskCache(url: URL) async -> PlatformImage? {
        await DiskCache.shared.loadCachedImage(for: url, asThumbnail: asThumbnail)
    }

    /// Loads an image from the network.
    ///
    /// - Parameter url: The URL to download from.
    func loadFromNetwork(url: URL) async {
        updatePhase(.loading)

        let ignoreCache = loadingOptions.ignoreCache
        let outcome = await ImageDownloader.shared.downloadWithResult(
            from: url,
            asThumbnail: asThumbnail,
            ignoreCache: ignoreCache
        )

        if let image = outcome.image {
            updatePhase(.success(image))
        } else if let error = outcome.error {
            handleError(error)
            updatePhase(.failure(error))
        } else {
            let error = ImageLoadingError.decodingFailed(url: url)
            handleError(error)
            updatePhase(.failure(error))
        }
    }

    /// Updates the phase, optionally within a transaction.
    ///
    /// - Parameter newPhase: The new phase to set.
    func updatePhase(_ newPhase: InternalPhase) {
        if transaction.animation != nil {
            withTransaction(transaction) {
                phase = newPhase
            }
        } else {
            phase = newPhase
        }
    }

    /// Calls the error handler if one is configured.
    ///
    /// - Parameter error: The error to report.
    func handleError(_ error: ImageLoadingError) {
        errorHandler?(error)
    }
}

// MARK: - Revalidation

private extension AsyncCachedImage {
    /// Revalidates the cached image if needed.
    ///
    /// Only revalidates if:
    /// - The URL is not nil
    /// - The current phase is `.success`
    /// - Revalidation is not skipped via options
    /// - The throttle interval has passed
    /// - The metadata contains ETag or Last-Modified headers
    func revalidateIfNeeded() async {
        guard let url else { return }
        guard case .success = phase else { return }

        if loadingOptions.skipRevalidation {
            return
        }

        let throttleInterval = effectiveThrottleInterval
        if RevalidationThrottler.isThrottled(lastRevalidation: lastRevalidation, interval: throttleInterval) {
            return
        }

        guard let metadata = await loadMetadata(for: url) else { return }
        guard metadata.etag != nil || metadata.lastModified != nil else { return }

        lastRevalidation = Date()
        await performRevalidation(for: url, metadata: metadata)
    }

    /// The effective throttle interval, from per-image options or global config.
    var effectiveThrottleInterval: TimeInterval {
        loadingOptions.revalidationThrottleInterval
            ?? Configuration.shared.revalidationThrottleInterval
    }

    /// Loads metadata for a cached image.
    ///
    /// - Parameter url: The URL to look up.
    /// - Returns: The cached metadata, or nil if not found.
    func loadMetadata(for url: URL) async -> Metadata? {
        await MetadataStore.shared.metadata(for: url, thumb: asThumbnail)
    }

    /// Performs the revalidation check against the server.
    ///
    /// If the cache is still valid, updates the metadata timestamp.
    /// If invalid, invalidates the cache and reloads the image.
    ///
    /// - Parameters:
    ///   - url: The URL to revalidate.
    ///   - metadata: The cached metadata to use for conditional headers.
    func performRevalidation(for url: URL, metadata: Metadata) async {
        let isStillValid = await CacheRevalidator.revalidate(for: url, metadata: metadata)

        if isStillValid {
            await refreshMetadataTimestamp(for: url, metadata: metadata)
        } else {
            await invalidateAndReload(url: url)
        }
    }

    /// Refreshes the metadata timestamp without changing other values.
    ///
    /// - Parameters:
    ///   - url: The URL to update.
    ///   - metadata: The existing metadata to preserve.
    func refreshMetadataTimestamp(for url: URL, metadata: Metadata) async {
        let refreshedMetadata = Metadata(
            etag: metadata.etag,
            lastModified: metadata.lastModified,
            cachedAt: Date()
        )
        await MetadataStore.shared.store(refreshedMetadata, for: url, thumb: asThumbnail)
    }

    /// Invalidates the cache and reloads the image from the server.
    ///
    /// - Parameter url: The URL to reload.
    func invalidateAndReload(url: URL) async {
        await MemoryCache.shared.remove(for: url, thumb: asThumbnail)
        await MetadataStore.shared.remove(for: url, thumb: asThumbnail)

        let outcome = await ImageDownloader.shared.downloadWithResult(
            from: url,
            asThumbnail: asThumbnail,
            ignoreCache: true
        )

        if let image = outcome.image {
            updatePhase(.success(image))
        }
    }
}

// MARK: - PlatformImageConverter

/// Converts platform-specific images to SwiftUI Image.
enum PlatformImageConverter {
    /// Converts a platform image to SwiftUI Image with scale.
    ///
    /// On iOS, applies the scale factor to create properly sized images for Retina displays.
    /// On macOS, scale is not applied as macOS handles resolution differently.
    ///
    /// - Parameters:
    ///   - image: The platform-specific image (UIImage or NSImage).
    ///   - scale: The scale factor for the image. Default: 1.0.
    /// - Returns: A SwiftUI Image ready for display.
    static func toSwiftUIImage(_ image: PlatformImage, scale: CGFloat = 1.0) -> Image {
        #if os(iOS)
        if scale != 1.0, let cgImage = image.cgImage {
            let scaledImage = UIImage(cgImage: cgImage, scale: scale, orientation: image.imageOrientation)
            return Image(uiImage: scaledImage)
        }
        return Image(uiImage: image)
        #else
        return Image(nsImage: image)
        #endif
    }
}
