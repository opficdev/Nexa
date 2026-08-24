//
//  NXNetworkMetrics.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation

/// 하나의 `URLSession` 작업에서 발생한 네트워크 활동의 값 스냅샷입니다.
///
/// `NXURLSessionTransport`는 이 값을 `NXNetworkMetricsObserver`에 전달하기 전에 생성합니다.
/// 사용자 정의 `NXHTTPTransport` 구현은 이 값을 생성하지 않습니다.
public struct NXNetworkMetrics: Sendable, Equatable {
    /// URL 로딩 작업의 총 소요 시간입니다.
    public let taskDuration: TimeInterval?
    /// URL 로딩 작업이 따라간 리다이렉트 횟수입니다.
    public let redirectCount: Int
    /// URL 로딩 작업에서 수집한 트랜잭션 개수입니다.
    public let transactionCount: Int
    /// `URLSession`이 보고한 순서를 보존한 트랜잭션 스냅샷입니다.
    public let transactions: [NXNetworkTransactionMetrics]

    /// 네트워크 메트릭 스냅샷을 생성합니다.
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

/// 하나의 URL 로딩 트랜잭션에 대한 값 스냅샷입니다.
public struct NXNetworkTransactionMetrics: Sendable, Equatable {
    /// URLSession이 두 타임스탬프를 모두 보고한 경우의 DNS 조회 시간입니다.
    public let domainLookupDuration: TimeInterval?
    /// URLSession이 두 타임스탬프를 모두 보고한 경우 연결 시작부터 종료까지의 시간입니다.
    public let connectionDuration: TimeInterval?
    /// URLSession이 두 타임스탬프를 모두 보고한 경우 TLS 협상 시간입니다.
    public let secureConnectionDuration: TimeInterval?
    /// URLSession이 두 타임스탬프를 모두 보고한 경우 요청 시작부터 첫 바이트 응답 수신까지의 시간입니다.
    public let timeToFirstByte: TimeInterval?
    /// URLSession이 기존 연결을 재사용했는지 여부입니다.
    public let isConnectionReused: Bool

    /// 트랜잭션 메트릭 스냅샷을 생성합니다.
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
