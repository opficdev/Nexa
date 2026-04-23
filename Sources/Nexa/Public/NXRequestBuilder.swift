//
//  NXRequestBuilder.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation

/// Value-semantic builder for configuring and sending raw HTTP requests.
///
/// ## Overview
///
/// Use `NXRequestBuilder` when you want to inspect the prepared request or handle the raw response yourself.
///
/// ```swift
/// import Foundation
/// import Nexa
///
/// let request = try await client
///     .post("/users")
///     .header("X-Trace-Id", UUID().uuidString)
///     .preparedURLRequest()
/// ```
///
/// ```swift
/// import Foundation
/// import Nexa
///
/// let response = try await client
///     .get("/users")
///     .accept("application/json")
///     .raw()
/// ```
public struct NXRequestBuilder: Sendable {
    let clientConfiguration: NXClientConfiguration
    let requestSpec: RequestSpec

    /// Appends a query item to the request URL.
    ///
    /// - Parameters:
    ///   - key: Query item name.
    ///   - value: Query item value converted with `String(describing:)`.
    /// - Returns: Updated request builder.
    public func query(_ key: String, _ value: some CustomStringConvertible) -> Self {
        modifying { requestSpec in
            requestSpec.queryItems.append(URLQueryItem(name: key, value: String(describing: value)))
        }
    }

    /// Sets or replaces a single HTTP header.
    ///
    /// - Parameters:
    ///   - key: Header field name.
    ///   - value: Header field value.
    /// - Returns: Updated request builder.
    public func header(_ key: String, _ value: String) -> Self {
        modifying { requestSpec in
            requestSpec.headers[key] = value
        }
    }

    /// Merges multiple HTTP headers into the request.
    ///
    /// - Parameter values: Header field names and values to add. Existing keys are overwritten by incoming values.
    /// - Returns: Updated request builder.
    public func headers(_ values: [String: String]) -> Self {
        modifying { requestSpec in
            requestSpec.headers.merge(values) { _, newValue in newValue }
        }
    }

    /// Sets the `Accept` header.
    ///
    /// - Parameter value: Media type value for the `Accept` header.
    /// - Returns: Updated request builder.
    public func accept(_ value: String) -> Self {
        header("Accept", value)
    }

    /// Marks the request as requiring authentication through the configured auth token provider.
    ///
    /// - Returns: Updated request builder.
    public func authorized() -> Self {
        modifying { requestSpec in
            requestSpec.authRequirement = .required
        }
    }

    /// Sets the per-request timeout interval.
    ///
    /// - Parameter seconds: Timeout interval in seconds. Negative values are clamped to `0`.
    /// - Returns: Updated request builder.
    public func timeout(_ seconds: TimeInterval) -> Self {
        modifying { requestSpec in
            requestSpec.timeout = max(0, seconds)
        }
    }

    /// Encodes an `Encodable` value as JSON and sets the `Content-Type` header.
    ///
    /// - Parameters:
    ///   - value: Value to encode into the request body.
    ///   - encoder: Encoder to use. When omitted, the client configuration encoder is used.
    /// - Returns: Updated request builder.
    public func json<T: Encodable>(_ value: T, encoder: JSONEncoder? = nil) throws -> Self {
        let selectedEncoder = encoder ?? clientConfiguration.encoder
        let encodedValue = try selectedEncoder.encode(value)

        return modifying { requestSpec in
            requestSpec.body = .data(encodedValue)
            requestSpec.headers["Content-Type"] = "application/json; charset=utf-8"
        }
    }

    /// Sets raw request body data.
    ///
    /// - Parameter data: Data to place in the HTTP body.
    /// - Returns: Updated request builder.
    public func body(_ data: Data) -> Self {
        modifying { requestSpec in
            requestSpec.body = .data(data)
        }
    }

    /// Sets or replaces the `Content-Type` header.
    ///
    /// - Parameter value: Media type value for the `Content-Type` header.
    /// - Returns: Updated request builder.
    public func contentType(_ value: String) -> Self {
        modifying { requestSpec in
            requestSpec.headers["Content-Type"] = value
        }
    }

    /// Applies a retry policy to the request.
    ///
    /// - Parameter policy: Retry behavior to use during execution.
    /// - Returns: Updated request builder.
    public func retry(_ policy: NXRetryPolicy) -> Self {
        modifying { requestSpec in
            requestSpec.retryPolicy = policy
        }
    }

    /// Applies a response validation policy to the request.
    ///
    /// - Parameter policy: Validation rule used after the transport returns a response.
    /// - Returns: Updated request builder.
    public func validate(_ policy: NXValidationPolicy) -> Self {
        modifying { requestSpec in
            requestSpec.validationPolicy = policy
        }
    }

    /// Appends a request-scoped interceptor.
    ///
    /// - Parameter interceptor: Interceptor to insert after global interceptors.
    /// - Returns: Updated request builder.
    public func intercept(_ interceptor: any NXHTTPInterceptor) -> Self {
        modifying { requestSpec in
            requestSpec.requestInterceptors.append(interceptor)
        }
    }

    /// Assembles the final `URLRequest` without sending it.
    ///
    /// - Returns: Fully prepared URL request.
    public func preparedURLRequest() async throws -> URLRequest {
        try NXRequestAssembler.assemble(clientConfiguration: clientConfiguration, requestSpec: requestSpec)
    }

    /// Sends the request and returns the raw HTTP response.
    ///
    /// - Returns: Raw response data and HTTP metadata.
    public func raw() async throws -> NXRawResponse {
        try await NXRequestExecutor.executeRaw(clientConfiguration: clientConfiguration, requestSpec: requestSpec)
    }

    /// Converts the builder into a typed builder that decodes the response.
    ///
    /// - Parameter type: Response type to decode when the request succeeds.
    /// - Returns: Typed request builder for `Response`.
    public func `as`<Response: Decodable>(_ type: Response.Type) -> NXTypedRequestBuilder<Response> {
        NXTypedRequestBuilder(requestBuilder: self)
    }

    func modifying(_ update: (inout RequestSpec) throws -> Void) rethrows -> Self {
        var copiedRequestSpec = requestSpec
        try update(&copiedRequestSpec)
        return Self(clientConfiguration: clientConfiguration, requestSpec: copiedRequestSpec)
    }
}
