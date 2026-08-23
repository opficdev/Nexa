//
//  NXRetryExecutionDependenciesTests.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("재시도 대기 시간 변환 테스트")
struct NXRetryExecutionDependenciesTests {
    @Test("일반 지연을 nanoseconds로 변환한다")
    func convertsFiniteDelayToNanoseconds() {
        #expect(NXRetryExecutionDependencies.nanoseconds(for: 1.5) == 1_500_000_000)
    }

    @Test("매우 큰 지연과 infinity를 최대 nanoseconds로 제한한다", arguments: [
        TimeInterval.greatestFiniteMagnitude,
        .infinity
    ])
    func capsUnrepresentableDelayToMaximumNanoseconds(delay: TimeInterval) {
        #expect(NXRetryExecutionDependencies.nanoseconds(for: delay) == .max)
    }

    @Test("0 이하 지연은 대기하지 않는다", arguments: [0, -1])
    func convertsNonPositiveDelayToZeroNanoseconds(delay: TimeInterval) {
        #expect(NXRetryExecutionDependencies.nanoseconds(for: delay) == 0)
    }
}
