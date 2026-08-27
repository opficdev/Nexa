//
//  NXRetryBackoff.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation

/// 재시도 간격 지연 전략
public enum NXRetryBackoff: Sendable {
    /// 재시도 시 고정 지연 사용
    case fixed(TimeInterval)
    /// 최대 지연에 도달할 때까지 시도마다 지연을 두 배로 늘림
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
