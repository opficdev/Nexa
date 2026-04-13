//
//  NXRetryPolicy.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

public struct NXRetryPolicy: Sendable {
    public enum Backoff: Sendable {
        case fixed(TimeInterval)
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

    public var maxAttempts: Int
    public var backoff: Backoff
    public var retryableStatusCodes: Set<Int>

    public init(
        maxAttempts: Int,
        backoff: Backoff = .fixed(0),
        retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504]
    ) {
        self.maxAttempts = max(1, maxAttempts)
        self.backoff = backoff
        self.retryableStatusCodes = retryableStatusCodes
    }
}
