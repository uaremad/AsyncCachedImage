# Fix: Reload When URL Changes After a Successful Load

**Branch:** `codex/reload-when-url-changes-after-successful-load`

---

## Problem

`AsyncCachedImage` could keep showing the wrong image when SwiftUI reused the
same view instance for a different URL.

This showed up in detail views where the image URL changes while the view is
already displaying a previously loaded image. The component treated any
`.success` phase as "already loaded" and skipped the new load, even if that
success belonged to an older URL.

## Root Cause

The loading path only checked whether `phase` was `.empty` before doing cache or
network work:

```swift
guard case .empty = phase else { return }
```

That made `.success` a URL-independent terminal state. When `url` changed, the
old image could remain visible because the loader returned before checking
memory cache, disk cache, or the network for the new URL.

## Solution

Track the URL associated with the current successful image and only skip loading
when the current phase is a successful load for the exact same URL.

Key changes:

- Add `loadedURL` state to remember which URL produced the current `.success`
- Add `activeURL` state so stale async work can compare against the live view URL
- Initialize `loadedURL` from the synchronous memory-cache hit during view init
- Replace the URL-blind `.empty` guard with a `.success` and `loadedURL` check
- Re-check memory cache when the URL changes before falling back to disk/network
- Reset `loadedURL` on missing URL and network failure
- Discard stale async results if the view's URL changed while awaiting disk or network work
- Run revalidation from the URL-scoped task instead of an unstructured `onAppear` task

## Behavior Change

Changing `url` on an existing `AsyncCachedImage` now triggers a load for the new
URL even if an older image is still visible.

The old image intentionally remains on screen while the new image is loading.
This avoids placeholder flicker during URL changes, but prevents stale async
results from overwriting newer state.

## Breaking Changes

None. The public API remains unchanged.

## Files Changed

| File | Change |
|------|--------|
| `Core/Sources/Public/AsyncCachedImage.swift` | Track successful and active URLs, reload on URL changes, and guard async state updates against stale requests |
| `Core/Sources/Public/AsyncCachedImageLoadPolicy.swift` | Encapsulate the URL-aware load/skip decision for focused regression coverage |
| `Core/Sources/Environment/ScenePhaseObserver.swift` | Trigger foreground revalidation through URL-scoped SwiftUI tasks instead of unstructured async work |
| `Core/Tests/Public/AsyncCachedImageTests.swift` | Add regression coverage for URL changes after a successful load |

## Verification

```bash
swift test
```

Expected result: all tests pass.
