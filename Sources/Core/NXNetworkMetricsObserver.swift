//
//  NXNetworkMetricsObserver.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

/// Receives metrics snapshots collected by `NXURLSessionTransport`.
///
/// Metrics delivery is independent of request completion and logger event order.
public protocol NXNetworkMetricsObserver: Sendable {
    /// Records one network metrics snapshot.
    func record(_ metrics: NXNetworkMetrics) async
}
