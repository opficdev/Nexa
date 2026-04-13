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

    public func get<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .get, path: path)
    }

    public func post(_ path: String) -> NXRequestBuilder {
        request(method: .post, path: path)
    }

    public func post<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .post, path: path)
    }

    public func put(_ path: String) -> NXRequestBuilder {
        request(method: .put, path: path)
    }

    public func put<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .put, path: path)
    }

    public func patch(_ path: String) -> NXRequestBuilder {
        request(method: .patch, path: path)
    }

    public func patch<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .patch, path: path)
    }

    public func delete(_ path: String) -> NXRequestBuilder {
        request(method: .delete, path: path)
    }

    public func delete<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .delete, path: path)
    }

    public func request<E: NXEndpoint>(_ endpoint: E) -> NXTypedRequestBuilder<E.Response> {
        endpoint.configure(typedRequest(method: endpoint.method, path: endpoint.path))
    }

    public func send<E: NXEndpoint>(_ endpoint: E) async throws -> E.Response {
        try await request(endpoint).send()
    }

    func request(method: NXHTTPMethod, path: String) -> NXRequestBuilder {
        NXRequestBuilder(clientConfiguration: clientConfiguration, requestSpec: RequestSpec(method: method, path: path))
    }

    func typedRequest<Response: Decodable>(method: NXHTTPMethod, path: String) -> NXTypedRequestBuilder<Response> {
        request(method: method, path: path).as(Response.self)
    }
}
