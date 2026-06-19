//
//  NXAPIClient.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation

/// Shared entry point for building and sending HTTP requests with a single client configuration.
///
/// ## Overview
///
/// Create a client once, then start requests from relative paths.
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
/// let client = NXAPIClient(
///     configuration: NXClientConfiguration(
///         baseURL: URL(string: "https://api.example.com")!
///     )
/// )
///
/// let user = try await client
///     .get("/users/me", as: User.self)
///     .send()
/// ```
///
/// Use the untyped overloads when you need a prepared `URLRequest` or `NXRawResponse`.
public struct NXAPIClient: Sendable {
    private let configuration: NXClientConfiguration
    private let responseCacheStore: NXResponseCacheStore?

    /// Creates a client that uses the provided configuration for all requests.
    ///
    /// - Parameter configuration: Shared settings such as the base URL, transport, logger, and auth provider.
    public init(configuration: NXClientConfiguration) {
        self.configuration = configuration
        responseCacheStore = switch configuration.cache {
        case .disabled:
            nil
        case .memory:
            NXResponseCacheStore()
        }
    }

    /// Creates an untyped `GET` request builder for the given path.
    ///
    /// - Parameter path: Path relative to the configured base URL.
    /// - Returns: A request builder that can be further configured before sending.
    public func get(_ path: String = "") -> NXRequestBuilder {
        request(method: .get, path: path)
    }

    /// Creates a typed `GET` request builder for the given path.
    ///
    /// - Parameters:
    ///   - path: Path relative to the configured base URL.
    ///   - type: Response type to decode when the request succeeds.
    /// - Returns: A typed request builder that decodes into `Response`.
    public func get<Response: Decodable>(_ path: String = "", as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .get, path: path)
    }

    /// Creates an untyped `POST` request builder for the given path.
    ///
    /// - Parameter path: Path relative to the configured base URL.
    /// - Returns: A request builder that can be further configured before sending.
    public func post(_ path: String) -> NXRequestBuilder {
        request(method: .post, path: path)
    }

    /// Creates a typed `POST` request builder for the given path.
    ///
    /// - Parameters:
    ///   - path: Path relative to the configured base URL.
    ///   - type: Response type to decode when the request succeeds.
    /// - Returns: A typed request builder that decodes into `Response`.
    public func post<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .post, path: path)
    }

    /// Creates an untyped `PUT` request builder for the given path.
    ///
    /// - Parameter path: Path relative to the configured base URL.
    /// - Returns: A request builder that can be further configured before sending.
    public func put(_ path: String) -> NXRequestBuilder {
        request(method: .put, path: path)
    }

    /// Creates a typed `PUT` request builder for the given path.
    ///
    /// - Parameters:
    ///   - path: Path relative to the configured base URL.
    ///   - type: Response type to decode when the request succeeds.
    /// - Returns: A typed request builder that decodes into `Response`.
    public func put<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .put, path: path)
    }

    /// Creates an untyped `PATCH` request builder for the given path.
    ///
    /// - Parameter path: Path relative to the configured base URL.
    /// - Returns: A request builder that can be further configured before sending.
    public func patch(_ path: String) -> NXRequestBuilder {
        request(method: .patch, path: path)
    }

    /// Creates a typed `PATCH` request builder for the given path.
    ///
    /// - Parameters:
    ///   - path: Path relative to the configured base URL.
    ///   - type: Response type to decode when the request succeeds.
    /// - Returns: A typed request builder that decodes into `Response`.
    public func patch<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .patch, path: path)
    }

    /// Creates an untyped `DELETE` request builder for the given path.
    ///
    /// - Parameter path: Path relative to the configured base URL.
    /// - Returns: A request builder that can be further configured before sending.
    public func delete(_ path: String) -> NXRequestBuilder {
        request(method: .delete, path: path)
    }

    /// Creates a typed `DELETE` request builder for the given path.
    ///
    /// - Parameters:
    ///   - path: Path relative to the configured base URL.
    ///   - type: Response type to decode when the request succeeds.
    /// - Returns: A typed request builder that decodes into `Response`.
    public func delete<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .delete, path: path)
    }

    /// Builds a typed request from an endpoint value.
    ///
    /// - Parameter endpoint: Endpoint that defines the HTTP method, path, and optional request customization.
    /// - Returns: A typed request builder configured from the endpoint.
    public func request<E: NXEndpoint>(_ endpoint: E) -> NXTypedRequestBuilder<E.Response> {
        endpoint.configure(typedRequest(method: endpoint.method, path: endpoint.path))
    }

    /// Sends an endpoint request and decodes its response.
    ///
    /// - Parameter endpoint: Endpoint that defines the request.
    /// - Returns: Decoded response value for the endpoint.
    public func send<E: NXEndpoint>(_ endpoint: E) async throws -> E.Response {
        try await request(endpoint).send()
    }

    func request(method: NXHTTPMethod, path: String) -> NXRequestBuilder {
        NXRequestBuilder(
            clientConfiguration: configuration,
            responseCacheStore: responseCacheStore,
            requestSpec: RequestSpec(method: method, path: path)
        )
    }

    func typedRequest<Response: Decodable>(method: NXHTTPMethod, path: String) -> NXTypedRequestBuilder<Response> {
        request(method: method, path: path).as(Response.self)
    }
}
