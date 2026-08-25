//
//  NXValidationPolicy.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// 응답 상태 코드 성공 validation 규칙
public enum NXValidationPolicy: Sendable {
    /// 상태 코드 validation 비활성화
    case none
    /// `200..<300` 범위 상태 코드만 허용
    case successStatusCode
    /// 지정 상태 코드 집합 허용
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
