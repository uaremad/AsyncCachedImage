//
//  AsyncCachedImage
//
//  Copyright © 2025 Jan-Hendrik Damerau.
//  https://github.com/uaremad/AsyncCachedImage
//
//  Licensed under the MIT License
//  Free to use without restrictions. See LICENSE file for full terms.
//

import AsyncCachedImage
import SwiftUI

// MARK: - DemoApp

/// The main entry point for the AsyncCachedImage demo application.
///
/// This app demonstrates the AsyncCachedImage library functionality
/// and integrates with Settings.bundle for cache management.
///
/// ## Features
///
/// - Configures AsyncCachedImage with custom settings
/// - Integrates with iOS Settings.bundle for cache management
/// - Synchronizes cache statistics to Settings on background
/// - Handles cache clearing requests from Settings
@main
struct DemoApp: App {
    /// Monitors scene phase changes for settings synchronization.
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            DemoView()
            #if os(macOS)
                .frame(minWidth: 1078, minHeight: 768)
            #endif
        }
        #if os(macOS)
        .windowToolbarStyle(.unified)
        .windowStyle(.hiddenTitleBar)
        #endif
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    /// Initializes the app and configures the image caching library.
    init() {
        configureAsyncCachedImage()
        handleLaunchActions()
    }
}

// MARK: - Configuration

private extension DemoApp {
    /// Configures the AsyncCachedImage library with custom settings.
    ///
    /// Sets up:
    /// - 60 second revalidation interval
    /// - 10 second throttle between revalidation attempts
    /// - 300 pixel max thumbnail size
    /// - 200 image memory cache limit
    /// - 150 MB memory cache size limit
    func configureAsyncCachedImage() {
        AsyncCachedImageConfiguration.shared = Configuration(
            revalidationInterval: 60,
            revalidationThrottleInterval: 10,
            thumbnailMaxPixelSize: 300,
            memoryCacheCountLimit: 200,
            memoryCacheSizeLimit: 150 * 1024 * 1024
        )
    }
}

// MARK: - Launch Actions

private extension DemoApp {
    /// Handles actions that should occur on app launch.
    ///
    /// Checks for cache clear requests from Settings and
    /// synchronizes cache statistics.
    func handleLaunchActions() {
        Task {
            await clearCacheIfRequestedFromSettings()
            await synchronizeCacheStatistics()
        }
    }

    /// Clears cache if the Settings.bundle toggle was enabled.
    func clearCacheIfRequestedFromSettings() async {
        await CacheSettingsManager.shared.clearCacheIfRequested()
    }

    /// Synchronizes cache statistics to Settings.bundle.
    func synchronizeCacheStatistics() async {
        await CacheSettingsManager.shared.synchronizeCacheStatistics()
    }
}

// MARK: - Scene Phase Handling

private extension DemoApp {
    /// Handles scene phase transitions.
    ///
    /// Synchronizes cache statistics when the app enters background
    /// to ensure Settings.bundle displays current information.
    ///
    /// - Parameter phase: The new scene phase.
    func handleScenePhaseChange(_ phase: ScenePhase) {
        switch phase {
        case .background:
            synchronizeOnBackground()
        case .active, .inactive:
            break
        @unknown default:
            break
        }
    }

    /// Synchronizes cache statistics when entering background.
    func synchronizeOnBackground() {
        Task {
            await CacheSettingsManager.shared.synchronizeCacheStatistics()
        }
    }
}
