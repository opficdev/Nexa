//
//  NXRequestCacheKey.swift
//  Nexa
//
//  Created by opfic on 6/19/26.
//

import Foundation

struct NXRequestCacheKey: Hashable, Sendable {
    let method: String
    let url: String
    let headers: Set<Header>

    init?(request: URLRequest) {
        guard let method = request.httpMethod,
              let url = request.url?.absoluteString else {
            return nil
        }

        self.method = method
        self.url = url
        headers = Set(
            (request.allHTTPHeaderFields ?? [:])
                .map { Header(name: $0.key.lowercased(), value: $0.value) }
        )
    }

    struct Header: Hashable, Sendable {
        let name: String
        let value: String
    }
}
