# Fix: Prevent image flicker on parent view re-renders

**Branch:** `fix/sync-memory-cache-prevents-flicker`

---

## Problem

When `AsyncCachedImage` is used inside list rows that re-render frequently (e.g., due to SwiftData updates), images flicker briefly even though they are already cached in memory.

## Root Cause

The `MemoryCache` is implemented as an actor, meaning all cache lookups are async. When SwiftData triggers parent view updates:

1. SwiftUI considers `AsyncCachedImage` a "new" view instance
2. `@State phase` resets to `.empty`
3. The placeholder is rendered immediately
4. An async hop is required to query the actor-isolated cache
5. Only after the next render cycle does the cached image appear

This async gap causes visible flickering, even for images that are already in memory.

## Solution

Introduce `MemoryCacheStorage` - a thread-safe storage backend that can be accessed **synchronously** during view initialization.

### Architecture

```
┌─────────────────────────────────────────────┐
│         MemoryCacheStorage                  │
│  final class: @unchecked Sendable           │
│                                             │
│  - NSCache (thread-safe per Apple docs)     │
│  - Synchronous access for View.init()       │
│  - Shared between actor and views           │
└─────────────────────────────────────────────┘
                    │
        ┌───────────┴───────────┐
        ▼                       ▼
┌───────────────┐      ┌────────────────────┐
│  MemoryCache  │      │ AsyncCachedImage   │
│    (actor)    │      │                    │
│               │      │ init() {           │
│ async store   │      │   _phase = State(  │
│ async remove  │      │     Storage.image  │
│               │      │   )                │
└───────────────┘      │ }                  │
                       └────────────────────┘
```

### Key Changes

- **`MemoryCacheStorage`**: New class wrapping `NSCache` with sync API
- **`MemoryCache`**: Now delegates to shared storage instance  
- **`AsyncCachedImage.init()`**: Sets initial `@State` from sync cache lookup

## Thread Safety

`NSCache` is explicitly documented by Apple as thread-safe:

> *"You can add, remove, and query items in the cache from different threads without having to lock the cache yourself."*
>
> — [Apple Developer Documentation: NSCache](https://developer.apple.com/documentation/foundation/nscache)

## Breaking Changes

None. The public API remains unchanged.

## Files Changed

| File | Change |
|------|--------|
| `MemoryCache.swift` | Added `MemoryCacheStorage`, refactored actor to use it |
| `AsyncCachedImage.swift` | Added `resolveInitialPhase()` for sync cache lookup |
| `MemoryCacheTests.swift` | Added tests for synchronous storage access |

## Tests Added

- `testStorageSharedInstanceExists()`
- `testStorageSyncAccessReturnsStoredImage()`
- `testStorageSyncAccessReturnsNilForNonExistent()`
- `testStorageSyncAccessRespectsThumbnailFlag()`
- `testStorageAndCacheShareSameData()`
- `testStorageSyncAccessDuringConcurrentWrites()`
