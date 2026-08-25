//
//  NXURLSessionTransport.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// `URLSession` 기반 기본 HTTP transport
public struct NXURLSessionTransport: NXHTTPTransport, Sendable {
    let urlSession: URLSession
    let metricsObserver: (any NXNetworkMetricsObserver)?

    /// `URLSession` transport만 수행하는 metrics 비수집 transport 생성
    ///
    /// - Parameter urlSession: 요청 실행 세션
    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        metricsObserver = nil
    }

    /// `URLSession` transport 및 metrics snapshot 기록 지원 transport 생성
    ///
    /// - Parameter urlSession: 요청 실행 세션
    /// - Parameter metricsObserver: `URLSession` metrics snapshot 수신 observer
    public init(
        urlSession: URLSession = .shared,
        metricsObserver: any NXNetworkMetricsObserver
    ) {
        self.urlSession = urlSession
        self.metricsObserver = metricsObserver
    }

    /// 준비된 요청 내부 `URLSession` transport
    ///
    /// - Parameter request: 실행 준비 요청
    /// - Returns: `NXRawResponse`의 응답 data와 HTTP metadata
    public func send(_ request: URLRequest) async throws -> NXRawResponse {
        let metricsDelegate = metricsObserver.map(NXURLSessionTaskMetricsDelegate.init)
        let (data, response) = try await urlSession.data(for: request, delegate: metricsDelegate)

        guard let httpURLResponse = response as? HTTPURLResponse else {
            throw NXError.invalidRequest("Non-HTTP response")
        }

        return NXRawResponse(data: data, response: httpURLResponse)
    }
}
