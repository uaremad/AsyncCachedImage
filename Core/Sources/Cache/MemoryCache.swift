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

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - MemoryCache

/// Thread-safe in-memory cache for decoded images using actor isolation.
///
/// Provides fast access to recently used images without disk I/O.
/// Uses Swift 6 actor isolation for coordinated async operations.
///
/// The memory cache stores fully decoded `PlatformImage` instances for instant display.
/// It uses NSCache internally which automatically evicts entries under memory pressure.
///
/// ## Synchronous Access
///
/// For synchronous cache lookups (e.g., during view initialization),
/// use `MemoryCacheStorage.shared` directly. This prevents view flicker
/// when parent views re-render.
///
/// - Note: Thumbnail and full-size variants are stored separately using different cache keys.
actor MemoryCache {
    /// The shared memory cache instance.
    static let shared = MemoryCache()

    /// The underlying storage backend.
    private let storage = MemoryCacheStorage.shared

    private init() {}

    // MARK: - Public API

    /// Retrieves a cached image.
    ///
    /// - Parameters:
    ///   - url: The image URL used as the cache key.
    ///   - thumb: Whether to retrieve the thumbnail variant.
    /// - Returns: The cached image, or nil if not found.
    func image(for url: URL, thumb: Bool) -> PlatformImage? {
        storage.image(for: url, thumb: thumb)
    }

    /// Stores an image in the cache.
    ///
    /// The cost is calculated based on the image's uncompressed bitmap size
    /// to accurately reflect memory usage.
    ///
    /// - Parameters:
    ///   - image: The decoded image to store.
    ///   - url: The image URL used as the cache key.
    ///   - thumb: Whether this is a thumbnail variant.
    func store(_ image: PlatformImage, for url: URL, thumb: Bool) {
        let cost = MemoryCostCalculator.estimateCost(for: image)
        storage.store(image, for: url, thumb: thumb, cost: cost)
    }

    /// Removes an image from the cache.
    ///
    /// - Parameters:
    ///   - url: The image URL used as the cache key.
    ///   - thumb: Whether to remove the thumbnail variant.
    func remove(for url: URL, thumb: Bool) {
        storage.remove(for: url, thumb: thumb)
    }

    /// Removes all cached images.
    ///
    /// Clears both full-size and thumbnail variants.
    func clearAll() {
        storage.clearAll()
    }
}

// MARK: - MemoryCostCalculator

/// Calculates memory cost for platform images.
///
/// Estimates the actual memory footprint of decoded images for accurate
/// cache cost tracking.
///
/// ## Performance Optimization
///
/// Previous implementation used PNG/TIFF encoding to determine image size,
/// which was extremely CPU-intensive (100-500ms for 4K images).
///
/// Current implementation calculates the uncompressed bitmap size directly
/// from image dimensions, which is O(1) and takes microseconds.
///
/// The uncompressed size is more accurate for memory cost estimation because
/// decoded images are stored as uncompressed bitmaps in memory.
enum MemoryCostCalculator {
    /// Bytes per pixel for standard RGBA images.
    ///
    /// Most decoded images use 4 bytes per pixel:
    /// - Red: 1 byte
    /// - Green: 1 byte
    /// - Blue: 1 byte
    /// - Alpha: 1 byte
    private static let bytesPerPixel = 4

    /// Estimates the memory cost of an image in bytes.
    ///
    /// Calculates the uncompressed bitmap size based on pixel dimensions.
    /// This represents the actual memory footprint of the decoded image.
    ///
    /// - Parameter image: The image to calculate cost for.
    /// - Returns: Estimated memory size in bytes (width * height * 4).
    static func estimateCost(for image: PlatformImage) -> Int {
        let dimensions = extractDimensions(from: image)
        return calculateBitmapSize(width: dimensions.width, height: dimensions.height)
    }

    // MARK: - Dimension Extraction

    /// Extracts pixel dimensions from a platform image.
    ///
    /// - Parameter image: The image to measure.
    /// - Returns: A tuple containing width and height in pixels.
    private static func extractDimensions(from image: PlatformImage) -> (width: Int, height: Int) {
        #if os(iOS)
        return extractDimensionsiOS(from: image)
        #elseif os(macOS)
        return extractDimensionsmacOS(from: image)
        #endif
    }

    #if os(iOS)
    /// Extracts dimensions from a UIImage.
    ///
    /// - Parameter image: The UIImage to measure.
    /// - Returns: Pixel dimensions from the underlying CGImage.
    private static func extractDimensionsiOS(from image: UIImage) -> (width: Int, height: Int) {
        guard let cgImage = image.cgImage else {
            return (0, 0)
        }
        return (cgImage.width, cgImage.height)
    }
    #endif

    #if os(macOS)
    /// Extracts dimensions from an NSImage.
    ///
    /// - Parameter image: The NSImage to measure.
    /// - Returns: Pixel dimensions from the underlying CGImage representation.
    private static func extractDimensionsmacOS(from image: NSImage) -> (width: Int, height: Int) {
        guard let cgImage = image.cgImageRepresentation else {
            return (0, 0)
        }
        return (cgImage.width, cgImage.height)
    }
    #endif

    // MARK: - Size Calculation

    /// Calculates uncompressed bitmap size from dimensions.
    ///
    /// - Parameters:
    ///   - width: Image width in pixels.
    ///   - height: Image height in pixels.
    /// - Returns: Memory size in bytes (width * height * bytesPerPixel).
    private static func calculateBitmapSize(width: Int, height: Int) -> Int {
        width * height * bytesPerPixel
    }
}
