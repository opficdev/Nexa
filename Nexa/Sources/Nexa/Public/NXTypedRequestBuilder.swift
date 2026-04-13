//
//  NXTypedRequestBuilder.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

public struct NXTypedRequestBuilder<Response>: Sendable where Response: Decodable {
    let requestBuilder: NXRequestBuilder

    init(requestBuilder: NXRequestBuilder) {
        self.requestBuilder = requestBuilder
    }

    var clientConfiguration: NXClientConfiguration {
        requestBuilder.clientConfiguration
    }

    var requestSpec: RequestSpec {
        requestBuilder.requestSpec
    }

    public func query(_ key: String, _ value: some CustomStringConvertible) -> Self {
        Self(requestBuilder: requestBuilder.query(key, value))
    }

    public func header(_ key: String, _ value: String) -> Self {
        Self(requestBuilder: requestBuilder.header(key, value))
    }

    public func headers(_ values: [String: String]) -> Self {
        Self(requestBuilder: requestBuilder.headers(values))
    }

    public func accept(_ value: String) -> Self {
        Self(requestBuilder: requestBuilder.accept(value))
    }

    public func authorized() -> Self {
        Self(requestBuilder: requestBuilder.authorized())
    }

    public func timeout(_ seconds: TimeInterval) -> Self {
        Self(requestBuilder: requestBuilder.timeout(seconds))
    }

    public func json<T: Encodable>(_ value: T, encoder: JSONEncoder? = nil) throws -> Self {
        try Self(requestBuilder: requestBuilder.json(value, encoder: encoder))
    }

    public func body(_ data: Data, contentType: String) -> Self {
        Self(requestBuilder: requestBuilder.body(data, contentType: contentType))
    }

    public func retry(_ policy: NXRetryPolicy) -> Self {
        Self(requestBuilder: requestBuilder.retry(policy))
    }

    public func validate(_ policy: NXValidationPolicy) -> Self {
        Self(requestBuilder: requestBuilder.validate(policy))
    }

    public func intercept(_ interceptor: any NXHTTPInterceptor) -> Self {
        Self(requestBuilder: requestBuilder.intercept(interceptor))
    }

    public func preparedURLRequest() async throws -> URLRequest {
        try await requestBuilder.preparedURLRequest()
    }

    public func raw() async throws -> NXRawResponse {
        try await requestBuilder.raw()
    }

    public func send() async throws -> Response {
        try await NXRequestExecutor.executeDecode(
            clientConfiguration: clientConfiguration,
            requestSpec: requestSpec,
            responseType: Response.self
        )
    }

    @available(*, deprecated, message: "send()를 사용하세요.")
    public func send(as type: Response.Type) async throws -> Response {
        try await send()
    }

    public func sendVoid() async throws {
        try await requestBuilder.sendVoid()
    }
}
