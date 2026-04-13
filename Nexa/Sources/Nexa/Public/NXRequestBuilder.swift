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

    func modifying(_ update: (inout RequestSpec) throws -> Void) rethrows -> Self {
        var copiedRequestSpec = requestSpec
        try update(&copiedRequestSpec)
        return Self(clientConfiguration: clientConfiguration, requestSpec: copiedRequestSpec)
    }
}
