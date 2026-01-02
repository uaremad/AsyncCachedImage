//
//  AsyncCachedImage
//
//  Copyright © 2026 Jan-Hendrik Damerau.
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

// MARK: - ImageDecoderTests

final class ImageDecoderTests: XCTestCase {
    // MARK: - Empty Data

    func testDecodeEmptyDataReturnsNil() {
        let emptyData = Data()

        let result = ImageDecoder.decode(from: emptyData, asThumbnail: false)

        XCTAssertNil(result)
    }

    func testDecodeThumbnailFromEmptyDataReturnsNil() {
        let emptyData = Data()

        let result = ImageDecoder.decode(from: emptyData, asThumbnail: true)

        XCTAssertNil(result)
    }

    // MARK: - Invalid Data

    func testDecodeInvalidDataReturnsNil() {
        let invalidData = Data([0x00, 0x01, 0x02, 0x03])

        let result = ImageDecoder.decode(from: invalidData, asThumbnail: false)

        XCTAssertNil(result)
    }

    func testDecodeThumbnailFromInvalidDataReturnsNil() {
        let invalidData = Data([0x00, 0x01, 0x02, 0x03])

        let result = ImageDecoder.decode(from: invalidData, asThumbnail: true)

        XCTAssertNil(result)
    }

    func testDecodeTextDataReturnsNil() {
        let textData = Data("This is not an image".utf8)

        let result = ImageDecoder.decode(from: textData, asThumbnail: false)

        XCTAssertNil(result)
    }

    func testDecodeHTMLDataReturnsNil() {
        let htmlData = Data("<html><body>404 Not Found</body></html>".utf8)

        let result = ImageDecoder.decode(from: htmlData, asThumbnail: false)

        XCTAssertNil(result)
    }

    // MARK: - Valid PNG Data

    func testDecodeValidPNGData() {
        let pngData = createValidPNGData(width: 100, height: 100)

        let result = ImageDecoder.decode(from: pngData, asThumbnail: false)

        XCTAssertNotNil(result)
    }

    func testDecodeThumbnailFromValidPNGData() {
        let pngData = createValidPNGData(width: 100, height: 100)

        let result = ImageDecoder.decode(from: pngData, asThumbnail: true)

        XCTAssertNotNil(result)
    }

    // MARK: - Image Dimensions

    func testDecodePreservesOriginalDimensions() {
        let pngData = createValidPNGData(width: 200, height: 150)

        let result = ImageDecoder.decode(from: pngData, asThumbnail: false)

        XCTAssertNotNil(result)
        #if os(iOS)
        XCTAssertEqual(result?.cgImage?.width, 200)
        XCTAssertEqual(result?.cgImage?.height, 150)
        #elseif os(macOS)
        XCTAssertEqual(result?.cgImageRepresentation?.width, 200)
        XCTAssertEqual(result?.cgImageRepresentation?.height, 150)
        #endif
    }

    func testDecodeThumbnailDownscalesLargeImage() {
        let pngData = createValidPNGData(width: 1000, height: 800)

        let result = ImageDecoder.decode(from: pngData, asThumbnail: true)

        XCTAssertNotNil(result)
        #if os(iOS)
        let width = result?.cgImage?.width ?? 0
        let height = result?.cgImage?.height ?? 0
        #elseif os(macOS)
        let width = result?.cgImageRepresentation?.width ?? 0
        let height = result?.cgImageRepresentation?.height ?? 0
        #endif

        XCTAssertLessThanOrEqual(width, 400)
        XCTAssertLessThanOrEqual(height, 400)
    }

    func testDecodeThumbnailMaintainsAspectRatio() {
        let pngData = createValidPNGData(width: 1000, height: 500)

        let result = ImageDecoder.decode(from: pngData, asThumbnail: true)

        XCTAssertNotNil(result)
        #if os(iOS)
        let width = result?.cgImage?.width ?? 0
        let height = result?.cgImage?.height ?? 0
        #elseif os(macOS)
        let width = result?.cgImageRepresentation?.width ?? 0
        let height = result?.cgImageRepresentation?.height ?? 0
        #endif

        guard width > 0, height > 0 else {
            XCTFail("Invalid dimensions")
            return
        }

        let originalRatio = 1000.0 / 500.0
        let resultRatio = Double(width) / Double(height)

        XCTAssertEqual(originalRatio, resultRatio, accuracy: 0.1)
    }

    // MARK: - Small Images

    func testDecodeSmallImageNotDownscaled() {
        let pngData = createValidPNGData(width: 50, height: 50)

        let result = ImageDecoder.decode(from: pngData, asThumbnail: true)

        XCTAssertNotNil(result)
        #if os(iOS)
        XCTAssertEqual(result?.cgImage?.width, 50)
        XCTAssertEqual(result?.cgImage?.height, 50)
        #elseif os(macOS)
        XCTAssertEqual(result?.cgImageRepresentation?.width, 50)
        XCTAssertEqual(result?.cgImageRepresentation?.height, 50)
        #endif
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
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
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

// MARK: - CGImageRepresentationTests

final class CGImageRepresentationTests: XCTestCase {
    #if os(iOS)
    func testUIImageCGImageRepresentation() {
        let size = CGSize(width: 100, height: 100)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0
        let renderer = UIGraphicsImageRenderer(size: size, format: format)
        let image = renderer.image { context in
            UIColor.red.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }

        let cgImage = image.cgImageRepresentation

        XCTAssertNotNil(cgImage)
        XCTAssertEqual(cgImage?.width, 100)
        XCTAssertEqual(cgImage?.height, 100)
    }
    #endif

    #if os(macOS)
    func testNSImageCGImageRepresentation() {
        let size = NSSize(width: 100, height: 100)
        let image = NSImage(size: size)
        image.lockFocus()
        NSColor.red.setFill()
        NSRect(origin: .zero, size: size).fill()
        image.unlockFocus()

        let cgImage = image.cgImageRepresentation

        XCTAssertNotNil(cgImage)
        XCTAssertEqual(cgImage?.width, 100)
        XCTAssertEqual(cgImage?.height, 100)
    }
    #endif
}
