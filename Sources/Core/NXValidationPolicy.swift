//
//  NXValidationPolicy.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Rules that determine whether a response status code is treated as successful.
public enum NXValidationPolicy: Sendable {
    /// Disables status code validation.
    case none
    /// Accepts status codes in the `200..<300` range.
    case successStatusCode
    /// Accepts only the provided set of status codes.
    case statusCodes(Set<Int>)

    func allows(statusCode: Int) -> Bool {
        switch self {
        case .none:
            true
        case .successStatusCode:
            200 <= statusCode && statusCode < 300
        case let .statusCodes(statusCodes):
            statusCodes.contains(statusCode)
        }
    }
}
