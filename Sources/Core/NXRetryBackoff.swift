//
//  NXRetryBackoff.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation

/// retry 간격 delay 전략
public enum NXRetryBackoff: Sendable {
    /// retry 시 고정 delay 사용
    case fixed(TimeInterval)
    /// 최대 delay 도달 시까지 시도별 두 배 delay 증가
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
