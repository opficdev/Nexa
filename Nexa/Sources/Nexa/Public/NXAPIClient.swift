//
//  NXAPIClient.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation

public struct NXAPIClient: Sendable {
    let clientConfiguration: NXClientConfiguration

    public init(configuration: NXClientConfiguration) {
        clientConfiguration = configuration
    }

    public func get(_ path: String) -> NXRequestBuilder {
        request(method: .get, path: path)
    }

    public func post(_ path: String) -> NXRequestBuilder {
        request(method: .post, path: path)
    }

    public func put(_ path: String) -> NXRequestBuilder {
        request(method: .put, path: path)
    }

    public func patch(_ path: String) -> NXRequestBuilder {
        request(method: .patch, path: path)
    }

    public func delete(_ path: String) -> NXRequestBuilder {
        request(method: .delete, path: path)
    }

    public func request<E: NXEndpoint>(_ endpoint: E) -> NXRequestBuilder {
        endpoint.configure(request(method: endpoint.method, path: endpoint.path))
    }

    public func send<E: NXEndpoint>(_ endpoint: E) async throws -> E.Response {
        try await request(endpoint).send(as: E.Response.self)
    }

    func request(method: NXHTTPMethod, path: String) -> NXRequestBuilder {
        NXRequestBuilder(clientConfiguration: clientConfiguration, requestSpec: RequestSpec(method: method, path: path))
    }
}
