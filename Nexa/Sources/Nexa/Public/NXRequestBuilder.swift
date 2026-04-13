//
//  NXRequestBuilder.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation

public struct NXRequestBuilder: Sendable {
    let clientConfiguration: NXClientConfiguration
    let requestSpec: RequestSpec

    init(clientConfiguration: NXClientConfiguration, requestSpec: RequestSpec) {
        self.clientConfiguration = clientConfiguration
        self.requestSpec = requestSpec
    }

    public func query(_ key: String, _ value: some CustomStringConvertible) -> Self {
        modifying { requestSpec in
            requestSpec.queryItems.append(URLQueryItem(name: key, value: String(describing: value)))
        }
    }

    public func header(_ key: String, _ value: String) -> Self {
        modifying { requestSpec in
            requestSpec.headers[key] = value
        }
    }

    public func headers(_ values: [String: String]) -> Self {
        modifying { requestSpec in
            requestSpec.headers.merge(values) { _, newValue in newValue }
        }
    }

    public func accept(_ value: String) -> Self {
        header("Accept", value)
    }

    public func authorized() -> Self {
        modifying { requestSpec in
            requestSpec.authRequirement = .required
        }
    }

    public func timeout(_ seconds: TimeInterval) -> Self {
        modifying { requestSpec in
            requestSpec.timeout = max(0, seconds)
        }
    }

    public func json<T: Encodable>(_ value: T, encoder: JSONEncoder? = nil) throws -> Self {
        let selectedEncoder = encoder ?? clientConfiguration.encoder
        let encodedValue = try selectedEncoder.encode(value)

        return modifying { requestSpec in
            requestSpec.body = .data(encodedValue)
            requestSpec.headers["Content-Type"] = "application/json; charset=utf-8"
        }
    }

    public func body(_ data: Data) -> Self {
        modifying { requestSpec in
            requestSpec.body = .data(data)
        }
    }

    public func contentType(_ value: String) -> Self {
        modifying { requestSpec in
            requestSpec.headers["Content-Type"] = value
        }
    }

    public func retry(_ policy: NXRetryPolicy) -> Self {
        modifying { requestSpec in
            requestSpec.retryPolicy = policy
        }
    }

    public func validate(_ policy: NXValidationPolicy) -> Self {
        modifying { requestSpec in
            requestSpec.validationPolicy = policy
        }
    }

    public func intercept(_ interceptor: any NXHTTPInterceptor) -> Self {
        modifying { requestSpec in
            requestSpec.requestInterceptors.append(interceptor)
        }
    }

    public func preparedURLRequest() async throws -> URLRequest {
        try NXRequestAssembler.assemble(clientConfiguration: clientConfiguration, requestSpec: requestSpec)
    }

    public func raw() async throws -> NXRawResponse {
        try await NXRequestExecutor.executeRaw(clientConfiguration: clientConfiguration, requestSpec: requestSpec)
    }

    public func `as`<Response: Decodable>(_ type: Response.Type) -> NXTypedRequestBuilder<Response> {
        NXTypedRequestBuilder(requestBuilder: self)
    }

    func modifying(_ update: (inout RequestSpec) throws -> Void) rethrows -> Self {
        var copiedRequestSpec = requestSpec
        try update(&copiedRequestSpec)
        return Self(clientConfiguration: clientConfiguration, requestSpec: copiedRequestSpec)
    }
}
