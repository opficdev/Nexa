//
//  NXNetworkMetricsObserver.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

/// `NXURLSessionTransport` 수집 metrics snapshot 수신 대상
///
/// 요청 완료 및 logger event 순서와 독립적 metrics 전달
public protocol NXNetworkMetricsObserver: Sendable {
    /// 네트워크 metrics snapshot 단건 기록
    func record(_ metrics: NXNetworkMetrics) async
}
