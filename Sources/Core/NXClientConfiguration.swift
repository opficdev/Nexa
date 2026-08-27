//
//  NXClientConfiguration.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// API 클라이언트가 생성하는 모든 요청의 공통 설정
///
/// ## 개요
///
/// 공통 네트워크 동작을 한 곳에서 정의하고 `NXAPIClient`를 통해 재사용
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
    /// 모든 요청의 공통 헤더(키 충돌 시 요청 단위 헤더 우선 적용)
    public let headers: [String: String]
    /// 조립된 `URLRequest`를 실행하는 전송
    public let transport: any NXHTTPTransport
    /// 요청 생명주기 이벤트를 받는 로거
    public let logger: any NXLogger
    /// 요청별로 적용할 인터셉터
    public let interceptors: [any NXHTTPInterceptor]
    /// 성공한 GET 응답 및 진행 중 동일 요청의 캐시 동작
    public let cache: NXCache
    /// 타입을 지정한 요청의 응답 본문 디코더
    public let decoder: JSONDecoder
    /// `json(_:encoder:)`를 전달하지 않았을 때 사용할 JSON 요청 본문 인코더
    public let encoder: JSONEncoder
    /// 실패한 서버 응답을 도메인 전용 오류로 매핑하는 디코더
    public let serverErrorDecoder: any NXServerErrorDecoder
    /// 인증 요청에서 Bearer 토큰을 조회하고 갱신하는 제공자
    public let authTokenProvider: (any NXAuthTokenProvider)?

    /// 클라이언트 구성 초기화
    ///
    /// - Parameters:
    ///   - baseURL: 상대 경로 요청 해석 기본 URL
    ///   - headers: 모든 요청의 공통 헤더(키 충돌 시 요청 단위 헤더 우선 적용)
    ///   - transport: 요청을 실행하는 전송
    ///   - logger: 요청 생명주기 이벤트를 받는 로거
    ///   - interceptors: 요청에 적용할 인터셉터 목록
    ///   - cache: 성공한 GET 응답 및 진행 중 동일 요청의 캐시 동작
    ///   - decoder: 타입을 지정한 응답을 디코딩하는 디코더
    ///   - encoder: JSON 요청 본문 인코더
    ///   - serverErrorDecoder: 실패 응답을 사용자 정의 오류로 매핑하는 디코더
    ///   - authTokenProvider: 인증 요청용 토큰 제공자
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
