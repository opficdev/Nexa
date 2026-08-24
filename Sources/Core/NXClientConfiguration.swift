//
//  NXClientConfiguration.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// API 클라이언트가 생성하는 모든 요청에 적용되는 공통 설정입니다.
///
/// ## 개요
///
/// 공통 네트워킹 동작을 한 곳에 정의하고 `NXAPIClient`를 통해 재사용하세요.
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
    /// 상대 경로 요청을 해석할 때 사용하는 기본 URL입니다.
    public let baseURL: URL
    /// 모든 요청에 추가되는 헤더입니다. 요청 수준에서 키가 겹치면 해당 헤더로 덮어씁니다.
    public let headers: [String: String]
    /// 조립된 `URLRequest` 실행에 사용하는 전송 계층입니다.
    public let transport: any NXHTTPTransport
    /// 요청 라이프사이클 이벤트를 수신하는 로거입니다.
    public let logger: any NXLogger
    /// 모든 요청에 적용되는 인터셉터입니다.
    public let interceptors: [any NXHTTPInterceptor]
    /// 성공한 GET 응답과 진행 중인 동일 요청에 대한 캐시 동작입니다.
    public let cache: NXCache
    /// 타입 지정 요청에서 응답 본문을 디코딩할 때 사용하는 디코더입니다.
    public let decoder: JSONDecoder
    /// `json(_:encoder:)`에 인코더가 전달되지 않을 때 JSON 요청 본문을 만드는 인코더입니다.
    public let encoder: JSONEncoder
    /// 실패한 서버 응답을 도메인 전용 오류로 매핑할 수 있는 디코더입니다.
    public let serverErrorDecoder: any NXServerErrorDecoder
    /// 인증 요청에서 베어러 토큰을 조회하고 갱신하는 데 사용하는 공급자입니다.
    public let authTokenProvider: (any NXAuthTokenProvider)?

    /// 클라이언트 구성을 생성합니다.
    ///
    /// - Parameters:
    ///   - baseURL: 상대 경로 요청을 해석할 때 사용하는 기본 URL입니다.
    ///   - headers: 모든 요청에 추가되는 헤더입니다.
    ///   - transport: 요청 실행을 담당하는 전송 계층입니다.
    ///   - logger: 요청 라이프사이클 이벤트를 받는 로거입니다.
    ///   - interceptors: 모든 요청에 적용되는 인터셉터 목록입니다.
    ///   - cache: 성공한 GET 응답 및 진행 중인 동일 요청에 대한 캐시 동작입니다.
    ///   - decoder: 타입 지정 응답 디코딩에 사용하는 디코더입니다.
    ///   - encoder: JSON 요청 본문 인코딩에 사용하는 인코더입니다.
    ///   - serverErrorDecoder: 실패 응답을 커스텀 오류로 매핑하는 디코더입니다.
    ///   - authTokenProvider: 인증 요청에 사용되는 공급자입니다.
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
