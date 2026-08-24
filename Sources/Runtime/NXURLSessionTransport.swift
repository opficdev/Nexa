//
//  NXURLSessionTransport.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// `URLSession` 기반 기본 HTTP 전송 계층입니다.
public struct NXURLSessionTransport: NXHTTPTransport, Sendable {
    let urlSession: URLSession
    let metricsObserver: (any NXNetworkMetricsObserver)?

    /// 메트릭을 수집하지 않고 `URLSession`으로 요청을 전송하는 전송 계층을 생성합니다.
    ///
    /// - Parameter urlSession: 요청을 실행할 세션입니다.
    public init(urlSession: URLSession = .shared) {
        self.urlSession = urlSession
        metricsObserver = nil
    }

    /// `URLSession`으로 요청을 전송하고 메트릭 스냅샷을 기록하는 전송 계층을 생성합니다.
    ///
    /// - Parameter urlSession: 요청을 실행할 세션입니다.
    /// - Parameter metricsObserver: `URLSession` 메트릭 스냅샷을 수신하는 옵저버입니다.
    public init(
        urlSession: URLSession = .shared,
        metricsObserver: any NXNetworkMetricsObserver
    ) {
        self.urlSession = urlSession
        self.metricsObserver = metricsObserver
    }

    /// 준비된 요청을 내부 `URLSession`으로 전송합니다.
    ///
    /// - Parameter request: 실행할 준비된 요청입니다.
    /// - Returns: 원시 응답 데이터와 HTTP 메타데이터입니다.
    public func send(_ request: URLRequest) async throws -> NXRawResponse {
        let metricsDelegate = metricsObserver.map(NXURLSessionTaskMetricsDelegate.init)
        let (data, response) = try await urlSession.data(for: request, delegate: metricsDelegate)

        guard let httpURLResponse = response as? HTTPURLResponse else {
            throw NXError.invalidRequest("Non-HTTP response")
        }

        return NXRawResponse(data: data, response: httpURLResponse)
    }
}
