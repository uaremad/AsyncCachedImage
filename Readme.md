# AsyncCachedImage

[![iOS](https://img.shields.io/badge/iOS-17%2B-blue.svg)]() [![macOS](https://img.shields.io/badge/macOS-14%2B-blue.svg)]() [![Swift](https://img.shields.io/badge/Swift-6-orange.svg)]() [![SwiftUI](https://img.shields.io/badge/SwiftUI-latest-brightgreen.svg)]()

A SwiftUI image component with smart caching and automatic server-side change detection via ETag/Last-Modified headers.

## Features

- **Instant Display** - Images load immediately from memory or disk cache
- **Smart Revalidation** - Automatic background validation using HTTP ETag and Last-Modified headers
- **Seamless Updates** - Changed images swap in without UI flickering
- **Thumbnail Support** - Optional downscaled thumbnails for lists and grids
- **Auto-Refresh** - Revalidates on app foreground, tab switch, and view appearance
- **Request Throttling** - Prevents network spam during rapid scrolling
- **Configurable** - Global defaults and per-image loading options
- **Cache Browser** - Built-in debug view to inspect and manage cached images
- **Cross-Platform** - Supports iOS and macOS

## Installation

### Swift Package Manager

Add AsyncCachedImage to your project using Xcode:

1. Go to **File > Add Package Dependencies...**
2. Enter the repository URL:
   ```
   https://github.com/uaremad/AsyncCachedImage
   ```
3. Select **Up to Next Major Version** and click **Add Package**

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/uaremad/AsyncCachedImage", from: "2025.11.1")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["AsyncCachedImage"]
)
```

### Manual Installation

Alternatively, copy the `Core/Sources` folder into your project.

## Usage

### Basic Usage

Drop-in replacement for `AsyncImage`:
```swift
AsyncCachedImage(url: imageURL) { image in
    image
        .resizable()
        .scaledToFit()
} placeholder: {
    ProgressView()
}
```

### With Thumbnail

For lists and grids, use thumbnails for better performance:
```swift
AsyncCachedImage(url: imageURL, asThumbnail: true) { image in
    image
        .resizable()
        .scaledToFill()
} placeholder: {
    Color.gray.opacity(0.2)
}
.frame(width: 100, height: 100)
.clipShape(RoundedRectangle(cornerRadius: 8))
```

### With Separate Failure View

Show a different view when loading fails:
```swift
AsyncCachedImage(
    url: imageURL,
    content: { image in
        image
            .resizable()
            .scaledToFit()
    },
    placeholder: {
        ProgressView()
    },
    failure: {
        Image(systemName: "exclamationmark.triangle")
            .foregroundStyle(.secondary)
    }
)
```

### Phase-based (like Apple's AsyncImage)

Full control over all loading states:
```swift
AsyncCachedImage(url: imageURL) { phase in
    if let image = phase.image {
        image
            .resizable()
            .scaledToFit()
    } else if phase.error != nil {
        Color.red
    } else {
        ProgressView()
    }
}
```

### With Scale and Transaction

For Retina images and smooth animations (Apple API parity):
```swift
AsyncCachedImage(
    url: imageURL,
    scale: 2.0,  // @2x image, displays at half pixel size
    transaction: Transaction(animation: .easeInOut)
) { phase in
    switch phase {
    case .empty, .loading:
        ProgressView()
    case .success(let image):
        image
            .resizable()
            .transition(.opacity)  // Fade in when loaded
    case .failure:
        Image(systemName: "exclamationmark.triangle")
    }
}
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `scale` | `1.0` | Scale factor for the image. Use `2.0` for @2x, `3.0` for @3x images |
| `transaction` | `Transaction()` | Animation transaction applied when phase changes |

Or with switch for more control:
```swift
AsyncCachedImage(url: imageURL) { phase in
    switch phase {
    case .empty, .loading:
        ProgressView()
    case .success(let image):
        image.resizable()
    case .failure(let error):
        VStack {
            Image(systemName: "exclamationmark.triangle")
            Text(error.localizedDescription)
                .font(.caption)
        }
    }
}
```

### Error Handling

Handle errors for logging or analytics:
```swift
AsyncCachedImage(url: imageURL) { image in
    image.resizable()
} placeholder: {
    ProgressView()
}
.onImageError { error in
    // Log to console
    print("Image failed: \(error.localizedDescription)")
    
    // Access error details
    if let url = error.url {
        print("URL: \(url)")
    }
    if let statusCode = error.statusCode {
        print("HTTP Status: \(statusCode)")
    }
    
    // Report to Crashlytics
    Crashlytics.log("Image error: \(error)")
}
```

Available error types:
| Error | Description |
|-------|-------------|
| `.invalidResponse` | Server response was not valid HTTP |
| `.httpError(statusCode:)` | Server returned error (404, 500, etc.) |
| `.emptyData` | Server returned empty response |
| `.decodingFailed` | Image data could not be decoded |
| `.invalidImageDimensions` | Decoded image has invalid size |
| `.networkError` | Network connection failed |
| `.missingURL` | URL was nil |

## Configuration

### Global Configuration

Set default behavior for all images at app launch:

```swift
@main
struct MyApp: App {
    
    init() {
        AsyncCachedImageConfiguration.shared = AsyncCachedImageConfiguration(
            revalidationInterval: 60,
            revalidationThrottleInterval: 10,
            thumbnailMaxPixelSize: 300,
            memoryCacheCountLimit: 200,
            memoryCacheSizeLimit: 150 * 1024 * 1024,
            logLevel: .trace
        )
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

| Setting | Default | Description |
|---------|---------|-------------|
| `revalidationInterval` | 30 sec | Time before cached content is considered stale |
| `revalidationThrottleInterval` | 5 sec | Minimum time between revalidation attempts |
| `thumbnailMaxPixelSize` | 400 px | Maximum pixel size for thumbnail decoding |
| `memoryCacheCountLimit` | 150 | Maximum decoded images in memory |
| `memoryCacheSizeLimit` | 100 MB | Maximum memory for decoded images |
| `logLevel` | `.none` | Global logging verbosity |

### Logging

Set the global log level via configuration:

```swift
Configuration.shared.logLevel = .warn
```

### Per-Image Configuration

Override global settings for specific images using the `.imageConfiguration()` modifier:

```swift
AsyncCachedImage(url: heroImageURL) { image in
    image.resizable()
} placeholder: {
    ProgressView()
}
.imageConfiguration(ImageLoadingOptions(
    revalidationThrottleInterval: 2
))
```

#### ImageLoadingOptions

| Property | Default | Description |
|----------|---------|-------------|
| `revalidationThrottleInterval` | `nil` (uses global) | Override throttle interval for this image |
| `skipRevalidation` | `false` | Skip revalidation entirely for static images |
| `ignoreCache` | `false` | Always fetch from network |

### Custom Presets

Create reusable presets for your app:

```swift
// MyApp/Extensions/ImageLoadingOptions+Presets.swift
extension ImageLoadingOptions {
    
    /// Hero images - frequent revalidation
    static let hero = ImageLoadingOptions(
        revalidationThrottleInterval: 2
    )
    
    /// Thumbnails in large lists - infrequent revalidation
    static let listThumbnail = ImageLoadingOptions(
        revalidationThrottleInterval: 300
    )
    
    /// Static assets that never change
    static let staticAsset = ImageLoadingOptions(
        skipRevalidation: true
    )
    
    /// User avatars - always fetch fresh
    static let avatar = ImageLoadingOptions(
        ignoreCache: true
    )
}
```

Usage:
```swift
// Hero image at top of screen
AsyncCachedImage(url: heroURL) { ... }
    .imageConfiguration(.hero)

// Thumbnail grid with 300+ images
LazyVGrid(columns: columns) {
    ForEach(items) { item in
        AsyncCachedImage(url: item.url, asThumbnail: true) { ... }
            .imageConfiguration(.listThumbnail)
    }
}

// Company logo that never changes
AsyncCachedImage(url: logoURL) { ... }
    .imageConfiguration(.staticAsset)
```

## Cache Management

```swift
// Get cache info
let info = await CacheManager.shared.info
print(info.summary) // "Disk: 12.3 MB / 500 MB, Memory: 2.1 MB, Entries: 47"

// Clear all caches
await CacheManager.shared.clearAll()

// Clear memory only (keeps disk cache)
await CacheManager.shared.clearMemoryOnly()
```

### Cache Browser

Use the built-in browser to inspect cached images:
```swift
NavigationStack {
    AsyncCachedImageBrowser()
        .navigationTitle("Image Cache")
}
```

## How It Works

1. **First Load** - Image downloads from server, stores in memory + disk cache with ETag/Last-Modified metadata
2. **Subsequent Loads** - Image displays instantly from cache
3. **Background Revalidation** - HEAD request checks if server content changed
4. **If Unchanged** - Updates cache timestamp, no download needed
5. **If Changed** - Downloads new image, swaps seamlessly into view

## Default Limits

| Setting | Value |
|---------|-------|
| Memory Cache | 100 MB |
| Disk Cache | 500 MB |
| Memory Item Limit | 150 images |
| Thumbnail Max Size | 400 px |
| Revalidation Interval | 30 seconds |
| Revalidation Throttle | 5 seconds |

## Requirements

- iOS 17+ / macOS 14+
- Swift 6
- SwiftUI

## License

MIT License - see [LICENSE](LICENSE) for details.