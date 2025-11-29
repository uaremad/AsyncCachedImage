// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "AsyncCachedImage",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "AsyncCachedImage",
            targets: ["AsyncCachedImage"]
        )
    ],
    targets: [
        .target(
            name: "AsyncCachedImage",
            path: "Core/Sources",
            swiftSettings: .default
        ),
        .testTarget(
            name: "AsyncCachedImageTests",
            dependencies: ["AsyncCachedImage"],
            path: "Core/Tests",
            swiftSettings: .default
        )
    ],
    swiftLanguageModes: [.v6]
)

// MARK: - Swift Settings Extension

extension [SwiftSetting] {
    /// Default Swift settings for all targets.
    ///
    /// Enables Swift 6 strict concurrency checking.
    static var `default`: [SwiftSetting] {
        [
            .enableUpcomingFeature("StrictConcurrency")
        ]
    }
}
