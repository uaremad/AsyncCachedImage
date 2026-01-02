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

// MARK: - CacheRevalidator

/// Validates cached resources against the server using conditional requests.
///
/// Uses HTTP conditional headers (ETag and Last-Modified) to efficiently check
/// if cached content is still valid without downloading the full resource.
///
/// The revalidation process:
/// 1. Sends a HEAD request with If-None-Match (ETag) and If-Modified-Since headers
/// 2. If server returns 304 Not Modified, the cache is valid
/// 3. If server returns 200 OK, compares headers to determine validity
/// 4. On network errors, assumes cache is valid to avoid unnecessary failures
enum CacheRevalidator {
    // MARK: - Public API

    /// Revalidates a cached resource against the server.
    ///
    /// Sends a conditional HEAD request to check if the cached resource is still valid.
    /// Uses ETag and Last-Modified headers for comparison.
    ///
    /// - Parameters:
    ///   - url: The resource URL to revalidate.
    ///   - metadata: The stored cache metadata containing ETag or Last-Modified values.
    /// - Returns: True if the cached resource is still valid, false if it needs refresh.
    ///
    /// - Note: Returns true on network errors to prevent unnecessary cache invalidation.
    static func revalidate(for url: URL, metadata: Metadata) async -> Bool {
        let request = ConditionalRequestBuilder.build(for: url, metadata: metadata)

        do {
            let response = try await performHeadRequest(request)
            let result = ResponseEvaluator.evaluate(response, against: metadata, url: url)
            return result == .valid
        } catch {
            logError(error, url: url)
            return true
        }
    }

    // MARK: - Network

    /// Performs a HEAD request to check resource validity.
    ///
    /// - Parameter request: The configured URL request.
    /// - Returns: The HTTP response from the server.
    /// - Throws: `RevalidationError.invalidResponse` if the response is not HTTP.
    private static func performHeadRequest(_ request: URLRequest) async throws -> HTTPURLResponse {
        let (_, response) = try await URLSession.imageNoCacheSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw RevalidationError.invalidResponse
        }

        return httpResponse
    }

    // MARK: - Logging

    /// Logs a revalidation error in debug builds.
    ///
    /// - Parameters:
    ///   - error: The error that occurred.
    ///   - url: The URL that failed revalidation.
    private static func logError(_ error: Error, url: URL) {
        Logging.log?.error(
            "[CacheRevalidator] Error for \(url.lastPathComponent): \(error.localizedDescription)"
        )
    }
}

// MARK: - RevalidationResult

/// Result of a cache revalidation check.
enum RevalidationResult: Sendable {
    /// The cached resource is still valid and matches the server version.
    case valid

    /// The cached resource is outdated and needs to be refreshed.
    case invalid

    /// An error occurred during revalidation.
    case error
}

// MARK: - ConditionalRequestBuilder

/// Builds conditional HTTP requests for cache revalidation.
///
/// Creates HEAD requests with appropriate conditional headers based on cached metadata.
private enum ConditionalRequestBuilder {
    /// Builds a conditional HEAD request for revalidation.
    ///
    /// Configures a request with:
    /// - HEAD method to minimize bandwidth
    /// - Cache policy to ignore local cache
    /// - Conditional headers from metadata
    ///
    /// - Parameters:
    ///   - url: The URL to validate.
    ///   - metadata: The cached metadata containing ETag or Last-Modified values.
    /// - Returns: A configured URLRequest ready for revalidation.
    static func build(for url: URL, metadata: Metadata) -> URLRequest {
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.cachePolicy = .reloadIgnoringLocalCacheData
        addConditionalHeaders(to: &request, metadata: metadata)
        return request
    }

    /// Adds conditional headers to a request based on cached metadata.
    ///
    /// - Parameters:
    ///   - request: The request to modify.
    ///   - metadata: The metadata containing header values.
    private static func addConditionalHeaders(to request: inout URLRequest, metadata: Metadata) {
        addETagHeader(to: &request, etag: metadata.etag)
        addLastModifiedHeader(to: &request, lastModified: metadata.lastModified)
    }

    /// Adds the If-None-Match header for ETag validation.
    ///
    /// - Parameters:
    ///   - request: The request to modify.
    ///   - etag: The cached ETag value, or nil if not available.
    private static func addETagHeader(to request: inout URLRequest, etag: String?) {
        guard let etag else { return }
        request.setValue(etag, forHTTPHeaderField: "If-None-Match")
    }

    /// Adds the If-Modified-Since header for Last-Modified validation.
    ///
    /// - Parameters:
    ///   - request: The request to modify.
    ///   - lastModified: The cached Last-Modified value, or nil if not available.
    private static func addLastModifiedHeader(to request: inout URLRequest, lastModified: String?) {
        guard let lastModified else { return }
        request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
    }
}

// MARK: - ResponseEvaluator

/// Evaluates HTTP responses for cache validity.
///
/// Determines if a cached resource is still valid based on HTTP status codes
/// and header comparisons.
private enum ResponseEvaluator {
    /// Evaluates whether a response indicates the cache is still valid.
    ///
    /// Evaluation logic:
    /// 1. 304 Not Modified -> Cache is valid
    /// 2. 200 OK -> Compare ETag and Last-Modified headers
    /// 3. Other status codes -> Cache is invalid
    ///
    /// - Parameters:
    ///   - response: The HTTP response to evaluate.
    ///   - metadata: The cached metadata to compare against.
    ///   - url: The URL being validated (for logging).
    /// - Returns: The evaluation result indicating cache validity.
    static func evaluate(
        _ response: HTTPURLResponse,
        against metadata: Metadata,
        url: URL
    ) -> RevalidationResult {
        logAttempt(url: url, metadata: metadata, response: response)

        if isNotModified(response) {
            logResult(.valid, reason: "304", url: url)
            return .valid
        }

        if isSuccess(response) {
            return evaluateHeaders(response: response, metadata: metadata, url: url)
        }

        logResult(.invalid, reason: "fallback", url: url)
        return .invalid
    }

    /// Checks if the response indicates the resource was not modified.
    ///
    /// - Parameter response: The HTTP response to check.
    /// - Returns: True if status code is 304.
    private static func isNotModified(_ response: HTTPURLResponse) -> Bool {
        response.statusCode == 304
    }

    /// Checks if the response indicates a successful request.
    ///
    /// - Parameter response: The HTTP response to check.
    /// - Returns: True if status code is 200.
    private static func isSuccess(_ response: HTTPURLResponse) -> Bool {
        response.statusCode == 200
    }

    /// Evaluates response headers to determine cache validity.
    ///
    /// Compares ETag and Last-Modified headers from the response against cached values.
    ///
    /// - Parameters:
    ///   - response: The HTTP response containing headers.
    ///   - metadata: The cached metadata to compare against.
    ///   - url: The URL being validated (for logging).
    /// - Returns: The evaluation result based on header comparison.
    private static func evaluateHeaders(
        response: HTTPURLResponse,
        metadata: Metadata,
        url: URL
    ) -> RevalidationResult {
        if let etagResult = ETagComparator.compare(response: response, metadata: metadata, url: url) {
            return etagResult
        }

        if let lastModResult = LastModifiedComparator.compare(response: response, metadata: metadata, url: url) {
            return lastModResult
        }

        logResult(.invalid, reason: "no matching headers", url: url)
        return .invalid
    }

    /// Logs a revalidation attempt in debug builds.
    ///
    /// - Parameters:
    ///   - url: The URL being revalidated.
    ///   - metadata: The cached metadata being used.
    ///   - response: The server response received.
    private static func logAttempt(url: URL, metadata: Metadata, response: HTTPURLResponse) {
        Logging.log?.trace(
            "[CacheRevalidator] Revalidating: \(url.lastPathComponent)"
        )
        Logging.log?.trace(
            "[CacheRevalidator]   Sent ETag: \(metadata.etag ?? "none")"
        )
        Logging.log?.trace(
            "[CacheRevalidator]   Sent Last-Modified: \(metadata.lastModified ?? "none")"
        )
        Logging.log?.trace(
            "[CacheRevalidator]   Response Status: \(response.statusCode)"
        )
        Logging.log?.trace(
            "[CacheRevalidator]   New ETag: \(response.value(forHTTPHeaderField: "ETag") ?? "none")"
        )
        Logging.log?.trace(
            "[CacheRevalidator]   New Last-Modified: \(response.value(forHTTPHeaderField: "Last-Modified") ?? "none")"
        )
    }

    /// Logs the revalidation result in debug builds.
    ///
    /// - Parameters:
    ///   - result: The revalidation result.
    ///   - reason: A description of why this result was determined.
    ///   - url: The URL that was revalidated.
    private static func logResult(_ result: RevalidationResult, reason: String, url _: URL) {
        let status = result == .valid ? "VALID" : "INVALID"
        Logging.log?.trace(
            "[CacheRevalidator]   Result: \(status) (\(reason))"
        )
    }
}

// MARK: - ETagComparator

/// Compares ETag headers for cache validation.
///
/// ETags are unique identifiers assigned by the server to specific versions of a resource.
/// If the ETag matches, the cached version is still valid.
private enum ETagComparator {
    /// Compares ETag values between response and cached metadata.
    ///
    /// - Parameters:
    ///   - response: The HTTP response containing the current ETag.
    ///   - metadata: The cached metadata containing the stored ETag.
    ///   - url: The URL being validated (for logging).
    /// - Returns: The comparison result, or nil if ETag comparison is not possible.
    static func compare(
        response: HTTPURLResponse,
        metadata: Metadata,
        url _: URL
    ) -> RevalidationResult? {
        guard let oldETag = metadata.etag else { return nil }
        guard let newETag = response.value(forHTTPHeaderField: "ETag") else { return nil }

        let matches = oldETag == newETag

        let status = matches ? "VALID" : "INVALID"
        Logging.log?.trace(
            "[CacheRevalidator]   Result: \(status) (ETag)"
        )

        return matches ? .valid : .invalid
    }
}

// MARK: - LastModifiedComparator

/// Compares Last-Modified headers for cache validation.
///
/// The Last-Modified header indicates when the resource was last changed on the server.
/// If the timestamp matches, the cached version is still valid.
private enum LastModifiedComparator {
    /// Compares Last-Modified values between response and cached metadata.
    ///
    /// - Parameters:
    ///   - response: The HTTP response containing the current Last-Modified timestamp.
    ///   - metadata: The cached metadata containing the stored Last-Modified timestamp.
    ///   - url: The URL being validated (for logging).
    /// - Returns: The comparison result, or nil if Last-Modified comparison is not possible.
    static func compare(
        response: HTTPURLResponse,
        metadata: Metadata,
        url _: URL
    ) -> RevalidationResult? {
        guard let oldLastModified = metadata.lastModified else { return nil }
        guard let newLastModified = response.value(forHTTPHeaderField: "Last-Modified") else { return nil }

        let matches = oldLastModified == newLastModified

        let status = matches ? "VALID" : "INVALID"
        Logging.log?.trace(
            "[CacheRevalidator]   Result: \(status) (Last-Modified)"
        )

        return matches ? .valid : .invalid
    }
}
