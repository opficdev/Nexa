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

    // URLSession task 측정값을 Nexa snapshot으로 전달하는 delegate 메서드
    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didFinishCollecting metrics: URLSessionTaskMetrics
    ) {
        let source = NXURLSessionTaskMetricsSource(metrics: metrics)
        let snapshot = NXNetworkMetrics(source: source)

        Task { [metricsObserver] in
            await metricsObserver.record(snapshot)
        }
    }
}

private struct NXURLSessionTaskMetricsSource: NXNetworkMetricsSource {
    let taskInterval: DateInterval
    let redirectCount: Int
    let transactions: [NXURLSessionTaskTransactionMetricsSource]

    // URLSession task 측정값에서 전송 snapshot source를 구성하는 initializer
    init(metrics: URLSessionTaskMetrics) {
        taskInterval = metrics.taskInterval
        redirectCount = metrics.redirectCount
        transactions = metrics.transactionMetrics.map(NXURLSessionTaskTransactionMetricsSource.init)
    }
}

private struct NXURLSessionTaskTransactionMetricsSource: NXNetworkTransactionMetricsSource {
    let domainLookupStartDate: Date?
    let domainLookupEndDate: Date?
    let connectStartDate: Date?
    let connectEndDate: Date?
    let secureConnectionStartDate: Date?
    let secureConnectionEndDate: Date?
    let requestStartDate: Date?
    let responseStartDate: Date?
    let isConnectionReused: Bool

    // URLSession transaction 측정값에서 transaction snapshot source를 구성하는 initializer
    init(metrics: URLSessionTaskTransactionMetrics) {
        domainLookupStartDate = metrics.domainLookupStartDate
        domainLookupEndDate = metrics.domainLookupEndDate
        connectStartDate = metrics.connectStartDate
        connectEndDate = metrics.connectEndDate
        secureConnectionStartDate = metrics.secureConnectionStartDate
        secureConnectionEndDate = metrics.secureConnectionEndDate
        requestStartDate = metrics.requestStartDate
        responseStartDate = metrics.responseStartDate
        isConnectionReused = metrics.isReusedConnection
    }
}
