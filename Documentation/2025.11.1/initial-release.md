# AsyncCachedImage 2025.11.1

**Initial Release**

---

## Overview

A SwiftUI image component with smart caching and automatic server-side change detection via ETag/Last-Modified headers. Drop-in replacement for Apple's `AsyncImage` with persistent caching and background revalidation.

## Features

### Caching

- **Two-tier cache**: Memory cache for instant display, disk cache for persistence
- **Automatic eviction**: Memory cache clears under pressure, disk respects size limits
- **Thumbnail support**: Separate cache entries for downscaled variants

### Smart Revalidation

- **HTTP-based validation**: Uses ETag and Last-Modified headers
- **Background checks**: Validates cached content without blocking UI
- **Seamless updates**: Changed images swap in without flickering
- **Request throttling**: Prevents network spam during rapid scrolling

### Auto-Refresh Triggers

- App returns to foreground
- Tab switch in TabView
- View appearance

### Configuration

- **Global defaults**: Set once at app launch
- **Per-image overrides**: Fine-tune individual images via environment
- **Custom presets**: Create reusable configuration objects

### Developer Tools

- **Cache browser**: Built-in SwiftUI view to inspect cached images
- **Cache info**: Programmatic access to cache statistics
- **Error handling**: Typed errors with URL and status code access

## API

### Initializers

| Initializer | Description |
|-------------|-------------|
| `init(url:content:placeholder:)` | Basic usage with content and placeholder |
| `init(url:content:placeholder:failure:)` | Separate failure view |
| `init(url:scale:transaction:content:)` | Phase-based with animation support |
| `init(url:asThumbnail:content:)` | Thumbnail variant |

### View Modifiers

| Modifier | Description |
|----------|-------------|
| `.imageConfiguration(_:)` | Per-image loading options |
| `.onImageError(_:)` | Error callback for logging/analytics |

### Configuration Options

| Property | Default | Description |
|----------|---------|-------------|
| `revalidationInterval` | 30s | Time before content is stale |
| `revalidationThrottleInterval` | 5s | Min time between revalidations |
| `thumbnailMaxPixelSize` | 400px | Max thumbnail dimension |
| `memoryCacheCountLimit` | 150 | Max images in memory |
| `memoryCacheSizeLimit` | 100MB | Max memory usage |

## Requirements

- iOS 17+ / macOS 14+
- Swift 6
- SwiftUI

## Architecture

```
AsyncCachedImage (View)
        │
        ▼
ImageDownloader (Actor)
        │
        ├──▶ MemoryCache (Actor) ──▶ NSCache
        │
        ├──▶ DiskCache (Actor) ──▶ FileManager
        │
        └──▶ MetadataStore (Actor) ──▶ JSON files
                    │
                    ▼
            CacheRevalidator (Actor)
                    │
                    ▼
            HTTP HEAD requests
```

