//
//  NXValidationPolicy.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

public enum NXValidationPolicy: Sendable {
    case none
    case successStatusCode
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
