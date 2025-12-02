# Breaking: Remove `.loading` Phase for Apple API Compatibility

**Branch:** `fix/remove-loading-phase-apple-compatibility`

---

## Problem

`AsyncCachedImagePhase` had four cases while Apple's `AsyncImagePhase` only has three. This prevented drop-in replacement usage since switch statements required handling the extra `.loading` case.

```swift
// Apple's AsyncImagePhase
enum AsyncImagePhase {
    case empty
    case success(Image)
    case failure(Error)
}

// Our AsyncCachedImagePhase (BEFORE)
enum AsyncCachedImagePhase {
    case empty
    case loading    // <- NOT in Apple's API
    case success(Image)
    case failure(ImageLoadingError)
}
```

## Solution

Remove `.loading` case to match Apple's API exactly. The phase stays `.empty` while loading is in progress, matching Apple's behavior.

```swift
// Our AsyncCachedImagePhase (AFTER)
enum AsyncCachedImagePhase {
    case empty
    case success(Image)
    case failure(ImageLoadingError)
}
```

## Breaking Change

Code that explicitly handled `.loading` will no longer compile:

```swift
// BEFORE - This code will break
switch phase {
case .empty:
    EmptyView()
case .loading:        // ERROR: Type has no member 'loading'
    ProgressView()
case .success(let image):
    image.resizable()
case .failure:
    ErrorView()
}

// AFTER - Handle loading in .empty
switch phase {
case .empty:
    ProgressView()    // Show spinner while loading
case .success(let image):
    image.resizable()
case .failure:
    ErrorView()
}
```

## Migration

Replace `.loading` handling with `.empty`:

| Before | After |
|--------|-------|
| `case .empty, .loading:` | `case .empty:` |
| `case .loading:` | Remove or merge into `.empty` |

## Files Changed

| File | Change |
|------|--------|
| `AsyncCachedImagePhase.swift` | Remove `.loading` case from both enums |
| `AsyncCachedImage.swift` | Remove `updatePhase(.loading)` call, simplify switch statements |
| `AsyncCachedImagePhaseTests.swift` | Remove all `.loading` tests |

## Rationale

AsyncCachedImage is marketed as a drop-in replacement for Apple's AsyncImage. API compatibility is more valuable than the extra granularity of a `.loading` state. Users who need to distinguish "not started" from "loading" can track this in their own state.
