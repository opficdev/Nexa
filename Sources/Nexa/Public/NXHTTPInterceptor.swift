//
//  NXHTTPInterceptor.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Intercepts a request execution step and decides how the chain continues.
///
/// ## Overview
///
/// Implement an interceptor when you need cross-cutting request behavior such as tracing, custom headers, or response observation.
///
/// ```swift
/// import Foundation
/// import Nexa
///
/// struct TraceInterceptor: NXHTTPInterceptor {
///     func intercept(
///         context: NXRequestExecutionContext,
///         next: @escaping @Sendable (NXRequestExecutionContext) async throws -> NXRawResponse
///     ) async throws -> NXRawResponse {
///         var request = context.request
///         request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Trace-Id")
///         return try await next(context.replacingRequest(request))
///     }
/// }
/// ```
public protocol NXHTTPInterceptor: Sendable {
    /// Handles one request execution step.
    ///
    /// - Parameters:
    ///   - context: Current request execution state.
    ///   - next: Closure that continues the interceptor chain.
    /// - Returns: Raw HTTP response produced by the current interceptor or a later step in the chain.
    func intercept(
        context: NXRequestExecutionContext,
        next: @escaping @Sendable (NXRequestExecutionContext) async throws -> NXRawResponse
    ) async throws -> NXRawResponse
}

/// Snapshot of the current request execution state exposed to interceptors.
///
/// `NXRequestExecutionContext` gives interceptors access to the prepared request, request identifier, retry attempt number, and custom metadata.
public struct NXRequestExecutionContext: Sendable {
    /// Request currently being executed.
    public let request: URLRequest
    /// Stable identifier shared by all attempts of the same logical request.
    public let requestIdentifier: UUID
    /// Current attempt number starting from `1`.
    public let attemptNumber: Int
    /// Custom string metadata attached to the request.
    public let userInfo: [String: String]

    let specification: RequestSpec
    let clientConfiguration: NXClientConfiguration

    /// Returns a copy of the context with a different request value.
    ///
    /// - Parameter request: Replacement request to use for the remaining chain.
    /// - Returns: A new execution context with the updated request.
    public func replacingRequest(_ request: URLRequest) -> Self {
        Self(
            request: request,
            requestIdentifier: requestIdentifier,
            attemptNumber: attemptNumber,
            userInfo: userInfo,
            specification: specification,
            clientConfiguration: clientConfiguration
        )
    }

    func withAttemptNumber(_ attemptNumber: Int) -> Self {
        Self(
            request: request,
            requestIdentifier: requestIdentifier,
            attemptNumber: attemptNumber,
            userInfo: userInfo,
            specification: specification,
            clientConfiguration: clientConfiguration
        )
    }
}
