//
//  AsyncCachedImage
//
//  Copyright © 2025 Jan-Hendrik Damerau.
//  https://github.com/uaremad/AsyncCachedImage
//
//  Licensed under the MIT License
//  Free to use without restrictions. See LICENSE file for full terms.
//

import XCTest
@testable import AsyncCachedImage

// MARK: - URLSessionImageTests

/// Tests for the URLSession+Image extension which provides pre-configured sessions.
///
/// Two sessions are provided:
/// - `imageCacheSession`: Optimized for image loading with disk/memory caching
/// - `imageNoCacheSession`: Bypasses all caching for revalidation and force-refresh
///
/// These sessions are separate from the app's default URLSession to avoid
/// polluting other network requests with image caching behavior.
final class URLSessionImageTests: XCTestCase {
    // MARK: - imageCacheSession

    /// Verifies the cache session exists.
    ///
    /// Expected: Session is not nil.
    func testImageCacheSessionExists() {
        let session = URLSession.imageCacheSession

        XCTAssertNotNil(session)
    }

    /// Verifies the cache session has a URLCache configured.
    ///
    /// URLCache enables disk and memory caching of responses.
    ///
    /// Expected: urlCache is not nil.
    func testImageCacheSessionHasURLCache() {
        let session = URLSession.imageCacheSession
        let urlCache = session.configuration.urlCache

        XCTAssertNotNil(urlCache)
    }

    /// Verifies the cache session has 100 MB memory capacity.
    ///
    /// Memory cache stores compressed image data for fast retrieval
    /// without disk I/O.
    ///
    /// Expected: memoryCapacity is 100 MB (100 * 1024 * 1024).
    func testImageCacheSessionMemoryCapacity() {
        let session = URLSession.imageCacheSession
        let memoryCapacity = session.configuration.urlCache?.memoryCapacity ?? 0

        let expectedCapacity = 100 * 1024 * 1024
        XCTAssertEqual(memoryCapacity, expectedCapacity)
    }

    /// Verifies the cache session has 500 MB disk capacity.
    ///
    /// Disk cache provides persistent storage across app launches.
    ///
    /// Expected: diskCapacity is 500 MB (500 * 1024 * 1024).
    func testImageCacheSessionDiskCapacity() {
        let session = URLSession.imageCacheSession
        let diskCapacity = session.configuration.urlCache?.diskCapacity ?? 0

        let expectedCapacity = 500 * 1024 * 1024
        XCTAssertEqual(diskCapacity, expectedCapacity)
    }

    /// Verifies the cache session prefers cached data.
    ///
    /// `.returnCacheDataElseLoad` returns cached data immediately if available,
    /// only fetching from network if no cached data exists.
    ///
    /// Expected: cachePolicy is .returnCacheDataElseLoad.
    func testImageCacheSessionCachePolicy() {
        let session = URLSession.imageCacheSession
        let cachePolicy = session.configuration.requestCachePolicy

        XCTAssertEqual(cachePolicy, .returnCacheDataElseLoad)
    }

    /// Verifies the cache session has 30 second request timeout.
    ///
    /// This is the timeout for the initial connection.
    ///
    /// Expected: timeoutIntervalForRequest is 30 seconds.
    func testImageCacheSessionRequestTimeout() {
        let session = URLSession.imageCacheSession
        let timeout = session.configuration.timeoutIntervalForRequest

        XCTAssertEqual(timeout, 30)
    }

    /// Verifies the cache session has 120 second resource timeout.
    ///
    /// This is the timeout for the entire resource download,
    /// allowing for slow connections on large images.
    ///
    /// Expected: timeoutIntervalForResource is 120 seconds.
    func testImageCacheSessionResourceTimeout() {
        let session = URLSession.imageCacheSession
        let timeout = session.configuration.timeoutIntervalForResource

        XCTAssertEqual(timeout, 120)
    }

    // MARK: - imageNoCacheSession

    /// Verifies the no-cache session exists.
    ///
    /// Expected: Session is not nil.
    func testImageNoCacheSessionExists() {
        let session = URLSession.imageNoCacheSession

        XCTAssertNotNil(session)
    }

    /// Verifies the no-cache session has no URLCache.
    ///
    /// This ensures responses are never cached and always fetched fresh.
    ///
    /// Expected: urlCache is nil.
    func testImageNoCacheSessionHasNoURLCache() {
        let session = URLSession.imageNoCacheSession
        let urlCache = session.configuration.urlCache

        XCTAssertNil(urlCache)
    }

    /// Verifies the no-cache session ignores all cached data.
    ///
    /// `.reloadIgnoringLocalAndRemoteCacheData` bypasses both local
    /// and proxy caches, ensuring a fresh request to the origin server.
    ///
    /// Expected: cachePolicy is .reloadIgnoringLocalAndRemoteCacheData.
    func testImageNoCacheSessionCachePolicy() {
        let session = URLSession.imageNoCacheSession
        let cachePolicy = session.configuration.requestCachePolicy

        XCTAssertEqual(cachePolicy, .reloadIgnoringLocalAndRemoteCacheData)
    }

    /// Verifies the no-cache session has 30 second request timeout.
    ///
    /// Same as cache session for consistency.
    ///
    /// Expected: timeoutIntervalForRequest is 30 seconds.
    func testImageNoCacheSessionRequestTimeout() {
        let session = URLSession.imageNoCacheSession
        let timeout = session.configuration.timeoutIntervalForRequest

        XCTAssertEqual(timeout, 30)
    }

    /// Verifies the no-cache session has 120 second resource timeout.
    ///
    /// Same as cache session for consistency.
    ///
    /// Expected: timeoutIntervalForResource is 120 seconds.
    func testImageNoCacheSessionResourceTimeout() {
        let session = URLSession.imageNoCacheSession
        let timeout = session.configuration.timeoutIntervalForResource

        XCTAssertEqual(timeout, 120)
    }

    // MARK: - Session Identity

    /// Verifies imageCacheSession is a singleton.
    ///
    /// Multiple accesses should return the same session instance.
    ///
    /// Expected: Both references point to the same object.
    func testImageCacheSessionIsSingleton() {
        let session1 = URLSession.imageCacheSession
        let session2 = URLSession.imageCacheSession

        XCTAssertTrue(session1 === session2)
    }

    /// Verifies imageNoCacheSession is a singleton.
    ///
    /// Multiple accesses should return the same session instance.
    ///
    /// Expected: Both references point to the same object.
    func testImageNoCacheSessionIsSingleton() {
        let session1 = URLSession.imageNoCacheSession
        let session2 = URLSession.imageNoCacheSession

        XCTAssertTrue(session1 === session2)
    }

    /// Verifies cache and no-cache sessions are different instances.
    ///
    /// They have different configurations and must be separate objects.
    ///
    /// Expected: References point to different objects.
    func testCacheAndNoCacheSessionsAreDifferent() {
        let cacheSession = URLSession.imageCacheSession
        let noCacheSession = URLSession.imageNoCacheSession

        XCTAssertFalse(cacheSession === noCacheSession)
    }
}
