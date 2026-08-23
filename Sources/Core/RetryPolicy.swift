//
//  RetryPolicy.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation

struct RetryPolicy: Sendable {
    let maxAttempts: Int
    let backoff: NXRetryBackoff
    let retryableStatusCodes: Set<Int>
    let allowedMethods: Set<NXHTTPMethod>
    let maximumServerDelay: TimeInterval
    let jitter: NXRetryJitter

    init(
        maxAttempts: Int,
        backoff: NXRetryBackoff = .fixed(0),
        retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504],
        allowing: Set<NXHTTPMethod> = [],
        maximumServerDelay: TimeInterval = 60,
        jitter: NXRetryJitter = .none
    ) {
        self.maxAttempts = max(1, maxAttempts)
        self.backoff = backoff
        self.retryableStatusCodes = retryableStatusCodes
        var allowedMethods: Set<NXHTTPMethod> = [.get, .head, .put, .delete, .options]
        allowedMethods.formUnion(allowing)
        self.allowedMethods = allowedMethods
        self.maximumServerDelay = max(0, maximumServerDelay)
        self.jitter = jitter
    }

    init(_ policy: NXRetryPolicy) {
        maxAttempts = policy.maxAttempts
        backoff = switch policy.backoff {
        case let .fixed(seconds):
            .fixed(seconds)
        case let .exponential(base, maxDelay):
            .exponential(base: base, maxDelay: maxDelay)
        }
        retryableStatusCodes = policy.retryableStatusCodes
        allowedMethods = policy.retryableMethods
        maximumServerDelay = policy.maximumServerDelay
        jitter = switch policy.jitter {
        case .none:
            .none
        case .full:
            .full
        }
    }
}
