//
//  NXNetworkMetricsObserver.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

/// `NXURLSessionTransport`에서 수집한 메트릭 스냅샷을 수신합니다.
///
/// 메트릭 전달은 요청 완료와 로거 이벤트 순서와 독립적으로 수행됩니다.
public protocol NXNetworkMetricsObserver: Sendable {
    /// 네트워크 메트릭 스냅샷을 한 건 기록합니다.
    func record(_ metrics: NXNetworkMetrics) async
}
