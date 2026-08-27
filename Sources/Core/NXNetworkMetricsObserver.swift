//
//  NXNetworkMetricsObserver.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

/// `NXURLSessionTransport`가 수집한 측정값 스냅샷을 받는 대상
///
/// 요청 완료 및 로거 이벤트 순서와 관계없이 측정값 전달
public protocol NXNetworkMetricsObserver: Sendable {
    /// 네트워크 측정값 스냅샷 하나 기록
    func record(_ metrics: NXNetworkMetrics) async
}
