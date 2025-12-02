# Fix: Thumbnail Size Configuration Was Ignored

**Branch:** `fix/thumbnail-config-ignored`

---

## Problem

Setting `Configuration.shared.thumbnailMaxPixelSize` had no effect. Thumbnails were always decoded at 400 pixels regardless of the configured value.

```swift
// This did nothing!
Configuration.shared.thumbnailMaxPixelSize = 200
```

## Root Cause

`ImageDecoder` had a hardcoded constant that was never replaced with the configurable value:

```swift
// ImageDecoder.swift (before)
private enum Constants {
    static let thumbnailMaxSize = 400  // HARDCODED - config ignored
}
```

The `Configuration.shared.thumbnailMaxPixelSize` property existed but was never read by any code path.

## Solution

Add `thumbnailMaxPixelSize` parameter to the decode chain and read from `Configuration.shared` at the call sites.

### Call Chain

```
AsyncCachedImage
    │
    ▼
ImageDownloader.performDownload()
    │
    ├─► reads Configuration.shared.thumbnailMaxPixelSize
    │
    ▼
ImageDownloader.decodeImageData(thumbnailMaxPixelSize:)
    │
    ▼
ImageDecoderBridge.decode(thumbnailMaxPixelSize:)
    │
    ▼
ImageDecoder.decode(thumbnailMaxPixelSize:)
    │
    ▼
CGImageSourceCreateThumbnailAtIndex(maxPixelSize)
```

Same flow for `DiskCache.loadCachedImage()`.

## Files Changed

| File | Change |
|------|--------|
| `ImageDecoder.swift` | Add `thumbnailMaxPixelSize` parameter, remove hardcoded constant |
| `DiskCache.swift` | Read config and pass to decoder |
| `ImageDownloader.swift` | Read config and pass through decode chain |

## Breaking Changes

None. The new parameter has a default value matching the previous hardcoded behavior.

## Verification

```swift
// Now works correctly
Configuration.shared.thumbnailMaxPixelSize = 200

AsyncCachedImage(url: imageURL, asThumbnail: true) { phase in
    // Thumbnail will be max 200px on longest edge
}
```
