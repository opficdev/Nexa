//
//  NXNetworkMetrics.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation

/// Value snapshot of one `URLSession` task's network activity.
///
/// `NXURLSessionTransport` creates this value before delivering it to an `NXNetworkMetricsObserver`.
/// Custom `NXHTTPTransport` implementations do not produce this value.
public struct NXNetworkMetrics: Sendable, Equatable {
    /// Total duration of the URL loading task.
    public let taskDuration: TimeInterval?
    /// Number of redirects followed by the URL loading task.
    public let redirectCount: Int
    /// Number of transactions collected for the URL loading task.
    public let transactionCount: Int
    /// Transaction snapshots in the order reported by `URLSession`.
    public let transactions: [NXNetworkTransactionMetrics]

    /// Creates a network metrics snapshot.
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

/// Value snapshot of one URL loading transaction.
public struct NXNetworkTransactionMetrics: Sendable, Equatable {
    /// Duration of DNS lookup when URLSession reports both timestamps.
    public let domainLookupDuration: TimeInterval?
    /// Duration from connection start through connection end when URLSession reports both timestamps.
    public let connectionDuration: TimeInterval?
    /// Duration of TLS negotiation when URLSession reports both timestamps.
    public let secureConnectionDuration: TimeInterval?
    /// Duration from request start until the first response byte when URLSession reports both timestamps.
    public let timeToFirstByte: TimeInterval?
    /// Whether URLSession reused an existing connection.
    public let isConnectionReused: Bool

    /// Creates a transaction metrics snapshot.
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
