//
//  AsyncCachedImage
//
//  Copyright © 2025 Jan-Hendrik Damerau.
//  https://github.com/uaremad/AsyncCachedImage
//
//  Licensed under the MIT License
//  Free to use without restrictions. See LICENSE file for full terms.
//

import XCTest
@testable import AsyncCachedImage

#if os(iOS)
import UIKit
#elseif os(macOS)
import AppKit
#endif

// MARK: - DownloadOutcomeTests

/// Tests for the DownloadOutcome struct which encapsulates download results.
///
/// DownloadOutcome provides:
/// - `.success(image)`: Download succeeded, image is available
/// - `.failure(error)`: Download failed, error describes the reason
///
/// This allows callers to access both the image and error information.
final class DownloadOutcomeTests: XCTestCase {
    // MARK: - Test Data

    private var testURL: URL {
        guard let url = URL(string: "https://cdn.manasuite.com/card_sets/artwork/sld_300_landscape.jpg") else {
            preconditionFailure("Invalid test URL")
        }
        return url
    }

    private var testImage: PlatformImage {
        createTestImage(width: 100, height: 100)
    }

    // MARK: - Success Outcome

    /// Verifies success outcome contains the image.
    ///
    /// Expected: image property is not nil.
    func testSuccessOutcomeHasImage() {
        let image = testImage
        let outcome = DownloadOutcome.success(image)

        XCTAssertNotNil(outcome.image)
    }

    /// Verifies success outcome has no error.
    ///
    /// Expected: error property is nil.
    func testSuccessOutcomeHasNoError() {
        let image = testImage
        let outcome = DownloadOutcome.success(image)

        XCTAssertNil(outcome.error)
    }

    // MARK: - Failure Outcome

    /// Verifies failure outcome has no image.
    ///
    /// Expected: image property is nil.
    func testFailureOutcomeHasNoImage() {
        let error = ImageLoadingError.missingURL
        let outcome = DownloadOutcome.failure(error)

        XCTAssertNil(outcome.image)
    }

    /// Verifies failure outcome contains the error.
    ///
    /// Expected: error property is not nil.
    func testFailureOutcomeHasError() {
        let error = ImageLoadingError.missingURL
        let outcome = DownloadOutcome.failure(error)

        XCTAssertNotNil(outcome.error)
    }

    /// Verifies failure outcome preserves error details.
    ///
    /// Error type and associated values should be preserved.
    ///
    /// Expected: httpError with status code 404.
    func testFailureOutcomePreservesErrorType() {
        let error = ImageLoadingError.httpError(url: testURL, statusCode: 404)
        let outcome = DownloadOutcome.failure(error)

        if case let .httpError(_, statusCode) = outcome.error {
            XCTAssertEqual(statusCode, 404)
        } else {
            XCTFail("Expected httpError")
        }
    }

    // MARK: - Protocol Conformance

    /// Verifies DownloadOutcome conforms to Sendable protocol.
    ///
    /// Sendable conformance is required for Swift 6 concurrency safety.
    ///
    /// Expected: Can be assigned to Sendable type.
    func testConformsToSendableProtocol() {
        let image = testImage
        let outcome: Sendable = DownloadOutcome.success(image)
        XCTAssertNotNil(outcome)
    }

    // MARK: - Helper Methods

    private func createTestImage(width: Int, height: Int) -> PlatformImage {
        #if os(iOS)
        return createUIImage(width: width, height: height)
        #elseif os(macOS)
        return createNSImage(width: width, height: height)
        #endif
    }

    #if os(iOS)
    private func createUIImage(width: Int, height: Int) -> UIImage {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
    #endif

    #if os(macOS)
    private func createNSImage(width: Int, height: Int) -> NSImage {
        let size = NSSize(width: width, height: height)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()
        return image
    }
    #endif
}

// MARK: - ImageDownloaderTests

/// Tests for the ImageDownloader actor which handles image downloading.
///
/// ImageDownloader responsibilities:
/// - Download images from URLs with proper error handling
/// - Deduplicate concurrent requests for the same URL
/// - Decode images with optional thumbnail downscaling
/// - Store results in memory cache, disk cache, and metadata store
final class ImageDownloaderTests: XCTestCase {
    // MARK: - Test Data

    private var testURL: URL {
        guard let url = URL(string: "https://cdn.manasuite.com/card_sets/artwork/sld_300_landscape.jpg") else {
            preconditionFailure("Invalid test URL")
        }
        return url
    }

    private var invalidURL: URL {
        guard let url = URL(string: "https://invalid.invalid.invalid/image.jpg") else {
            preconditionFailure("Invalid URL")
        }
        return url
    }

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        await DiskCache.shared.removeAll()
        await MemoryCache.shared.clearAll()
        await MetadataStore.shared.removeAll()
    }

    override func tearDown() async throws {
        await DiskCache.shared.removeAll()
        await MemoryCache.shared.clearAll()
        await MetadataStore.shared.removeAll()
        try await super.tearDown()
    }

    // MARK: - Shared Instance

    /// Verifies shared singleton instance exists.
    ///
    /// Expected: ImageDownloader.shared is not nil.
    func testSharedInstanceExists() async {
        let downloader = ImageDownloader.shared

        XCTAssertNotNil(downloader)
    }

    // MARK: - Download Success (Integration Test)

    /// Tests downloading a real image from the CDN.
    ///
    /// This is an integration test that requires internet connectivity.
    /// It verifies the complete download pipeline works end-to-end.
    ///
    /// Expected: Returns a decoded image.
    func testDownloadValidImageReturnsImage() async {
        let result = await ImageDownloader.shared.download(
            from: testURL,
            asThumbnail: false,
            ignoreCache: true
        )

        XCTAssertNotNil(result)
    }

    /// Tests downloading as thumbnail.
    ///
    /// Thumbnail mode uses ImageIO to downscale during decode,
    /// reducing memory usage for list views.
    ///
    /// Expected: Returns a decoded thumbnail image.
    func testDownloadValidImageAsThumbnail() async {
        let result = await ImageDownloader.shared.download(
            from: testURL,
            asThumbnail: true,
            ignoreCache: true
        )

        XCTAssertNotNil(result)
    }

    // MARK: - Download Failure

    /// Tests download from invalid URL returns nil.
    ///
    /// DNS lookup failure should result in nil, not a crash.
    ///
    /// Expected: Returns nil.
    func testDownloadFromInvalidURLReturnsNil() async {
        let result = await ImageDownloader.shared.download(
            from: invalidURL,
            asThumbnail: false,
            ignoreCache: true
        )

        XCTAssertNil(result)
    }

    /// Tests downloadWithResult returns error for invalid URL.
    ///
    /// The error should contain details about the failure.
    ///
    /// Expected: image is nil, error is not nil.
    func testDownloadWithResultFromInvalidURLReturnsError() async {
        let outcome = await ImageDownloader.shared.downloadWithResult(
            from: invalidURL,
            asThumbnail: false,
            ignoreCache: true
        )

        XCTAssertNil(outcome.image)
        XCTAssertNotNil(outcome.error)
    }

    // MARK: - Download With Result

    /// Tests downloadWithResult returns an outcome.
    ///
    /// Expected: Outcome is not nil.
    func testDownloadWithResultReturnsOutcome() async {
        let outcome = await ImageDownloader.shared.downloadWithResult(
            from: testURL,
            asThumbnail: false,
            ignoreCache: true
        )

        XCTAssertNotNil(outcome)
    }

    /// Tests successful downloadWithResult has image and no error.
    ///
    /// Expected: image is not nil, error is nil.
    func testDownloadWithResultSuccessHasImage() async {
        let outcome = await ImageDownloader.shared.downloadWithResult(
            from: testURL,
            asThumbnail: false,
            ignoreCache: true
        )

        XCTAssertNotNil(outcome.image)
        XCTAssertNil(outcome.error)
    }

    // MARK: - Cache Integration

    /// Tests download stores image in memory cache.
    ///
    /// After download, the image should be available for instant retrieval.
    ///
    /// Expected: MemoryCache contains the image.
    func testDownloadStoresInMemoryCache() async {
        _ = await ImageDownloader.shared.download(
            from: testURL,
            asThumbnail: false,
            ignoreCache: true
        )

        let cached = await MemoryCache.shared.image(for: testURL, thumb: false)

        XCTAssertNotNil(cached)
    }

    /// Tests download stores metadata.
    ///
    /// ETag and Last-Modified headers should be persisted for revalidation.
    ///
    /// Expected: MetadataStore contains metadata for the URL.
    func testDownloadStoresMetadata() async {
        _ = await ImageDownloader.shared.download(
            from: testURL,
            asThumbnail: false,
            ignoreCache: true
        )

        let metadata = await MetadataStore.shared.metadata(for: testURL, thumb: false)

        XCTAssertNotNil(metadata)
    }

    // MARK: - Ignore Cache Option

    /// Tests ignoreCache bypasses disk cache.
    ///
    /// Even with cached data, ignoreCache forces a fresh download.
    /// Both downloads should succeed.
    ///
    /// Expected: Both results are not nil.
    func testIgnoreCacheBypassesDiskCache() async {
        let result1 = await ImageDownloader.shared.download(
            from: testURL,
            asThumbnail: false,
            ignoreCache: false
        )

        let result2 = await ImageDownloader.shared.download(
            from: testURL,
            asThumbnail: false,
            ignoreCache: true
        )

        XCTAssertNotNil(result1)
        XCTAssertNotNil(result2)
    }

    // MARK: - Decode Image Data

    /// Tests decoding valid PNG data.
    ///
    /// The decode function runs on a background thread to avoid
    /// blocking the main thread during CPU-intensive decoding.
    ///
    /// Expected: Returns a decoded image.
    func testDecodeImageDataWithValidPNG() async throws {
        let pngData = createValidPNGData(width: 100, height: 100)

        let image = try ImageDownloader.shared.decodeImageData(pngData, asThumbnail: false)

        XCTAssertNotNil(image)
    }

    /// Tests decoding empty data throws error.
    ///
    /// Expected: Throws InternalDownloadError.
    func testDecodeImageDataWithEmptyDataThrows() async {
        let emptyData = Data()

        XCTAssertThrowsError(try ImageDownloader.shared.decodeImageData(emptyData, asThumbnail: false)) { error in
            XCTAssertTrue(error is InternalDownloadError)
        }
    }

    /// Tests decoding invalid data throws error.
    ///
    /// Random bytes cannot be decoded as an image.
    ///
    /// Expected: Throws InternalDownloadError.
    func testDecodeImageDataWithInvalidDataThrows() async {
        let invalidData = Data([0x00, 0x01, 0x02])

        XCTAssertThrowsError(try ImageDownloader.shared.decodeImageData(invalidData, asThumbnail: false)) { error in
            XCTAssertTrue(error is InternalDownloadError)
        }
    }

    // MARK: - Concurrent Downloads

    /// Tests concurrent downloads don't cause crashes.
    ///
    /// Actor isolation should handle parallel downloads safely.
    /// Request deduplication may reduce actual network requests.
    ///
    /// Expected: All downloads complete without crash, returns 5 results.
    func testConcurrentDownloadsDoNotCrash() async {
        let urls = (0 ..< 5).compactMap { index in
            URL(string: "https://cdn.manasuite.com/card_sets/artwork/sld_\(300 + index)_landscape.jpg")
        }

        await withTaskGroup(of: PlatformImage?.self) { group in
            for url in urls {
                group.addTask {
                    await ImageDownloader.shared.download(
                        from: url,
                        asThumbnail: false,
                        ignoreCache: true
                    )
                }
            }

            var results: [PlatformImage?] = []
            for await result in group {
                results.append(result)
            }

            XCTAssertEqual(results.count, 5)
        }
    }

    // MARK: - Helper Methods

    private func createValidPNGData(width: Int, height: Int) -> Data {
        #if os(iOS)
        return createPNGDataiOS(width: width, height: height)
        #elseif os(macOS)
        return createPNGDatamacOS(width: width, height: height)
        #endif
    }

    #if os(iOS)
    private func createPNGDataiOS(width: Int, height: Int) -> Data {
        let size = CGSize(width: width, height: height)
        let renderer = UIGraphicsImageRenderer(size: size)
        let image = renderer.image { context in
            UIColor.blue.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
        return image.pngData() ?? Data()
    }
    #endif

    #if os(macOS)
    private func createPNGDatamacOS(width: Int, height: Int) -> Data {
        let size = NSSize(width: width, height: height)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.blue.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()

        guard let tiffData = image.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiffData),
              let pngData = bitmap.representation(using: .png, properties: [:])
        else {
            return Data()
        }
        return pngData
    }
    #endif
}
