//
//  NXRetryPolicy.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Retry behavior applied to a request when execution fails.
///
/// ## Overview
///
/// By default, Nexa retries `GET`, `HEAD`, `PUT`, `DELETE`, and `OPTIONS` requests
/// for retryable transport errors and configured status codes. Add `POST` or `PATCH`
/// to ``retryableMethods`` only when the endpoint safely accepts repeated requests.
///
/// For `429` and `503` responses, a valid `Retry-After` value takes precedence over
/// local backoff and is limited by ``maximumServerDelay``. ``Jitter`` applies only to
/// local backoff delays.
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

    /// Randomization applied to local backoff delays.
    public enum Jitter: Sendable, Equatable {
        /// Keeps the local backoff delay unchanged.
        case none
        /// Uses a random value within the local backoff delay range.
        case full
    }

    /// Maximum number of attempts including the initial request.
    public var maxAttempts: Int
    /// Delay strategy used between retry attempts.
    public var backoff: Backoff
    /// HTTP status codes that are eligible for retry.
    public var retryableStatusCodes: Set<Int>
    /// HTTP methods that are eligible for retry.
    public var retryableMethods: Set<NXHTTPMethod>
    /// Upper limit applied to a server-provided retry delay.
    public var maximumServerDelay: TimeInterval
    /// Randomization applied to local backoff delays.
    public var jitter: Jitter

    /// Creates a retry policy.
    ///
    /// - Parameters:
    ///   - maxAttempts: Maximum number of attempts including the initial request.
    ///   - backoff: Delay strategy used between retry attempts.
    ///   - retryableStatusCodes: Status codes that should trigger a retry.
    ///   - retryableMethods: HTTP methods that should trigger a retry.
    ///   - maximumServerDelay: Upper limit applied to a server-provided retry delay.
    ///   - jitter: Randomization applied to local backoff delays.
    public init(
        maxAttempts: Int,
        backoff: Backoff = .fixed(0),
        retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504],
        retryableMethods: Set<NXHTTPMethod> = [.get, .head, .put, .delete, .options],
        maximumServerDelay: TimeInterval = 60,
        jitter: Jitter = .none
    ) {
        self.maxAttempts = max(1, maxAttempts)
        self.backoff = backoff
        self.retryableStatusCodes = retryableStatusCodes
        self.retryableMethods = retryableMethods
        self.maximumServerDelay = max(0, maximumServerDelay)
        self.jitter = jitter
    }
}
