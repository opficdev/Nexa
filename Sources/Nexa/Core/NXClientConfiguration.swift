//
//  NXClientConfiguration.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Shared configuration applied to every request created by an API client.
///
/// ## Overview
///
/// Put shared networking behavior here once, then reuse it through `NXAPIClient`.
///
/// ```swift
/// import Foundation
/// import Nexa
///
/// let configuration = NXClientConfiguration(
///     baseURL: URL(string: "https://api.example.com")!,
///     headers: [
///         "Accept": "application/json"
///     ],
///     transport: NXURLSessionTransport(),
///     logger: NXNoopLogger(),
///     interceptors: []
/// )
///
/// let client = NXAPIClient(configuration: configuration)
/// ```
public struct NXClientConfiguration: Sendable {
    /// Base URL used to resolve relative request paths.
    public let baseURL: URL
    /// Headers added to every request. Request-level headers overwrite these if keys conflict.
    public let headers: [String: String]
    /// Transport used to execute the assembled `URLRequest`.
    public let transport: any NXHTTPTransport
    /// Logger that receives request lifecycle events.
    public let logger: any NXLogger
    /// Interceptors applied to every request.
    public let interceptors: [any NXHTTPInterceptor]
    /// Decoder used by typed requests when no custom decoder is provided elsewhere.
    public let decoder: JSONDecoder
    /// Encoder used for JSON request bodies when no encoder is passed to `json(_:encoder:)`.
    public let encoder: JSONEncoder
    /// Decoder that can map failed server responses into domain-specific errors.
    public let serverErrorDecoder: any NXServerErrorDecoder
    /// Provider used by authenticated requests to fetch and refresh bearer tokens.
    public let authTokenProvider: (any NXAuthTokenProvider)?

    /// Creates a client configuration.
    ///
    /// - Parameters:
    ///   - baseURL: Base URL used to resolve relative request paths.
    ///   - headers: Headers added to every request.
    ///   - transport: Transport used to execute requests.
    ///   - logger: Logger that receives request lifecycle events.
    ///   - interceptors: Interceptors applied to every request.
    ///   - decoder: Decoder used for typed responses.
    ///   - encoder: Encoder used for JSON request bodies.
    ///   - serverErrorDecoder: Decoder used to map failed responses to custom errors.
    ///   - authTokenProvider: Provider used for authenticated requests.
    public init(
        baseURL: URL,
        headers: [String: String] = [:],
        transport: any NXHTTPTransport = NXURLSessionTransport(),
        logger: any NXLogger = NXNoopLogger(),
        interceptors: [any NXHTTPInterceptor] = [],
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        serverErrorDecoder: any NXServerErrorDecoder = NXDefaultServerErrorDecoder(),
        authTokenProvider: (any NXAuthTokenProvider)? = nil
    ) {
        self.baseURL = baseURL
        self.headers = headers
        self.transport = transport
        self.logger = logger
        self.interceptors = interceptors
        self.decoder = decoder
        self.encoder = encoder
        self.serverErrorDecoder = serverErrorDecoder
        self.authTokenProvider = authTokenProvider
    }
}
