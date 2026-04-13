//
//  NXClientConfiguration.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

public struct NXClientConfiguration: Sendable {
    public var baseURL: URL
    public var headers: [String: String]
    public var transport: any NXHTTPTransport
    public var decoder: JSONDecoder
    public var encoder: JSONEncoder
    public var authTokenProvider: (any NXAuthTokenProvider)?

    public init(
        baseURL: URL,
        headers: [String: String] = [:],
        transport: any NXHTTPTransport = NXURLSessionTransport(),
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        authTokenProvider: (any NXAuthTokenProvider)? = nil
    ) {
        self.baseURL = baseURL
        self.headers = headers
        self.transport = transport
        self.decoder = decoder
        self.encoder = encoder
        self.authTokenProvider = authTokenProvider
    }
}
