//
//  NXRequestBody.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Request body representations supported by Nexa.
public enum NXRequestBody: Sendable {
    case data(Data)

    var data: Data {
        switch self {
        case let .data(dataValue):
            dataValue
        }
    }
}
