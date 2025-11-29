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
import ImageIO

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - ImageDecoder

/// Decodes image data into platform-specific images.
///
/// Supports full-size and thumbnail decoding with automatic validation.
/// Uses ImageIO for efficient thumbnail generation with downscaling during decode.
///
/// ## Thumbnail Decoding
///
/// When `asThumbnail: true`, the decoder uses `CGImageSourceCreateThumbnailAtIndex`
/// which downscales the image during the decode process. This is more memory-efficient
/// than decoding full-size and then resizing.
enum ImageDecoder {
    // MARK: - Public API

    /// Decodes image data into a platform image.
    ///
    /// - Parameters:
    ///   - data: The raw image data (JPEG, PNG, HEIC, etc.).
    ///   - asThumbnail: Whether to decode as a downscaled thumbnail.
    /// - Returns: The decoded platform image, or nil on failure.
    static func decode(from data: Data, asThumbnail: Bool) -> PlatformImage? {
        guard !data.isEmpty else { return nil }

        if asThumbnail {
            return decodeThumbnail(from: data)
        } else {
            return decodeFullSize(from: data)
        }
    }

    // MARK: - Thumbnail Decoding

    /// Decodes data as a downscaled thumbnail.
    ///
    /// Uses ImageIO to efficiently create a thumbnail during decode,
    /// avoiding the memory overhead of decoding the full image first.
    ///
    /// - Parameter data: The raw image data.
    /// - Returns: A downscaled platform image, or nil on failure.
    private static func decodeThumbnail(from data: Data) -> PlatformImage? {
        guard let source = createImageSource(from: data) else {
            return nil
        }
        guard let cgImage = createThumbnail(from: source) else {
            return nil
        }
        guard isValidDimensions(cgImage) else {
            return nil
        }
        return createPlatformImage(from: cgImage)
    }

    /// Creates an image source from raw data.
    ///
    /// - Parameter data: The raw image data.
    /// - Returns: A CGImageSource, or nil if the data is not valid image data.
    private static func createImageSource(from data: Data) -> CGImageSource? {
        CGImageSourceCreateWithData(data as CFData, nil)
    }

    /// Creates a thumbnail from an image source.
    ///
    /// - Parameter source: The image source to create a thumbnail from.
    /// - Returns: A downscaled CGImage, or nil on failure.
    private static func createThumbnail(from source: CGImageSource) -> CGImage? {
        CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions)
    }

    /// Options for thumbnail creation.
    ///
    /// Configures ImageIO to:
    /// - Always create a thumbnail (even if one isn't embedded)
    /// - Limit the maximum size to `thumbnailMaxSize` pixels
    /// - Apply EXIF orientation transforms
    private static var thumbnailOptions: CFDictionary {
        [
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            kCGImageSourceThumbnailMaxPixelSize: Constants.thumbnailMaxSize,
            kCGImageSourceCreateThumbnailWithTransform: true
        ] as CFDictionary
    }

    // MARK: - Full Size Decoding

    /// Decodes data at full resolution.
    ///
    /// - Parameter data: The raw image data.
    /// - Returns: A full-size platform image, or nil on failure.
    private static func decodeFullSize(from data: Data) -> PlatformImage? {
        #if os(iOS)
        return decodeFullSizeiOS(from: data)
        #elseif os(macOS)
        return decodeFullSizemacOS(from: data)
        #endif
    }

    #if os(iOS)
    /// Decodes full-size image data on iOS.
    ///
    /// - Parameter data: The raw image data.
    /// - Returns: A UIImage, or nil on failure.
    private static func decodeFullSizeiOS(from data: Data) -> UIImage? {
        guard let image = UIImage(data: data) else {
            return nil
        }
        guard let cgImage = image.cgImage else {
            return nil
        }
        guard isValidDimensions(cgImage) else {
            return nil
        }
        return image
    }
    #endif

    #if os(macOS)
    /// Decodes full-size image data on macOS.
    ///
    /// - Parameter data: The raw image data.
    /// - Returns: An NSImage, or nil on failure.
    private static func decodeFullSizemacOS(from data: Data) -> NSImage? {
        guard let image = NSImage(data: data) else {
            return nil
        }
        guard let cgImage = image.cgImageRepresentation else {
            return nil
        }
        guard isValidDimensions(cgImage) else {
            return nil
        }
        return image
    }
    #endif

    // MARK: - Platform Image Creation

    /// Creates a platform image from a CGImage.
    ///
    /// - Parameter cgImage: The decoded CGImage.
    /// - Returns: A platform-specific image (UIImage or NSImage).
    private static func createPlatformImage(from cgImage: CGImage) -> PlatformImage? {
        #if os(iOS)
        return UIImage(cgImage: cgImage)
        #elseif os(macOS)
        return createNSImage(from: cgImage)
        #endif
    }

    #if os(macOS)
    /// Creates an NSImage from a CGImage.
    ///
    /// - Parameter cgImage: The decoded CGImage.
    /// - Returns: An NSImage with the CGImage as its representation.
    private static func createNSImage(from cgImage: CGImage) -> NSImage {
        let representation = NSBitmapImageRep(cgImage: cgImage)
        let nsImage = NSImage(size: representation.size)
        nsImage.addRepresentation(representation)
        return nsImage
    }
    #endif

    // MARK: - Validation

    /// Validates that a CGImage has valid dimensions.
    ///
    /// Rejects images that are 0x0 or 1x1 pixels, which typically indicate
    /// decoding failures or placeholder images.
    ///
    /// - Parameter cgImage: The image to validate.
    /// - Returns: True if the image has valid dimensions.
    private static func isValidDimensions(_ cgImage: CGImage) -> Bool {
        cgImage.width > Constants.minimumDimension && cgImage.height > Constants.minimumDimension
    }
}

// MARK: - Constants

private extension ImageDecoder {
    /// Configuration constants for image decoding.
    enum Constants {
        /// Maximum pixel size for thumbnail generation.
        ///
        /// The thumbnail will be scaled to fit within this dimension on its longest edge.
        static let thumbnailMaxSize = 400

        /// Minimum valid dimension for decoded images.
        ///
        /// Images with width or height equal to or less than this value are rejected.
        static let minimumDimension = 1
    }
}

// MARK: - CGImage Representation Extensions

#if os(iOS)
extension UIImage {
    /// Returns the underlying CGImage representation.
    ///
    /// Provides a unified API across platforms for accessing the CGImage.
    var cgImageRepresentation: CGImage? { cgImage }
}
#endif

#if os(macOS)
extension NSImage {
    /// Returns a CGImage representation of this image.
    ///
    /// Creates a CGImage from the NSImage using the image's natural size.
    ///
    /// - Returns: A CGImage representation, or nil if conversion fails.
    var cgImageRepresentation: CGImage? {
        var proposedRect = CGRect(origin: .zero, size: size)
        return cgImage(forProposedRect: &proposedRect, context: nil, hints: nil)
    }
}
#endif
