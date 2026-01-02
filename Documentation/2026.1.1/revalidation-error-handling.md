# Fix: Surface Revalidation Errors Instead of Treating Them as Valid

**Branch:** `Revalidation-ErrorHandling`

---

## Problem

Revalidation failures (timeouts, DNS errors, invalid responses) were treated as
"cache still valid." This hid staleness indefinitely when the network was flaky
and made it impossible to react to revalidation errors.

## Solution

Return a structured `RevalidationResult` from `CacheRevalidator` and surface
errors through the existing `onImageError` handler without changing the
current phase or refreshing metadata timestamps.

Key changes:

- `CacheRevalidator.revalidate(...)` now returns `RevalidationResult`
- `.error` includes a `RevalidationError` payload
- `AsyncCachedImage` handles `.error` by calling `onImageError`
- `RevalidationError` gains `LocalizedError` for better messages

## Behavior Change

Revalidation errors no longer keep the cache "fresh" by default. The cached
image remains visible, but the error is now observable and can be logged or
used for retry/backoff in app code.

## Files Changed

| File | Change |
|------|--------|
| `Core/Sources/Cache/CacheRevalidator.swift` | Return `RevalidationResult` and map errors |
| `Core/Sources/Public/AsyncCachedImage.swift` | Handle `.error` by reporting via `onImageError` |
| `Core/Sources/Errors/RevalidationError.swift` | Add `LocalizedError` and better docs |
| `Core/Tests/Cache/RevalidationResultTests.swift` | Update tests for new result type |
| `Core/Tests/Errors/RevalidationErrorTests.swift` | Add localization tests |

## Tests Updated

- `RevalidationResultTests` updated to expect `.error` instead of `true`
- `RevalidationErrorTests` now validate localized error descriptions
