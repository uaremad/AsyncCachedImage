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

// MARK: - MetadataStore

/// Thread-safe persistent storage for image cache metadata.
///
/// Stores metadata as JSON files in the app's caches directory.
/// Uses actor isolation for Swift 6 concurrency safety.
///
/// Metadata is stored separately from image data to enable:
/// - Fast metadata lookups without loading image data
/// - Independent management of metadata and cached images
/// - Efficient cache revalidation checks
///
/// ## Storage Format
///
/// Each metadata entry is stored as a JSON file with a base64-encoded filename
/// derived from the image URL. Thumbnail variants use a `#thumb` suffix.
public actor MetadataStore {
    /// The shared metadata store instance.
    public static let shared = MetadataStore()

    /// The name of the metadata storage directory.
    private let metadataDirectoryName = "Metadata"

    private init() {
        Self.createMetadataDirectoryIfNeeded(directoryName: metadataDirectoryName)
    }

    // MARK: - Public API

    /// Retrieves metadata for a cached image.
    ///
    /// - Parameters:
    ///   - url: The image URL.
    ///   - thumb: Whether to retrieve metadata for the thumbnail variant.
    /// - Returns: The stored metadata, or nil if not found.
    public func metadata(for url: URL, thumb: Bool) -> Metadata? {
        let fileURL = metadataFileURL(for: url, thumb: thumb)
        return loadMetadata(from: fileURL)
    }

    /// Stores metadata for a cached image.
    ///
    /// Overwrites any existing metadata for the same URL and variant.
    ///
    /// - Parameters:
    ///   - metadata: The metadata to store.
    ///   - url: The image URL.
    ///   - thumb: Whether this is metadata for a thumbnail variant.
    public func store(_ metadata: Metadata, for url: URL, thumb: Bool) {
        let fileURL = metadataFileURL(for: url, thumb: thumb)
        saveMetadata(metadata, to: fileURL)
    }

    /// Removes metadata for a cached image.
    ///
    /// - Parameters:
    ///   - url: The image URL.
    ///   - thumb: Whether to remove metadata for the thumbnail variant.
    public func remove(for url: URL, thumb: Bool) {
        let fileURL = metadataFileURL(for: url, thumb: thumb)
        deleteFile(at: fileURL)
    }

    /// Returns the count of all stored metadata entries.
    ///
    /// - Returns: The number of metadata files in storage.
    public func entryCount() -> Int {
        countJSONFiles(in: metadataDirectory)
    }

    /// Removes all stored metadata.
    ///
    /// Deletes all JSON files in the metadata directory.
    public func removeAll() {
        deleteAllJSONFiles(in: metadataDirectory)
    }

    /// Returns all stored cache keys with their metadata.
    ///
    /// Used by the cache browser to display all cached entries.
    ///
    /// - Returns: Array of tuples containing the cache key and its metadata.
    public func allEntries() -> [(key: String, metadata: Metadata)] {
        loadAllEntries(from: metadataDirectory)
    }

    // MARK: - Directory Management

    /// The URL of the metadata storage directory.
    private var metadataDirectory: URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent(metadataDirectoryName)
    }

    /// Creates the metadata directory if it doesn't exist.
    ///
    /// Called during initialization to ensure the storage directory is available.
    ///
    /// - Parameter directoryName: The name of the directory to create.
    private static func createMetadataDirectoryIfNeeded(directoryName: String) {
        let fileManager = FileManager.default
        let base = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? fileManager.temporaryDirectory
        let directory = base.appendingPathComponent(directoryName)

        try? fileManager.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
    }

    // MARK: - Key Generation

    /// Generates the file URL for storing metadata.
    ///
    /// - Parameters:
    ///   - imageURL: The image URL to generate a file path for.
    ///   - thumb: Whether this is for a thumbnail variant.
    /// - Returns: The file URL where metadata should be stored.
    private func metadataFileURL(for imageURL: URL, thumb: Bool) -> URL {
        let key = cacheKey(for: imageURL, thumb: thumb)
        let filename = sanitizedFilename(for: key)
        return metadataDirectory.appendingPathComponent("\(filename).json")
    }

    /// Creates a cache key from a URL and variant flag.
    ///
    /// - Parameters:
    ///   - url: The image URL.
    ///   - thumb: Whether this is a thumbnail variant.
    /// - Returns: A unique cache key string.
    private func cacheKey(for url: URL, thumb: Bool) -> String {
        url.absoluteString + (thumb ? "#thumb" : "")
    }

    /// Converts a cache key to a valid filename.
    ///
    /// Uses base64 encoding to handle special characters in URLs.
    /// Replaces forward slashes with underscores for filesystem compatibility.
    ///
    /// - Parameter key: The cache key to convert.
    /// - Returns: A sanitized filename suitable for the filesystem.
    private func sanitizedFilename(for key: String) -> String {
        let base64 = key.data(using: .utf8)?.base64EncodedString() ?? UUID().uuidString
        return base64.replacingOccurrences(of: "/", with: "_")
    }

    // MARK: - File Operations

    /// Loads metadata from a file.
    ///
    /// - Parameter fileURL: The URL of the metadata file.
    /// - Returns: The decoded metadata, or nil if loading fails.
    private func loadMetadata(from fileURL: URL) -> Metadata? {
        guard let data = try? Data(contentsOf: fileURL) else {
            return nil
        }
        return try? JSONDecoder().decode(Metadata.self, from: data)
    }

    /// Saves metadata to a file.
    ///
    /// - Parameters:
    ///   - metadata: The metadata to save.
    ///   - fileURL: The URL where the metadata should be written.
    private func saveMetadata(_ metadata: Metadata, to fileURL: URL) {
        guard let data = try? JSONEncoder().encode(metadata) else {
            Logging.log?.error("[MetadataStore] Failed to encode metadata")
            return
        }
        try? data.write(to: fileURL)
    }

    /// Deletes a file at the specified URL.
    ///
    /// - Parameter fileURL: The URL of the file to delete.
    private func deleteFile(at fileURL: URL) {
        try? FileManager.default.removeItem(at: fileURL)
    }

    // MARK: - Bulk Operations

    /// Counts JSON files in a directory.
    ///
    /// - Parameter directory: The directory to scan.
    /// - Returns: The number of .json files found.
    private func countJSONFiles(in directory: URL) -> Int {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            return 0
        }
        return files.count { $0.pathExtension == "json" }
    }

    /// Deletes all JSON files in a directory.
    ///
    /// - Parameter directory: The directory to clean.
    private func deleteAllJSONFiles(in directory: URL) {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            return
        }

        for file in files where file.pathExtension == "json" {
            try? FileManager.default.removeItem(at: file)
        }
    }

    /// Loads all metadata entries from a directory.
    ///
    /// - Parameter directory: The directory to scan.
    /// - Returns: An array of cache keys and their associated metadata.
    private func loadAllEntries(from directory: URL) -> [(key: String, metadata: Metadata)] {
        guard let files = try? FileManager.default.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil
        ) else {
            return []
        }

        var entries: [(key: String, metadata: Metadata)] = []

        for file in files where file.pathExtension == "json" {
            guard let metadata = loadMetadata(from: file) else {
                continue
            }

            let filename = file.deletingPathExtension().lastPathComponent
            guard let key = decodeKey(from: filename) else {
                continue
            }

            entries.append((key: key, metadata: metadata))
        }

        return entries
    }

    /// Decodes a cache key from a sanitized filename.
    ///
    /// Reverses the base64 encoding applied by `sanitizedFilename(for:)`.
    ///
    /// - Parameter filename: The sanitized filename to decode.
    /// - Returns: The original cache key, or nil if decoding fails.
    private func decodeKey(from filename: String) -> String? {
        let sanitized = filename.replacingOccurrences(of: "_", with: "/")
        guard let keyData = Data(base64Encoded: sanitized),
              let key = String(data: keyData, encoding: .utf8)
        else {
            return nil
        }
        return key
    }
}
