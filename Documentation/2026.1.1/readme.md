#
Logging and Debug Output (2026.1.1)

**Branch:** `Introduced-Debugging-Trace`

---

## Summary

Add a shared logging system with configurable levels and replace ad-hoc debug prints
with structured logging calls.

## Problem

Debug output was scattered across the codebase via `print` statements guarded by
`#if DEBUG`, with no central toggle or log level control. This made it hard to:

- enable/disable logs consistently
- adjust verbosity for troubleshooting
- swap to custom logging backends

## Solution

Introduce a small logging API similar to OAuthSwift, with `.none` as the default.
The log level can be configured via `Configuration`:

- `LogLevel` enum (`trace`, `warn`, `error`, `none`)
- `LogProtocol` with default implementations
- `DebugLogger` default logger
- `Logging` namespace with shared, thread-safe `log` and `setLogLevel(_:)`

All core log sites now call `Logging.log?.trace/warn/error` instead of `print`.
The demo app sets `Logging.setLogLevel(.trace)` at startup.

## Usage

```swift
Configuration.shared.logLevel = .trace
Logging.log?.warn("Cache skipped for URL: \(url)")
```

## Concurrency

The shared logger storage is protected by a lock so the global logger can be
mutated safely under Swift 6 strict concurrency checks.

## Files Changed

| File | Change |
|------|--------|
| `Core/Sources/Logging/LogLevel.swift` | New log level enum |
| `Core/Sources/Logging/LogProtocol.swift` | New logging protocol and defaults |
| `Core/Sources/Logging/DebugLogger.swift` | Default stdout logger |
| `Core/Sources/Logging/Logging.swift` | Shared logger with thread-safe storage |
| `Core/Sources/Networking/ImageDownloader.swift` | Replace prints with logs |
| `Core/Sources/Cache/CacheRevalidator.swift` | Replace prints with logs |
| `Core/Sources/Cache/DiskCache.swift` | Replace prints with logs |
| `Core/Sources/Public/CacheManager.swift` | Replace prints with logs |
| `Core/Sources/Metadata/MetadataStore.swift` | Replace prints with logs |
| `App/Sources/DemoApp.swift` | Set log level to `.trace` |

## Tests Added

- `Core/Tests/Logging/LogLevelTests.swift`
- `Core/Tests/Logging/LogProtocolTests.swift`
- `Core/Tests/Logging/DebugLoggerTests.swift`
- `Core/Tests/Logging/LoggingTests.swift`
