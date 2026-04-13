//
//  NXError.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Errors produced by Nexa while assembling, sending, validating, or decoding requests.
public enum NXError: Error, Sendable {
    /// Request assembly failed because the input could not produce a valid HTTP request.
    case invalidRequest(String)
    /// The request required authentication but no token was available.
    case authenticationRequired
    /// The request required authentication but no auth token provider was configured.
    case authProviderUnavailable
    /// The underlying transport failed with a `URLError`.
    case transport(URLError)
    /// The request timed out.
    case timeout
    /// The request was cancelled.
    case cancelled
    /// Response validation failed for the received status code.
    case invalidStatus(statusCode: Int, data: Data?)
    /// The server returned a failing status code and a custom server error was decoded.
    case server(statusCode: Int, data: Data?, underlying: any Error)
    /// Response decoding failed for a successful request.
    case decoding(any Error, data: Data?)
    /// An uncategorized error occurred.
    case unknown(any Error)
}
