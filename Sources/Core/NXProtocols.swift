//
//  NXProtocols.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Abstraction over the networking backend that executes `URLRequest` values.
///
/// ## Overview
///
/// Adopt `NXHTTPTransport` to stub network responses in tests or replace the default `URLSession` transport.
public protocol NXHTTPTransport: Sendable {
    /// Sends a prepared request and returns the raw HTTP response.
    func send(_ request: URLRequest) async throws -> NXRawResponse
}

/// Decodes failed server responses into domain-specific errors.
public protocol NXServerErrorDecoder: Sendable {
    /// Attempts to decode a custom error from a failed HTTP response.
    func decodeServerError(data: Data, response: HTTPURLResponse, decoder: JSONDecoder) -> (any Error)?
}

/// Default server error decoder that does not produce a custom error.
public struct NXDefaultServerErrorDecoder: NXServerErrorDecoder {
    /// Creates the default server error decoder.
    public init() {}

    /// Always returns `nil`.
    public func decodeServerError(data: Data, response: HTTPURLResponse, decoder: JSONDecoder) -> (any Error)? {
        nil
    }
}

/// Provides bearer tokens for authenticated requests and token refresh.
///
/// ## Overview
///
/// Configure an auth token provider when requests use `.authorized()`.
///
/// ```swift
/// import Nexa
///
/// actor AuthProvider: NXAuthTokenProvider {
///     func currentAccessToken() async throws -> String? {
///         "access-token"
///     }
///
///     func refreshAccessToken() async throws -> String? {
///         "refreshed-access-token"
///     }
/// }
/// ```
public protocol NXAuthTokenProvider: Sendable {
    /// Returns the current access token if one is available.
    func currentAccessToken() async throws -> String?
    /// Refreshes the access token and returns the new value if refresh succeeds.
    func refreshAccessToken() async throws -> String?
}
