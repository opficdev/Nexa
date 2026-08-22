//
//  NXRetryExecutionDependencies.swift
//  Nexa
//
//  Created by opfic on 8/22/26.
//

import Foundation

struct NXRetryExecutionDependencies: Sendable {
    let now: @Sendable () -> Date
    let sleep: @Sendable (TimeInterval) async throws -> Void
    let randomUnit: @Sendable () -> Double

    static let live = Self(
        now: { Date() },
        sleep: { delay in
            guard 0 < delay else {
                return
            }

            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        },
        randomUnit: { Double.random(in: 0...1) }
    )
}
