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

    public func get<Response>(_ path: String) -> NXRequestBuilder<Response> {
        request(method: .get, path: path)
    }

    public func post<Response>(_ path: String) -> NXRequestBuilder<Response> {
        request(method: .post, path: path)
    }

    public func put<Response>(_ path: String) -> NXRequestBuilder<Response> {
        request(method: .put, path: path)
    }

    public func patch<Response>(_ path: String) -> NXRequestBuilder<Response> {
        request(method: .patch, path: path)
    }

    public func delete<Response>(_ path: String) -> NXRequestBuilder<Response> {
        request(method: .delete, path: path)
    }

    public func request<E: NXEndpoint>(_ endpoint: E) -> NXRequestBuilder<E.Response> {
        endpoint.configure(request(method: endpoint.method, path: endpoint.path))
    }

    public func send<E: NXEndpoint>(_ endpoint: E) async throws -> E.Response {
        try await request(endpoint).send()
    }

    func request<Response>(method: NXHTTPMethod, path: String) -> NXRequestBuilder<Response> {
        NXRequestBuilder(clientConfiguration: clientConfiguration, requestSpec: RequestSpec(method: method, path: path))
    }
}
