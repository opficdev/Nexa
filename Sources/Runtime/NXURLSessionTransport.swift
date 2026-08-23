//
//  NXURLSessionTransport.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Default HTTP transport backed by `URLSession`.
public struct NXURLSessionTransport: NXHTTPTransport, Sendable {
    let urlSession: URLSession

    /// Creates a transport that sends requests through a `URLSession`.
    ///
    /// - Parameter urlSession: Session used to perform requests.
    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
    }

    /// Sends a prepared request through the underlying `URLSession`.
    ///
    /// - Parameter request: Prepared request to execute.
    /// - Returns: Raw response data and HTTP metadata.
    public func send(_ request: URLRequest) async throws -> NXRawResponse {
        let (data, response) = try await urlSession.data(for: request)

        guard let httpURLResponse = response as? HTTPURLResponse else {
            throw NXError.invalidRequest("Non-HTTP response")
        }

        return NXRawResponse(data: data, response: httpURLResponse)
    }
}
