//
//  NXTypedRequestBuilder.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Value-semantic builder for configuring requests that decode into a specific response type.
///
/// ## Overview
///
/// Use `NXTypedRequestBuilder` for most application code that should decode directly into a `Decodable` model.
///
/// ```swift
/// import Foundation
/// import Nexa
///
/// struct User: Decodable {
///     let id: Int
///     let name: String
/// }
///
/// let user = try await client
///     .get("/users/me", as: User.self)
///     .query("include", "profile")
///     .accept("application/json")
///     .send()
/// ```
public struct NXTypedRequestBuilder<Response>: Sendable where Response: Decodable {
    let requestBuilder: NXRequestBuilder

    init(requestBuilder: NXRequestBuilder) {
        self.requestBuilder = requestBuilder
    }

    /// Appends a query item to the request URL.
    ///
    /// - Parameters:
    ///   - key: Query item name.
    ///   - value: Query item value converted with `String(describing:)`.
    /// - Returns: Updated typed request builder.
    public func query(_ key: String, _ value: some CustomStringConvertible) -> Self {
        Self(requestBuilder: requestBuilder.query(key, value))
    }

    /// Sets or replaces a single HTTP header.
    ///
    /// - Parameters:
    ///   - key: Header field name.
    ///   - value: Header field value.
    /// - Returns: Updated typed request builder.
    public func header(_ key: String, _ value: String) -> Self {
        Self(requestBuilder: requestBuilder.header(key, value))
    }

    /// Merges multiple HTTP headers into the request.
    ///
    /// - Parameter values: Header field names and values to add. Existing keys are overwritten by incoming values.
    /// - Returns: Updated typed request builder.
    public func headers(_ values: [String: String]) -> Self {
        Self(requestBuilder: requestBuilder.headers(values))
    }

    /// Sets the `Accept` header.
    ///
    /// - Parameter value: Media type value for the `Accept` header.
    /// - Returns: Updated typed request builder.
    public func accept(_ value: String) -> Self {
        Self(requestBuilder: requestBuilder.accept(value))
    }

    /// Marks the request as requiring authentication through the configured auth token provider.
    ///
    /// - Returns: Updated typed request builder.
    public func authorized() -> Self {
        Self(requestBuilder: requestBuilder.authorized())
    }

    /// Sets the per-request timeout interval.
    ///
    /// - Parameter seconds: Timeout interval in seconds. Negative values are clamped to `0`.
    /// - Returns: Updated typed request builder.
    public func timeout(_ seconds: TimeInterval) -> Self {
        Self(requestBuilder: requestBuilder.timeout(seconds))
    }

    /// Encodes an `Encodable` value as JSON and sets the `Content-Type` header.
    ///
    /// - Parameters:
    ///   - value: Value to encode into the request body.
    ///   - encoder: Encoder to use. When omitted, the client configuration encoder is used.
    /// - Returns: Updated typed request builder.
    public func json<T: Encodable>(_ value: T, encoder: JSONEncoder? = nil) throws -> Self {
        try Self(requestBuilder: requestBuilder.json(value, encoder: encoder))
    }

    /// Sets raw request body data.
    ///
    /// - Parameter data: Data to place in the HTTP body.
    /// - Returns: Updated typed request builder.
    public func body(_ data: Data) -> Self {
        Self(requestBuilder: requestBuilder.body(data))
    }

    /// Sets or replaces the `Content-Type` header.
    ///
    /// - Parameter value: Media type value for the `Content-Type` header.
    /// - Returns: Updated typed request builder.
    public func contentType(_ value: String) -> Self {
        Self(requestBuilder: requestBuilder.contentType(value))
    }

    /// Applies a retry policy to the request.
    ///
    /// - Parameter policy: Retry behavior to use during execution.
    /// - Returns: Updated typed request builder.
    public func retry(_ policy: NXRetryPolicy) -> Self {
        Self(requestBuilder: requestBuilder.retry(policy))
    }

    /// Applies a response validation policy to the request.
    ///
    /// - Parameter policy: Validation rule used after the transport returns a response.
    /// - Returns: Updated typed request builder.
    public func validate(_ policy: NXValidationPolicy) -> Self {
        Self(requestBuilder: requestBuilder.validate(policy))
    }

    /// Appends a request-scoped interceptor.
    ///
    /// - Parameter interceptor: Interceptor to insert after global interceptors.
    /// - Returns: Updated typed request builder.
    public func intercept(_ interceptor: any NXHTTPInterceptor) -> Self {
        Self(requestBuilder: requestBuilder.intercept(interceptor))
    }

    /// Assembles the final `URLRequest` without sending it.
    ///
    /// - Returns: Fully prepared URL request.
    public func preparedURLRequest() async throws -> URLRequest {
        try await requestBuilder.preparedURLRequest()
    }

    /// Sends the request and returns the raw HTTP response.
    ///
    /// - Returns: Raw response data and HTTP metadata.
    public func raw() async throws -> NXRawResponse {
        try await requestBuilder.raw()
    }

    /// Sends the request and decodes the response into `Response`.
    ///
    /// - Returns: Decoded response value.
    /// - Throws: `NXError` if the request fails or decoding fails.
    public func send() async throws -> Response {
        try await requestBuilder.decoded(Response.self)
    }
}
