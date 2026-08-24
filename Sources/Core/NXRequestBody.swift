//
//  NXRequestBody.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Nexa가 지원하는 요청 본문 표현 방식입니다.
public enum NXRequestBody: Sendable {
    case data(Data)

    var data: Data {
        switch self {
        case let .data(dataValue):
            dataValue
        }
    }
}
