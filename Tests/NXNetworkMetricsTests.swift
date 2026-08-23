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
        let transactions = [
            NXNetworkTransactionMetrics(
                domainLookupDuration: 0.1,
                connectionDuration: 0.2,
                secureConnectionDuration: 0.3,
                timeToFirstByte: 0.4,
                isConnectionReused: false
            ),
            NXNetworkTransactionMetrics(
                domainLookupDuration: 0.5,
                connectionDuration: 0.6,
                secureConnectionDuration: 0.7,
                timeToFirstByte: 0.8,
                isConnectionReused: false
            ),
            NXNetworkTransactionMetrics(
                domainLookupDuration: nil,
                connectionDuration: nil,
                secureConnectionDuration: nil,
                timeToFirstByte: 0.2,
                isConnectionReused: true
            )
        ]
        let metrics = NXNetworkMetrics(
            taskDuration: 1.2,
            redirectCount: 2,
            transactionCount: transactions.count,
            transactions: transactions
        )

        #expect(metrics.taskDuration == 1.2)
        #expect(metrics.redirectCount == 2)
        #expect(metrics.transactionCount == 3)
        #expect(metrics.transactions[0].domainLookupDuration == 0.1)
        #expect(metrics.transactions[1].timeToFirstByte == 0.8)
        #expect(metrics.transactions[2].isConnectionReused)
    }

    @Test("불완전한 날짜 구간은 해당 duration만 nil로 표현한다")
    func incompleteSegmentsRemainNil() {
        let transaction = NXNetworkTransactionMetrics(
            domainLookupDuration: nil,
            connectionDuration: nil,
            secureConnectionDuration: 0.05,
            timeToFirstByte: 0.1,
            isConnectionReused: true
        )

        #expect(transaction.domainLookupDuration == nil)
        #expect(transaction.connectionDuration == nil)
        #expect(transaction.secureConnectionDuration == 0.05)
        #expect(transaction.timeToFirstByte == 0.1)
        #expect(transaction.isConnectionReused)
    }
}
