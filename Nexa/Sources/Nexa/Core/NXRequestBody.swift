//
//  NXRequestBody.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

public enum NXRequestBody: Sendable {
    case data(Data, contentType: String)

    var data: Data {
        switch self {
        case let .data(dataValue, _):
            dataValue
        }
    }

    var contentType: String {
        switch self {
        case let .data(_, contentTypeValue):
            contentTypeValue
        }
    }
}
