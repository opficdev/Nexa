//
//  NXError.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

public enum NXError: Error, Sendable {
    case invalidRequest(String)
    case authenticationRequired
    case authProviderUnavailable
    case transport(URLError)
    case timeout
    case cancelled
    case invalidStatus(statusCode: Int, data: Data?)
    case server(statusCode: Int, data: Data?, underlying: any Error)
    case decoding(any Error, data: Data?)
    case unknown(any Error)
}
