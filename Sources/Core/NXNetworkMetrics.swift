//
//  NXNetworkMetrics.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation

/// `URLSession` task 기반 네트워크 활동 값 snapshot
///
/// `NXURLSessionTransport`는 `NXNetworkMetricsObserver` 전달 전 snapshot 생성
/// 사용자 정의 `NXHTTPTransport` 구현은 snapshot 미생성
public struct NXNetworkMetrics: Sendable, Equatable {
    /// URL loading task 총 소요 시간
    public let taskDuration: TimeInterval?
    /// URL loading task redirect 횟수
    public let redirectCount: Int
    /// URL loading task 수집 transaction 개수
    public let transactionCount: Int
    /// `URLSession` 보고 순서 보존 transaction snapshot
    public let transactions: [NXNetworkTransactionMetrics]

    /// 네트워크 metrics snapshot 생성
    public init(
        taskDuration: TimeInterval?,
        redirectCount: Int,
        transactionCount: Int,
        transactions: [NXNetworkTransactionMetrics]
    ) {
        self.taskDuration = taskDuration
        self.redirectCount = redirectCount
        self.transactionCount = transactionCount
        self.transactions = transactions
    }
}

/// 단일 URL loading transaction 값 snapshot
public struct NXNetworkTransactionMetrics: Sendable, Equatable {
    /// `URLSession` 시작·종료 timestamp 제공 시 DNS 조회 시간
    public let domainLookupDuration: TimeInterval?
    /// `URLSession` 시작·종료 timestamp 제공 시 연결 시작부터 종료까지의 시간
    public let connectionDuration: TimeInterval?
    /// `URLSession` 시작·종료 timestamp 제공 시 TLS 협상 시간
    public let secureConnectionDuration: TimeInterval?
    /// `URLSession` 시작·종료 timestamp 제공 시 요청 시작부터 첫 응답 byte 수신까지의 시간
    public let timeToFirstByte: TimeInterval?
    /// 기존 연결 재사용 여부
    public let isConnectionReused: Bool

    /// transaction metrics snapshot 생성
    public init(
        domainLookupDuration: TimeInterval?,
        connectionDuration: TimeInterval?,
        secureConnectionDuration: TimeInterval?,
        timeToFirstByte: TimeInterval?,
        isConnectionReused: Bool
    ) {
        self.domainLookupDuration = domainLookupDuration
        self.connectionDuration = connectionDuration
        self.secureConnectionDuration = secureConnectionDuration
        self.timeToFirstByte = timeToFirstByte
        self.isConnectionReused = isConnectionReused
    }
}

protocol NXNetworkMetricsSource {
    associatedtype Transaction: NXNetworkTransactionMetricsSource

    var taskInterval: DateInterval { get }
    var redirectCount: Int { get }
    var transactions: [Transaction] { get }
}

protocol NXNetworkTransactionMetricsSource {
    var domainLookupStartDate: Date? { get }
    var domainLookupEndDate: Date? { get }
    var connectStartDate: Date? { get }
    var connectEndDate: Date? { get }
    var secureConnectionStartDate: Date? { get }
    var secureConnectionEndDate: Date? { get }
    var requestStartDate: Date? { get }
    var responseStartDate: Date? { get }
    var isConnectionReused: Bool { get }
}

extension NXNetworkMetrics {
    init<Source: NXNetworkMetricsSource>(source: Source) {
        let transactions = source.transactions.map { transaction in
            NXNetworkTransactionMetrics(
                domainLookupDuration: Self.duration(
                    from: transaction.domainLookupStartDate,
                    to: transaction.domainLookupEndDate
                ),
                connectionDuration: Self.duration(
                    from: transaction.connectStartDate,
                    to: transaction.connectEndDate
                ),
                secureConnectionDuration: Self.duration(
                    from: transaction.secureConnectionStartDate,
                    to: transaction.secureConnectionEndDate
                ),
                timeToFirstByte: Self.duration(
                    from: transaction.requestStartDate,
                    to: transaction.responseStartDate
                ),
                isConnectionReused: transaction.isConnectionReused
            )
        }

        self.init(
            taskDuration: source.taskInterval.duration,
            redirectCount: source.redirectCount,
            transactionCount: transactions.count,
            transactions: transactions
        )
    }

    private static func duration(from startDate: Date?, to endDate: Date?) -> TimeInterval? {
        guard let startDate, let endDate else {
            return nil
        }

        return endDate.timeIntervalSince(startDate)
    }
}
