//
//  AsyncCachedImage
//
//  Copyright © 2026 Jan-Hendrik Damerau.
//  https://github.com/uaremad/AsyncCachedImage
//
//  Licensed under the MIT License
//  Free to use without restrictions. See LICENSE file for full terms.
//

import SwiftUI

// MARK: - ScenePhaseObserver

/// Observes scene phase changes and triggers a callback when the app becomes active.
///
/// Extracted from AsyncCachedImage to enable unit testing without SwiftUI environment dependencies.
/// This modifier encapsulates the `@Environment(\.scenePhase)` access, isolating it from the main view logic.
///
/// ## Usage
///
/// ```swift
/// content
///     .modifier(ScenePhaseObserver(onBecameActive: revalidateIfNeeded))
/// ```
struct ScenePhaseObserver: ViewModifier {
    /// Callback executed when the app transitions to the active state.
    ///
    /// Marked as `@Sendable` to ensure thread safety when called from async context.
    let onBecameActive: @Sendable () async -> Void

    /// The current scene phase from the environment.
    @Environment(\.scenePhase) private var scenePhase

    func body(content: Content) -> some View {
        content
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .active {
                    Task {
                        await onBecameActive()
                    }
                }
            }
    }
}
