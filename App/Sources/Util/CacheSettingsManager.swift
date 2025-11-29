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
import Foundation

// MARK: - CacheSettingsManager

/// Manages synchronization between cache statistics and Settings.bundle.
///
/// This actor writes cache information to UserDefaults, which is then
/// displayed in the iOS Settings app via Settings.bundle.
///
/// The manager also handles the "Clear Cache on Next Launch" toggle,
/// checking it on app launch and clearing the cache if enabled.
///
/// ## Usage
///
/// ```swift
/// // On app launch
/// await CacheSettingsManager.shared.clearCacheIfRequested()
/// await CacheSettingsManager.shared.synchronizeCacheStatistics()
///
/// // When entering background
/// await CacheSettingsManager.shared.synchronizeCacheStatistics()
/// ```
public actor CacheSettingsManager {
    /// The shared cache settings manager instance.
    public static let shared = CacheSettingsManager()

    private init() {}

    // MARK: - Public API

    /// Synchronizes current cache statistics to UserDefaults.
    ///
    /// Call this method when the app enters background or terminates
    /// to ensure Settings.bundle displays up-to-date information.
    ///
    /// Writes:
    /// - Disk usage (formatted)
    /// - Disk capacity (formatted)
    /// - Memory usage (formatted)
    /// - Entry count
    /// - App version and build number
    public func synchronizeCacheStatistics() async {
        let info = await CacheManager.shared.info
        writeStatisticsToDefaults(info: info)
        writeAppVersionToDefaults()
    }

    /// Checks if cache should be cleared based on Settings toggle.
    ///
    /// If the "Clear Cache on Next Launch" toggle is enabled, this method
    /// clears all caches and resets the toggle to false.
    ///
    /// - Returns: True if cache was cleared, false otherwise.
    @discardableResult
    public func clearCacheIfRequested() async -> Bool {
        guard shouldClearCache() else {
            return false
        }

        await performCacheClear()
        resetClearCacheFlag()
        await synchronizeCacheStatistics()

        logCacheCleared()
        return true
    }
}

// MARK: - UserDefaults Keys

private extension CacheSettingsManager {
    /// Keys used for UserDefaults storage.
    ///
    /// These keys must match the identifiers in Settings.bundle/Root.plist.
    enum DefaultsKey {
        /// Key for disk usage display.
        static let diskUsage = "cache_disk_usage"

        /// Key for disk capacity display.
        static let diskCapacity = "cache_disk_capacity"

        /// Key for memory usage display.
        static let memoryUsage = "cache_memory_usage"

        /// Key for entry count display.
        static let entryCount = "cache_entry_count"

        /// Key for the "Clear Cache on Next Launch" toggle.
        static let clearOnLaunch = "cache_clear_on_launch"

        /// Key for app version display.
        static let appVersion = "app_version"

        /// Key for app build number display.
        static let appBuild = "app_build"
    }
}

// MARK: - Statistics Writing

private extension CacheSettingsManager {
    /// Writes cache statistics to UserDefaults.
    ///
    /// - Parameter info: The cache information to write.
    func writeStatisticsToDefaults(info: CacheInfo) {
        let defaults = UserDefaults.standard
        defaults.set(info.diskUsedFormatted, forKey: DefaultsKey.diskUsage)
        defaults.set(info.diskCapacityFormatted, forKey: DefaultsKey.diskCapacity)
        defaults.set(info.memoryUsedFormatted, forKey: DefaultsKey.memoryUsage)
        defaults.set(String(info.cachedEntryCount), forKey: DefaultsKey.entryCount)
        defaults.synchronize()
    }

    /// Writes app version and build number to UserDefaults.
    func writeAppVersionToDefaults() {
        let defaults = UserDefaults.standard
        let version = AppVersionProvider.version
        let build = AppVersionProvider.build

        defaults.set(version, forKey: DefaultsKey.appVersion)
        defaults.set(build, forKey: DefaultsKey.appBuild)
    }
}

// MARK: - Cache Clearing

private extension CacheSettingsManager {
    /// Checks if the clear cache flag is set.
    ///
    /// - Returns: True if cache should be cleared on launch.
    func shouldClearCache() -> Bool {
        UserDefaults.standard.bool(forKey: DefaultsKey.clearOnLaunch)
    }

    /// Performs the actual cache clearing operation.
    func performCacheClear() async {
        await CacheManager.shared.clearAll()
    }

    /// Resets the clear cache flag to false.
    ///
    /// Forces synchronization to ensure the Settings app reflects
    /// the updated value immediately.
    func resetClearCacheFlag() {
        let defaults = UserDefaults.standard
        defaults.set(false, forKey: DefaultsKey.clearOnLaunch)
        defaults.synchronize()
    }
}

// MARK: - Logging

private extension CacheSettingsManager {
    /// Logs cache cleared message in debug builds.
    func logCacheCleared() {
        #if DEBUG
        print("[CacheSettingsManager] Cache cleared via Settings toggle")
        #endif
    }
}

// MARK: - AppVersionProvider

/// Provides app version information from the main bundle.
private enum AppVersionProvider {
    /// The app's marketing version string (e.g., "1.0.0").
    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0.0"
    }

    /// The app's build number string (e.g., "42").
    static var build: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}
