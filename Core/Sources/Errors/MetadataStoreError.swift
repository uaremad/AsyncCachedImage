//
//  AsyncCachedImage
//
//  Copyright © 2025 Jan-Hendrik Damerau.
//  https://github.com/uaremad/AsyncCachedImage
//
//  Licensed under the MIT License
//  Free to use without restrictions. See LICENSE file for full terms.
//

// MARK: - MetadataStoreError

/// Errors that can occur during metadata operations.
enum MetadataStoreError: Error, Equatable, Sendable {
    /// Failed to create the metadata storage directory.
    case directoryCreationFailed

    /// Failed to encode metadata to JSON.
    case encodingFailed

    /// Failed to write metadata to disk.
    case writeFailed

    /// Failed to decode metadata from JSON.
    case decodingFailed
}
