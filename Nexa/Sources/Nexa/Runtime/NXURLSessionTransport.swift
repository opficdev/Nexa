//
//  NXURLSessionTransport.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

public struct NXURLSessionTransport: NXHTTPTransport, Sendable {
    let urlSession: URLSession

    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    public func send(_ request: URLRequest) async throws -> NXRawResponse {
        let (data, response) = try await urlSession.data(for: request)

        guard let httpURLResponse = response as? HTTPURLResponse else {
            throw NXError.invalidRequest("Non-HTTP response")
        }

        return NXRawResponse(data: data, response: httpURLResponse)
    }
}
