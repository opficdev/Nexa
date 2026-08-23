//
//  NXURLSessionTaskMetricsDelegate.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation

final class NXURLSessionTaskMetricsDelegate: NSObject, URLSessionTaskDelegate {
    private let metricsObserver: any NXNetworkMetricsObserver

    init(metricsObserver: any NXNetworkMetricsObserver) {
        self.metricsObserver = metricsObserver
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didFinishCollecting metrics: URLSessionTaskMetrics
    ) {
        let snapshot = NXNetworkMetrics(metrics: metrics)

        Task { [metricsObserver] in
            await metricsObserver.record(snapshot)
        }
    }
}

private extension NXNetworkMetrics {
    init(metrics: URLSessionTaskMetrics) {
        let transactions = metrics.transactionMetrics.map { transaction in
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
                isConnectionReused: transaction.isReusedConnection
            )
        }

        self.init(
            taskDuration: metrics.taskInterval.duration,
            redirectCount: metrics.redirectCount,
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
