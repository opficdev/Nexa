//
//  NXRetryBackoff.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation

/// Delay strategy used between retry attempts.
public enum NXRetryBackoff: Sendable {
    /// Uses a fixed delay for every retry attempt.
    case fixed(TimeInterval)
    /// Doubles the delay every attempt until the maximum delay is reached.
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
