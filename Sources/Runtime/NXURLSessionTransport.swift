//
//  NXURLSessionTransport.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// `URLSession` 기반 기본 HTTP 전송
public struct NXURLSessionTransport: NXHTTPTransport, Sendable {
    let urlSession: URLSession
    let metricsObserver: (any NXNetworkMetricsObserver)?

    /// `URLSession` 전송만 수행하고 측정값을 수집하지 않는 전송 생성
    ///
    /// - Parameter urlSession: 요청 실행 세션
    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        metricsObserver = nil
    }

    /// `URLSession` 전송과 측정값 스냅샷 기록을 지원하는 전송 생성
    ///
    /// - Parameter urlSession: 요청 실행 세션
    /// - Parameter metricsObserver: `URLSession` 측정값 스냅샷을 받는 관측자
    public init(
        urlSession: URLSession = .shared,
        metricsObserver: any NXNetworkMetricsObserver
    ) {
        self.urlSession = urlSession
        self.metricsObserver = metricsObserver
    }

    /// 준비된 요청을 내부 `URLSession`으로 전송
    ///
    /// - Parameter request: 실행 준비 요청
    /// - Returns: `NXRawResponse`의 응답 데이터와 HTTP 메타데이터
    public func send(_ request: URLRequest) async throws -> NXRawResponse {
        let metricsDelegate = metricsObserver.map(NXURLSessionTaskMetricsDelegate.init)
        let (data, response) = try await urlSession.data(for: request, delegate: metricsDelegate)

        guard let httpURLResponse = response as? HTTPURLResponse else {
            throw NXError.invalidRequest("Non-HTTP response")
        }

        return NXRawResponse(data: data, response: httpURLResponse)
    }
}
