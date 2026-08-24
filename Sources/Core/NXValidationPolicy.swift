//
//  NXValidationPolicy.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// 응답 상태 코드의 성공 판정 규칙입니다.
public enum NXValidationPolicy: Sendable {
    /// 상태 코드 유효성 검사를 비활성화합니다.
    case none
    /// `200..<300` 범위의 상태 코드만 허용합니다.
    case successStatusCode
    /// 지정한 상태 코드 집합만 허용합니다.
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
