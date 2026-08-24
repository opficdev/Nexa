//
//  NXRetryBackoff.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation

/// 재시도 간격에 사용되는 지연 전략입니다.
public enum NXRetryBackoff: Sendable {
    /// 매 재시도마다 고정 지연을 사용합니다.
    case fixed(TimeInterval)
    /// 매 시도마다 지연을 두 배로 늘려 최대 지연에 도달할 때까지 반복합니다.
    case exponential(base: TimeInterval, maxDelay: TimeInterval)

    func delay(forAttempt attemptNumber: Int) -> TimeInterval {
        switch self {
        case let .fixed(seconds):
            return max(0, seconds)
        case let .exponential(base, maxDelay):
            let exponent = max(0, attemptNumber - 1)
            let computedDelay = base * pow(2, Double(exponent))
            return min(maxDelay, max(0, computedDelay))
        }
    }
}
