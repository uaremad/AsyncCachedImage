//
//  AsyncCachedImage
//
//  Copyright © 2026 Jan-Hendrik Damerau.
//  https://github.com/uaremad/AsyncCachedImage
//
//  Licensed under the MIT License
//  Free to use without restrictions. See LICENSE file for full terms.
//

import Foundation
@preconcurrency import ProjectDescription

// MARK: - Project Constants

/// Central configuration for the AsyncCachedImage demo project.
///
/// Contains all project-wide constants including names, bundle identifiers,
/// and deployment targets for consistent configuration across targets.
private enum ProjectConstants {
    /// The project name used in Tuist and Xcode.
    static let name = "AsyncCachedImage"

    /// The bundle identifier base for all targets.
    static let bundleIdBase = "com.jandamerau.asynccachedimage"

    /// Application target configuration.
    enum App {
        /// The technical name of the main application target.
        static let name = "Demo"

        /// The user-facing display name shown on device.
        static let displayName = "Demo"
    }

    /// Scheme configuration.
    enum Scheme {
        /// The name of the development scheme.
        static let name = "AsyncCachedImageDev"
    }

    /// Deployment target versions for supported platforms.
    enum Deployment {
        /// Minimum iOS version required.
        static let iOS = "26.0"

        /// Minimum macOS version required.
        static let macOS = "26.0"

        /// Combined deployment targets for multiplatform support.
        static let targets: DeploymentTargets = .multiplatform(
            iOS: iOS,
            macOS: macOS
        )
    }
}

// MARK: - Project Definition

/// The AsyncCachedImage demo project.
///
/// A demonstration application showcasing:
/// - Asynchronous image loading with caching
/// - HTTP revalidation via ETag/Last-Modified headers
/// - Memory and disk cache management
/// - SwiftUI integration with AsyncCachedImage view
///
/// ## Platform Support
///
/// - iOS (iPhone)
/// - iPadOS (iPad)
/// - macOS (Desktop)
///
/// ## Build Configurations
///
/// - **Debug**: Development builds with optimized compile times
/// - **Release**: Optimized builds for distribution
let project = Project(
    name: ProjectConstants.name,
    options: .options(
        automaticSchemesOptions: .disabled
    ),
    packages: [
        .local(path: ".")
    ],
    settings: .settings(
        base: .projectBase,
        defaultSettings: .recommended
    ),
    targets: [
        .demoApp
    ],
    schemes: [
        .defaultScheme
    ]
)

// MARK: - Demo App Target

private extension Target {
    /// The demo application target.
    ///
    /// A simple demo app showcasing the AsyncCachedImage library features.
    /// No code signing or provisioning profiles required - runs in simulator only.
    ///
    /// ## Features Demonstrated
    ///
    /// - Bulk image loading without UI blocking
    /// - Multi-level caching (memory + disk)
    /// - Cache revalidation with HTTP conditional headers
    /// - Cache browser for inspecting cached entries
    /// - Settings.bundle integration for cache management
    ///
    /// ## Build Scripts
    ///
    /// - **Pre-build**: SwiftFormat for code formatting
    /// - **Post-build**: SwiftLint for code quality
    static var demoApp: Self {
        .target(
            name: ProjectConstants.App.name,
            destinations: [
                .iPhone,
                .iPad,
                .mac
            ],
            product: .app,
            productName: ProjectConstants.App.displayName,
            bundleId: "\(ProjectConstants.bundleIdBase).demo",
            deploymentTargets: ProjectConstants.Deployment.targets,
            infoPlist: .file(path: "App/Info.plist"),
            sources: ["App/Sources/**/*.swift"],
            resources: ["App/Sources/Resources/**"],
            scripts: .appScripts,
            dependencies: [
                .package(product: "AsyncCachedImage", type: .runtime)
            ],
            settings: .settings(
                base: .projectBase.merging([
                    "MARKETING_VERSION": .appVersion,
                    "CURRENT_PROJECT_VERSION": .appBuildNumber,
                    "PRODUCT_NAME": .string(ProjectConstants.App.displayName),
                    "CODE_SIGN_IDENTITY": .string(""),
                    "CODE_SIGN_STYLE": .string("Automatic")
                ]),
                configurations: [
                    .debug(
                        name: "Debug",
                        settings: [
                            "DEBUG_INFORMATION_FORMAT": "dwarf",
                            "SWIFT_OPTIMIZATION_LEVEL": "-Onone"
                        ]
                    ),
                    .release(
                        name: "Release",
                        settings: [
                            "DEBUG_INFORMATION_FORMAT": "dwarf-with-dsym",
                            "SWIFT_OPTIMIZATION_LEVEL": "-O"
                        ]
                    )
                ],
                defaultSettings: .recommended
            ),
            environmentVariables: [
                "OS_ACTIVITY_MODE": "disable"
            ]
        )
    }
}

// MARK: - Scheme Definition

private extension Scheme {
    /// The default build scheme for the demo app.
    ///
    /// This scheme includes:
    /// - **Build Action**: Builds the demo app
    /// - **Run Action**: Launches the demo app in simulator
    /// - **Test Action**: Runs all unit tests via test plan
    static var defaultScheme: Self {
        .scheme(
            name: ProjectConstants.Scheme.name,
            shared: true,
            buildAction: .buildAction(
                targets: [
                    .project(path: ".", target: ProjectConstants.App.name)
                ]
            ),
            testAction: .testPlans([
                "TestPlans/AllTests.xctestplan"
            ]),
            runAction: .runAction(
                executable: .init(stringLiteral: ProjectConstants.App.name)
            )
        )
    }
}

// MARK: - Scripts Configuration

private extension [TargetScript] {
    /// Build scripts for code quality and formatting.
    ///
    /// ## SwiftFormat (Pre-build)
    ///
    /// Automatically formats code according to project style guide.
    ///
    /// ## SwiftLint (Post-build)
    ///
    /// Enforces code quality and style rules.
    ///
    /// Both tools are optional - build continues with warnings if missing.
    static var appScripts: Self {
        [
            .pre(
                script: .swiftFormat,
                name: "Run SwiftFormat",
                basedOnDependencyAnalysis: false
            ),
            .post(
                script: .swiftLint,
                name: "Run SwiftLint",
                basedOnDependencyAnalysis: false
            )
        ]
    }
}

// MARK: - Script Definitions

private extension String {
    /// SwiftFormat script with graceful degradation.
    ///
    /// Formats all Swift files in the project directory.
    /// Prints a warning if SwiftFormat is not installed.
    static let swiftFormat = """
    export PATH="$PATH:/opt/homebrew/bin"

    if which swiftformat >/dev/null; then
        swiftformat --verbose .
    else
        echo "warning: SwiftFormat not installed. Install with: brew install swiftformat"
    fi
    """

    /// SwiftLint script with graceful degradation.
    ///
    /// Lints all Swift files according to project rules.
    /// Prints a warning if SwiftLint is not installed.
    static let swiftLint = """
    export PATH="$PATH:/opt/homebrew/bin"

    if which swiftlint >/dev/null; then
        swiftlint
    else
        echo "warning: SwiftLint not installed. Install with: brew install swiftlint"
    fi
    """
}

// MARK: - Settings Dictionary Extensions

private extension SettingsDictionary {
    /// Base project settings shared across all configurations.
    ///
    /// ## Key Settings
    ///
    /// - **Swift Version**: 6.1 with strict concurrency
    /// - **Concurrency Checking**: Complete data race safety
    /// - **Testing**: Enabled for future test additions
    /// - **Asset Catalogs**: Standard AppIcon configuration
    static var projectBase: Self {
        [
            "SWIFT_VERSION": "6.1",
            "SWIFT_STRICT_CONCURRENCY": "complete",
            "ENABLE_TESTING_SEARCH_PATHS": "YES",
            "ASSETCATALOG_COMPILER_APPICON_NAME": "AppIcon",
            "ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME": "AccentColor"
        ]
    }
}

// MARK: - Version Helpers

private extension SettingValue {
    /// Reads the app version from `.app-version` file.
    ///
    /// Falls back to "1.0.0" if file is missing.
    static var appVersion: Self {
        readVersionFile(named: ".app-version", defaultValue: "1.0.0")
    }

    /// Reads the app build number from `.app-buildnumber` file.
    ///
    /// Falls back to "1" if file is missing.
    static var appBuildNumber: Self {
        readVersionFile(named: ".app-buildnumber", defaultValue: "1")
    }

    /// Helper method to read version files with fallback.
    ///
    /// - Parameters:
    ///   - fileName: The name of the version file to read.
    ///   - defaultValue: Fallback value if file cannot be read.
    /// - Returns: A setting value containing the version string.
    private static func readVersionFile(named fileName: String, defaultValue: String) -> Self {
        let rootPath = FileManager.default.currentDirectoryPath
        let filePath = rootPath + "/" + fileName

        do {
            let value = try String(contentsOfFile: filePath, encoding: .utf8)
                .trimmingCharacters(in: .whitespacesAndNewlines)
            return .string(value)
        } catch {
            print("warning: Could not read \(fileName), using default: \(defaultValue)")
            return .string(defaultValue)
        }
    }
}
