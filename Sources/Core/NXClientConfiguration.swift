//
//  NXClientConfiguration.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// API client가 생성하는 모든 요청의 공통 설정
///
/// ## 개요
///
/// 공통 네트워크 동작의 단일 정의 지점, `NXAPIClient` 통한 재사용
///
/// ```swift
/// import Foundation
/// import Nexa
///
/// let configuration = NXClientConfiguration(
///     baseURL: URL(string: "https://api.example.com")!,
///     headers: [
///         "Accept": "application/json"
///     ],
///     transport: NXURLSessionTransport(),
///     logger: NXNoopLogger(),
///     interceptors: []
/// )
///
/// let client = NXAPIClient(configuration: configuration)
/// ```
public struct NXClientConfiguration: Sendable {
    /// 상대 경로 요청 해석 기본 URL
    public let baseURL: URL
    /// 모든 요청 공통 header(키 충돌 시 요청 단위 header 우선 적용)
    public let headers: [String: String]
    /// 조립된 `URLRequest` 실행 transport
    public let transport: any NXHTTPTransport
    /// 요청 lifecycle event 수신 logger
    public let logger: any NXLogger
    /// 요청별 적용 interceptor
    public let interceptors: [any NXHTTPInterceptor]
    /// 성공한 GET 응답 및 진행 중 동일 요청의 cache 동작
    public let cache: NXCache
    /// type 지정 요청 응답 body decoder
    public let decoder: JSONDecoder
    /// `json(_:encoder:)` 미전달 시 사용 JSON 요청 body encoder
    public let encoder: JSONEncoder
    /// 실패한 서버 응답을 도메인 전용 오류로 mapping하는 decoder
    public let serverErrorDecoder: any NXServerErrorDecoder
    /// 인증 요청에서 베어러 토큰 조회 및 갱신 provider
    public let authTokenProvider: (any NXAuthTokenProvider)?

    /// client 구성 initialization
    ///
    /// - Parameters:
    ///   - baseURL: 상대 경로 요청 해석 기본 URL
    ///   - headers: 모든 요청 공통 header(키 충돌 시 요청 단위 header 우선 적용)
    ///   - transport: 요청 실행 transport
    ///   - logger: 요청 lifecycle event 수신 logger
    ///   - interceptors: 요청 적용 interceptor 목록
    ///   - cache: 성공한 GET 응답 및 진행 중 동일 요청의 cache 동작
    ///   - decoder: type 지정 응답 decoding decoder
    ///   - encoder: JSON 요청 body encoder
    ///   - serverErrorDecoder: 실패 응답 사용자 정의 오류 mapping decoder
    ///   - authTokenProvider: 인증 요청용 token provider
    public init(
        baseURL: URL,
        headers: [String: String] = [:],
        transport: any NXHTTPTransport = NXURLSessionTransport(),
        logger: any NXLogger = NXNoopLogger(),
        interceptors: [any NXHTTPInterceptor] = [],
        cache: NXCache = .disabled,
        decoder: JSONDecoder = JSONDecoder(),
        encoder: JSONEncoder = JSONEncoder(),
        serverErrorDecoder: any NXServerErrorDecoder = NXDefaultServerErrorDecoder(),
        authTokenProvider: (any NXAuthTokenProvider)? = nil
    ) {
        self.baseURL = baseURL
        self.headers = headers
        self.transport = transport
        self.logger = logger
        self.interceptors = interceptors
        self.cache = cache
        self.decoder = decoder
        self.encoder = encoder
        self.serverErrorDecoder = serverErrorDecoder
        self.authTokenProvider = authTokenProvider
    }
}
