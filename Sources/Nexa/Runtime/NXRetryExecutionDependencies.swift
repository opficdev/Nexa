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
            let nanoseconds = Self.nanoseconds(for: delay)

            guard 0 < nanoseconds else {
                return
            }

            try await Task.sleep(nanoseconds: nanoseconds)
        },
        randomUnit: { Double.random(in: 0...1) }
    )

    static func nanoseconds(for delay: TimeInterval) -> UInt64 {
        guard 0 < delay else {
            return 0
        }

        guard delay.isFinite else {
            return .max
        }

        let maximumSeconds = TimeInterval(UInt64.max / 1_000_000_000)

        guard delay <= maximumSeconds else {
            return .max
        }

        return UInt64(delay * 1_000_000_000)
    }
}
