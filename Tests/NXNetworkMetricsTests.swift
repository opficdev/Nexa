//
//  NXNetworkMetricsTests.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

@testable import Nexa
import Foundation
import Testing

@Suite("전송 metrics snapshot 테스트")
struct NXNetworkMetricsTests {
    @Test("snapshot은 transaction 순서와 구간 값을 보존한다")
    func snapshotPreservesTransactionValues() {
        let metrics = NXNetworkMetrics(source: FixtureMetricsSource(
            taskInterval: DateInterval(start: date(0), duration: 1.2),
            redirectCount: 2,
            transactions: [
                FixtureTransactionSource(
                    domainLookupStartDate: date(0),
                    domainLookupEndDate: date(0.1),
                    connectStartDate: date(0.1),
                    connectEndDate: date(0.3),
                    secureConnectionStartDate: date(0.3),
                    secureConnectionEndDate: date(0.6),
                    requestStartDate: date(0.6),
                    responseStartDate: date(1),
                    isConnectionReused: false
                ),
                FixtureTransactionSource(
                    domainLookupStartDate: date(2),
                    domainLookupEndDate: date(2.5),
                    connectStartDate: date(2.5),
                    connectEndDate: date(3.1),
                    secureConnectionStartDate: date(3.1),
                    secureConnectionEndDate: date(3.8),
                    requestStartDate: date(3.8),
                    responseStartDate: date(4.6),
                    isConnectionReused: false
                ),
                FixtureTransactionSource(
                    domainLookupStartDate: nil,
                    domainLookupEndDate: nil,
                    connectStartDate: nil,
                    connectEndDate: nil,
                    secureConnectionStartDate: nil,
                    secureConnectionEndDate: nil,
                    requestStartDate: date(5),
                    responseStartDate: date(5.2),
                    isConnectionReused: true
                )
            ]
        ))

        #expect(isApproximatelyEqual(metrics.taskDuration, to: 1.2))
        #expect(metrics.redirectCount == 2)
        #expect(metrics.transactionCount == 3)
        #expect(isApproximatelyEqual(metrics.transactions[0].domainLookupDuration, to: 0.1))
        #expect(isApproximatelyEqual(metrics.transactions[1].timeToFirstByte, to: 0.8))
        #expect(metrics.transactions[2].isConnectionReused)
    }

    @Test("불완전한 날짜 구간은 해당 duration만 nil로 표현한다")
    func incompleteSegmentsRemainNil() {
        let metrics = NXNetworkMetrics(source: FixtureMetricsSource(
            taskInterval: DateInterval(start: date(0), duration: 0.25),
            redirectCount: 0,
            transactions: [
                FixtureTransactionSource(
                    domainLookupStartDate: date(0),
                    domainLookupEndDate: nil,
                    connectStartDate: date(0),
                    connectEndDate: nil,
                    secureConnectionStartDate: date(0.1),
                    secureConnectionEndDate: date(0.15),
                    requestStartDate: date(0.15),
                    responseStartDate: date(0.25),
                    isConnectionReused: true
                )
            ]
        ))
        let transaction = metrics.transactions[0]

        #expect(transaction.domainLookupDuration == nil)
        #expect(transaction.connectionDuration == nil)
        #expect(isApproximatelyEqual(transaction.secureConnectionDuration, to: 0.05))
        #expect(isApproximatelyEqual(transaction.timeToFirstByte, to: 0.1))
        #expect(transaction.isConnectionReused)
    }

    private func date(_ seconds: TimeInterval) -> Date {
        Date(timeIntervalSinceReferenceDate: seconds)
    }

    private func isApproximatelyEqual(_ value: TimeInterval?, to expected: TimeInterval) -> Bool {
        guard let value else {
            return false
        }

        return abs(value - expected) < 0.000_000_001
    }
}

private struct FixtureMetricsSource: NXNetworkMetricsSource {
    let taskInterval: DateInterval
    let redirectCount: Int
    let transactions: [FixtureTransactionSource]
}

private struct FixtureTransactionSource: NXNetworkTransactionMetricsSource {
    let domainLookupStartDate: Date?
    let domainLookupEndDate: Date?
    let connectStartDate: Date?
    let connectEndDate: Date?
    let secureConnectionStartDate: Date?
    let secureConnectionEndDate: Date?
    let requestStartDate: Date?
    let responseStartDate: Date?
    let isConnectionReused: Bool
}
