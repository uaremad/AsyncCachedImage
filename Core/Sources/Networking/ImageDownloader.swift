//
//  AsyncCachedImage
//
//  Copyright © 2025 Jan-Hendrik Damerau.
//  https://github.com/uaremad/AsyncCachedImage
//
//  Licensed under the MIT License
//  Free to use without restrictions. See LICENSE file for full terms.
//

import CoreGraphics
import Foundation

// MARK: - ImageDownloader

/// Downloads and processes images from remote URLs.
///
/// The downloader provides several optimizations:
/// - Request deduplication: Multiple requests for the same URL share one download
/// - Background decoding: Image decoding runs off the main thread
/// - HTTP validation: Error responses are caught before decoding
/// - Automatic caching: Downloaded images are stored in memory and disk caches
///
/// Uses actor isolation for Swift 6 concurrency safety.
actor ImageDownloader {
    /// The shared image downloader instance.
    static let shared = ImageDownloader()

    /// In-flight download tasks, keyed by request for deduplication.
    private var inFlightRequests: [DownloadRequest: Task<DownloadOutcome, Never>] = [:]

    private init() {}

    // MARK: - Public API

    /// Downloads an image from a URL with deduplication.
    ///
    /// If a download for the same URL and thumbnail setting is already in progress,
    /// this method will wait for that download instead of starting a new one.
    ///
    /// - Parameters:
    ///   - url: The image URL to download.
    ///   - asThumbnail: Whether to decode as a downscaled thumbnail.
    ///   - ignoreCache: Whether to bypass the disk cache and force a fresh download.
    /// - Returns: The decoded image, or nil on failure.
    func download(
        from url: URL,
        asThumbnail: Bool,
        ignoreCache: Bool
    ) async -> PlatformImage? {
        let outcome = await downloadWithResult(from: url, asThumbnail: asThumbnail, ignoreCache: ignoreCache)
        return outcome.image
    }

    /// Downloads an image and returns detailed result including any error.
    ///
    /// Use this method when you need to handle or report errors.
    ///
    /// - Parameters:
    ///   - url: The image URL to download.
    ///   - asThumbnail: Whether to decode as a downscaled thumbnail.
    ///   - ignoreCache: Whether to bypass the disk cache and force a fresh download.
    /// - Returns: A `DownloadOutcome` containing either the image or an error.
    func downloadWithResult(
        from url: URL,
        asThumbnail: Bool,
        ignoreCache: Bool
    ) async -> DownloadOutcome {
        let request = DownloadRequest(url: url, asThumbnail: asThumbnail)

        if !ignoreCache, let existingTask = inFlightRequests[request] {
            logDeduplication(url: url)
            return await existingTask.value
        }

        let task = Task<DownloadOutcome, Never> {
            await performDownload(url: url, asThumbnail: asThumbnail, ignoreCache: ignoreCache)
        }

        inFlightRequests[request] = task
        let result = await task.value
        inFlightRequests[request] = nil

        return result
    }

    // MARK: - Download Execution

    /// Performs the actual download, decode, and cache operations.
    ///
    /// - Parameters:
    ///   - url: The image URL to download.
    ///   - asThumbnail: Whether to decode as a thumbnail.
    ///   - ignoreCache: Whether to bypass the disk cache.
    /// - Returns: The download outcome with image or error.
    private func performDownload(
        url: URL,
        asThumbnail: Bool,
        ignoreCache: Bool
    ) async -> DownloadOutcome {
        logDownloadStart(url: url, ignoreCache: ignoreCache)

        if ignoreCache {
            await clearDiskCache(for: url)
        }

        let thumbnailSize = await MainActor.run { Configuration.shared.thumbnailMaxPixelSize }

        do {
            let downloadResult = try await fetchImageData(from: url, ignoreCache: ignoreCache)
            let image = try decodeImageData(
                downloadResult.data,
                asThumbnail: asThumbnail,
                thumbnailMaxPixelSize: thumbnailSize
            )

            await storeInAllCaches(
                image: image,
                downloadResult: downloadResult,
                url: url,
                asThumbnail: asThumbnail
            )

            logDownloadComplete(url: url)
            return .success(image)
        } catch let error as InternalDownloadError {
            let publicError = mapToPublicError(error, url: url)
            logDownloadError(publicError, url: url)
            return .failure(publicError)
        } catch {
            let publicError = ImageLoadingError.networkError(url: url, underlyingError: error)
            logDownloadError(publicError, url: url)
            return .failure(publicError)
        }
    }

    // MARK: - Error Mapping

    /// Maps internal errors to public errors with URL information.
    ///
    /// - Parameters:
    ///   - error: The internal error to map.
    ///   - url: The URL to include in the public error.
    /// - Returns: A public `ImageLoadingError` with full context.
    private func mapToPublicError(_ error: InternalDownloadError, url: URL) -> ImageLoadingError {
        switch error {
        case .invalidResponse:
            .invalidResponse(url: url)
        case let .httpError(statusCode):
            .httpError(url: url, statusCode: statusCode)
        case .emptyData:
            .emptyData(url: url)
        case .decodingFailed:
            .decodingFailed(url: url)
        case .invalidImageDimensions:
            .invalidImageDimensions(url: url)
        }
    }
}

// MARK: - Network Operations

private extension ImageDownloader {
    /// Contains the raw data and response from a successful download.
    struct DownloadResult: Sendable {
        /// The downloaded image data.
        let data: Data

        /// The HTTP response from the server.
        let response: HTTPURLResponse
    }

    /// Fetches image data from the network.
    ///
    /// Validates the HTTP response before returning to ensure only successful
    /// responses proceed to decoding.
    ///
    /// - Parameters:
    ///   - url: The URL to fetch.
    ///   - ignoreCache: Whether to use the no-cache session.
    /// - Returns: The download result with data and response.
    /// - Throws: `InternalDownloadError` if the request fails or returns an error status.
    func fetchImageData(from url: URL, ignoreCache: Bool) async throws -> DownloadResult {
        let session = selectSession(ignoreCache: ignoreCache)
        let request = URLRequest(url: url)
        let (data, response) = try await session.data(for: request)

        let httpResponse = try ResponseValidator.validateIsHTTPResponse(response)
        try ResponseValidator.validateStatusCode(httpResponse)

        return DownloadResult(data: data, response: httpResponse)
    }

    /// Selects the appropriate URLSession based on cache settings.
    ///
    /// - Parameter ignoreCache: Whether to bypass the cache.
    /// - Returns: The appropriate URLSession.
    func selectSession(ignoreCache: Bool) -> URLSession {
        ignoreCache ? URLSession.imageNoCacheSession : URLSession.imageCacheSession
    }
}

// MARK: - DownloadRequest

/// Represents a unique download request for deduplication.
///
/// Two requests are considered equal if they have the same URL and thumbnail setting.
private struct DownloadRequest: Hashable, Sendable {
    /// The image URL to download.
    let url: URL

    /// Whether to decode as a thumbnail.
    let asThumbnail: Bool
}

// MARK: - DownloadOutcome

/// Result of a download operation, including the error if failed.
///
/// Used internally to return both success and failure cases with detailed information.
struct DownloadOutcome: Sendable {
    /// The downloaded and decoded image, or nil on failure.
    let image: PlatformImage?

    /// The error that occurred, or nil on success.
    let error: ImageLoadingError?

    /// Creates a successful outcome with the downloaded image.
    ///
    /// - Parameter image: The successfully downloaded and decoded image.
    /// - Returns: A success outcome.
    static func success(_ image: PlatformImage) -> DownloadOutcome {
        DownloadOutcome(image: image, error: nil)
    }

    /// Creates a failure outcome with the error.
    ///
    /// - Parameter error: The error that caused the download to fail.
    /// - Returns: A failure outcome.
    static func failure(_ error: ImageLoadingError) -> DownloadOutcome {
        DownloadOutcome(image: nil, error: error)
    }
}

// MARK: - ResponseValidator

/// Validates HTTP responses before processing.
///
/// Ensures that only successful responses (2xx status codes) proceed to decoding.
/// This prevents unnecessary decoding attempts for error responses like 404, 403, 500, etc.
private enum ResponseValidator {
    /// Validates that the response is an HTTP response.
    ///
    /// - Parameter response: The URL response to validate.
    /// - Returns: The response cast to HTTPURLResponse.
    /// - Throws: `InternalDownloadError.invalidResponse` if not an HTTP response.
    static func validateIsHTTPResponse(_ response: URLResponse) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw InternalDownloadError.invalidResponse
        }
        return httpResponse
    }

    /// Validates that the HTTP status code indicates success.
    ///
    /// Only 2xx status codes are considered successful. All other status codes
    /// will throw an error, preventing unnecessary decoding attempts.
    ///
    /// - Parameter response: The HTTP response to validate.
    /// - Throws: `InternalDownloadError.httpError` if status code is not 2xx.
    static func validateStatusCode(_ response: HTTPURLResponse) throws {
        guard isSuccessStatusCode(response.statusCode) else {
            throw InternalDownloadError.httpError(statusCode: response.statusCode)
        }
    }

    /// Checks if a status code indicates success.
    ///
    /// - Parameter statusCode: The HTTP status code to check.
    /// - Returns: True if the status code is in the 2xx range.
    private static func isSuccessStatusCode(_ statusCode: Int) -> Bool {
        (200 ..< 300).contains(statusCode)
    }
}

// MARK: - Background Decoding

extension ImageDownloader {
    /// Decodes image data without actor isolation to enable background execution.
    ///
    /// This function is intentionally nonisolated to allow the Swift runtime
    /// to execute it on a background thread, avoiding main thread blocking
    /// during CPU-intensive decoding operations.
    ///
    /// - Parameters:
    ///   - data: The raw image data to decode.
    ///   - asThumbnail: Whether to decode as a downscaled thumbnail.
    ///   - thumbnailMaxPixelSize: Maximum pixel size for thumbnail decoding.
    /// - Returns: The decoded platform image.
    /// - Throws: `InternalDownloadError` if decoding fails.
    nonisolated func decodeImageData(
        _ data: Data,
        asThumbnail: Bool,
        thumbnailMaxPixelSize: Int
    ) throws -> PlatformImage {
        try DataValidator.validateNotEmpty(data)
        let image = try ImageDecoderBridge.decode(
            data,
            asThumbnail: asThumbnail,
            thumbnailMaxPixelSize: thumbnailMaxPixelSize
        )
        try ImageValidator.validateDimensions(image)
        return image
    }
}

// MARK: - DataValidator

/// Validates raw image data before decoding.
private enum DataValidator {
    /// Validates that the data is not empty.
    ///
    /// - Parameter data: The data to validate.
    /// - Throws: `InternalDownloadError.emptyData` if data is empty.
    static func validateNotEmpty(_ data: Data) throws {
        guard !data.isEmpty else {
            throw InternalDownloadError.emptyData
        }
    }
}

// MARK: - ImageDecoderBridge

/// Bridges to the ImageDecoder for decoding operations.
private enum ImageDecoderBridge {
    /// Decodes image data using the ImageDecoder.
    ///
    /// - Parameters:
    ///   - data: The raw image data.
    ///   - asThumbnail: Whether to decode as a thumbnail.
    ///   - thumbnailMaxPixelSize: Maximum pixel size for thumbnail decoding.
    /// - Returns: The decoded platform image.
    /// - Throws: `InternalDownloadError.decodingFailed` if decoding fails.
    static func decode(
        _ data: Data,
        asThumbnail: Bool,
        thumbnailMaxPixelSize: Int
    ) throws -> PlatformImage {
        guard let decoded = ImageDecoder.decode(
            from: data,
            asThumbnail: asThumbnail,
            thumbnailMaxPixelSize: thumbnailMaxPixelSize
        ) else {
            throw InternalDownloadError.decodingFailed
        }
        return decoded
    }
}

// MARK: - ImageValidator

/// Validates decoded images.
private enum ImageValidator {
    /// Validates that the image has valid dimensions.
    ///
    /// Rejects images with dimensions 0x0 or 1x1, which typically indicate
    /// decoding failures or placeholder images.
    ///
    /// - Parameter image: The image to validate.
    /// - Throws: `InternalDownloadError.invalidImageDimensions` if dimensions are invalid.
    static func validateDimensions(_ image: PlatformImage) throws {
        guard let cgImage = image.cgImageRepresentation else {
            throw InternalDownloadError.invalidImageDimensions
        }
        guard hasValidDimensions(cgImage) else {
            throw InternalDownloadError.invalidImageDimensions
        }
    }

    /// Checks if a CGImage has valid dimensions.
    ///
    /// - Parameter cgImage: The image to check.
    /// - Returns: True if both width and height are greater than 1.
    private static func hasValidDimensions(_ cgImage: CGImage) -> Bool {
        cgImage.width > 1 && cgImage.height > 1
    }
}

// MARK: - Cache Operations

private extension ImageDownloader {
    /// Clears the disk cache for a URL.
    ///
    /// - Parameter url: The URL to clear from cache.
    func clearDiskCache(for url: URL) async {
        await DiskCache.shared.remove(for: url)
    }

    /// Stores a downloaded image in all cache layers.
    ///
    /// - Parameters:
    ///   - image: The decoded image to store.
    ///   - downloadResult: The download result containing raw data and response.
    ///   - url: The image URL.
    ///   - asThumbnail: Whether this is a thumbnail variant.
    func storeInAllCaches(
        image: PlatformImage,
        downloadResult: DownloadResult,
        url: URL,
        asThumbnail: Bool
    ) async {
        await storeToDiskCache(data: downloadResult.data, response: downloadResult.response, url: url)
        await storeToMemoryCache(image: image, url: url, asThumbnail: asThumbnail)
        await storeMetadata(from: downloadResult.response, url: url, asThumbnail: asThumbnail)
    }

    /// Stores image data in the disk cache.
    ///
    /// - Parameters:
    ///   - data: The raw image data.
    ///   - response: The HTTP response.
    ///   - url: The image URL.
    func storeToDiskCache(data: Data, response: URLResponse, url: URL) async {
        await DiskCache.shared.store(data: data, response: response, for: url)
    }

    /// Stores a decoded image in the memory cache.
    ///
    /// - Parameters:
    ///   - image: The decoded image.
    ///   - url: The image URL.
    ///   - asThumbnail: Whether this is a thumbnail variant.
    func storeToMemoryCache(image: PlatformImage, url: URL, asThumbnail: Bool) async {
        await MemoryCache.shared.store(image, for: url, thumb: asThumbnail)
    }

    /// Extracts and stores metadata from the HTTP response.
    ///
    /// - Parameters:
    ///   - response: The HTTP response containing cache headers.
    ///   - url: The image URL.
    ///   - asThumbnail: Whether this is a thumbnail variant.
    func storeMetadata(from response: HTTPURLResponse, url: URL, asThumbnail: Bool) async {
        let metadata = MetadataExtractor.extract(from: response)
        await MetadataStore.shared.store(metadata, for: url, thumb: asThumbnail)
    }
}

// MARK: - MetadataExtractor

/// Extracts cache metadata from HTTP responses.
private enum MetadataExtractor {
    /// Extracts metadata from an HTTP response.
    ///
    /// Captures ETag and Last-Modified headers for cache revalidation.
    ///
    /// - Parameter response: The HTTP response to extract from.
    /// - Returns: Extracted metadata with current timestamp.
    static func extract(from response: HTTPURLResponse) -> Metadata {
        Metadata(
            etag: response.value(forHTTPHeaderField: "ETag"),
            lastModified: response.value(forHTTPHeaderField: "Last-Modified"),
            cachedAt: Date()
        )
    }
}

// MARK: - Logging

private extension ImageDownloader {
    /// Logs the start of a download operation.
    ///
    /// - Parameters:
    ///   - url: The URL being downloaded.
    ///   - ignoreCache: Whether cache is being bypassed.
    func logDownloadStart(url: URL, ignoreCache: Bool) {
        #if DEBUG
        print("[ImageDownloader] Downloading: \(url.lastPathComponent), ignoreCache: \(ignoreCache)")
        #endif
    }

    /// Logs successful completion of a download.
    ///
    /// - Parameter url: The URL that was downloaded.
    func logDownloadComplete(url: URL) {
        #if DEBUG
        print("[ImageDownloader] Download complete: \(url.lastPathComponent)")
        #endif
    }

    /// Logs a download error.
    ///
    /// - Parameters:
    ///   - error: The error that occurred.
    ///   - url: The URL that failed.
    func logDownloadError(_ error: ImageLoadingError, url: URL) {
        #if DEBUG
        print("[ImageDownloader] Download failed for \(url.lastPathComponent): \(error.localizedDescription)")
        #endif
    }

    /// Logs when a request is deduplicated.
    ///
    /// - Parameter url: The URL being deduplicated.
    func logDeduplication(url: URL) {
        #if DEBUG
        print("[ImageDownloader] Deduplicating request for: \(url.lastPathComponent)")
        #endif
    }
}
