//
//  NXClientConfiguration.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

public struct NXClientConfiguration: Sendable {
    public let baseURL: URL
    public let headers: [String: String]
    public let transport: any NXHTTPTransport
    public let logger: any NXLogger
    public let interceptors: [any NXHTTPInterceptor]
    public let decoder: JSONDecoder
    public let encoder: JSONEncoder
    public let serverErrorDecoder: any NXServerErrorDecoder
    public let authTokenProvider: (any NXAuthTokenProvider)?

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
