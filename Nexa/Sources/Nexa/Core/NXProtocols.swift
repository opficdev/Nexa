//
//  NXProtocols.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

public protocol NXHTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> NXRawResponse
}

public protocol NXAuthTokenProvider: Sendable {
    func currentAccessToken() async throws -> String?
    func refreshAccessToken() async throws -> String?
}
