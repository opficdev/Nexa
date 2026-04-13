//
//  NXRetryPolicy.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Retry behavior applied to a request when execution fails.
public struct NXRetryPolicy: Sendable {
    /// Delay strategy used between retry attempts.
    public enum Backoff: Sendable {
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

    /// Maximum number of attempts including the initial request.
    public var maxAttempts: Int
    /// Delay strategy used between retry attempts.
    public var backoff: Backoff
    /// HTTP status codes that are eligible for retry.
    public var retryableStatusCodes: Set<Int>

    /// Creates a retry policy.
    ///
    /// - Parameters:
    ///   - maxAttempts: Maximum number of attempts including the initial request.
    ///   - backoff: Delay strategy used between retry attempts.
    ///   - retryableStatusCodes: Status codes that should trigger a retry.
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
