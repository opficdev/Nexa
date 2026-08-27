//
//  NXAPIClient.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation

/// 단일 클라이언트 설정을 기반으로 HTTP 요청을 구성하고 전송하는 공용 진입점
///
/// ## 개요
///
/// 클라이언트를 한 번 생성한 뒤 상대 경로나 스킴을 포함한 절대 URL 문자열로 요청 시작
///
/// 절대 URL 문자열은 기본 URL을 대체하지만 클라이언트 공통 헤더, 인터셉터, 인증 정책은 유지
/// 인증이나 민감한 헤더가 설정된 클라이언트에서는 신뢰하는 호스트에만 절대 URL 사용
///
/// 캐시 사용 시 각 `NXAPIClient` 초기화마다 독립된 메모리 캐시와 진행 중 요청 저장소 생성. 캐시 응답 공유는 서비스 또는 의존성 주입 계층에서 클라이언트를 재사용해 보장. 동일한 클라이언트 값의 복사본은 같은 저장소 유지
///
/// ```swift
/// import Foundation
/// import Nexa
///
/// struct User: Decodable {
///     let id: Int
///     let name: String
/// }
///
/// let client = NXAPIClient(
///     configuration: NXClientConfiguration(
///         baseURL: URL(string: "https://api.example.com")!
///     )
/// )
///
/// let user = try await client
///     .get("/users/me")
///     .send(as: User.self)
/// ```
///
/// 직접 요청은 메서드 기반 빌더 경로를 사용하고 `NXEndpoint`는 타입 지정 빌더 구성 계약의 소스 호환성 유지
public struct NXAPIClient: Sendable {
    private let configuration: NXClientConfiguration
    private let responseCacheStore: NXResponseCacheStore?
    private let authRefreshCoordinator: NXAuthRefreshCoordinator

    /// 모든 요청의 공통 설정을 반영한 클라이언트 생성
    ///
    /// - Parameter configuration: 기본 URL, 전송, 로거, `NXAuthTokenProvider` 같은 공용 설정
    public init(configuration: NXClientConfiguration) {
        self.init(
            configuration: configuration,
            onWaiterRegistered: nil,
            onRefreshCompleted: nil
        )
    }

    init(
        configuration: NXClientConfiguration,
        onWaiterRegistered: (@Sendable () -> Void)?,
        onRefreshCompleted: (@Sendable () -> Void)?
    ) {
        self.configuration = configuration
        authRefreshCoordinator = NXAuthRefreshCoordinator(
            onWaiterRegistered: onWaiterRegistered,
            onRefreshCompleted: onRefreshCompleted
        )
        responseCacheStore = switch configuration.cache {
        case .disabled:
            nil
        case .memory, .revalidatingMemory:
            NXResponseCacheStore()
        }
    }

    /// 지정 경로를 기준으로 타입을 지정하지 않은 `GET` 요청 빌더 생성
    ///
    /// - Parameter path: 설정된 기본 URL을 기준으로 하는 상대 경로 또는 스킴을 포함한 절대 URL 문자열
    ///   빈 값은 기본 URL 경로 유지
    /// - Returns: 전송 전에 추가로 설정할 수 있는 요청 빌더
    public func get(_ path: String = "") -> NXRequestBuilder {
        request(method: .get, path: path)
    }

    /// 지정 경로를 기준으로 타입을 지정한 `GET` 요청 빌더 생성
    ///
    /// - Parameters:
    ///   - path: 설정된 기본 URL을 기준으로 하는 상대 경로 또는 스킴을 포함한 절대 URL 문자열. 빈 값은 기본 URL 경로 유지
    ///   - type: 성공 응답 디코딩 대상 타입
    /// - Returns: `Response` 디코딩 타입을 지정한 요청 빌더
    @available(*, deprecated, message: "Use get(_:) followed by send(as:).")
    public func get<Response: Decodable>(
        _ path: String = "",
        as type: Response.Type
    ) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .get, path: path)
    }

    /// 지정 경로를 기준으로 타입을 지정하지 않은 `POST` 요청 빌더 생성
    ///
    /// - Parameter path: 설정된 기본 URL을 기준으로 하는 상대 경로 또는 스킴을 포함한 절대 URL 문자열
    /// - Returns: 전송 전에 추가로 설정할 수 있는 요청 빌더
    public func post(_ path: String) -> NXRequestBuilder {
        request(method: .post, path: path)
    }

    /// 지정 경로를 기준으로 타입을 지정한 `POST` 요청 빌더 생성
    ///
    /// - Parameters:
    ///   - path: 설정된 기본 URL을 기준으로 하는 상대 경로 또는 스킴을 포함한 절대 URL 문자열
    ///   - type: 성공 응답 디코딩 대상 타입
    /// - Returns: `Response` 디코딩 타입을 지정한 요청 빌더
    @available(*, deprecated, message: "Use post(_:) followed by send(as:).")
    public func post<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .post, path: path)
    }

    /// 지정 경로를 기준으로 타입을 지정하지 않은 `PUT` 요청 빌더 생성
    ///
    /// - Parameter path: 설정된 기본 URL을 기준으로 하는 상대 경로 또는 스킴을 포함한 절대 URL 문자열
    /// - Returns: 전송 전에 추가로 설정할 수 있는 요청 빌더
    public func put(_ path: String) -> NXRequestBuilder {
        request(method: .put, path: path)
    }

    /// 지정 경로를 기준으로 타입을 지정한 `PUT` 요청 빌더 생성
    ///
    /// - Parameters:
    ///   - path: 설정된 기본 URL을 기준으로 하는 상대 경로 또는 스킴을 포함한 절대 URL 문자열
    ///   - type: 성공 응답 디코딩 대상 타입
    /// - Returns: `Response` 디코딩 타입을 지정한 요청 빌더
    @available(*, deprecated, message: "Use put(_:) followed by send(as:).")
    public func put<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .put, path: path)
    }

    /// 지정 경로를 기준으로 타입을 지정하지 않은 `PATCH` 요청 빌더 생성
    ///
    /// - Parameter path: 설정된 기본 URL을 기준으로 하는 상대 경로 또는 스킴을 포함한 절대 URL 문자열
    /// - Returns: 전송 전에 추가로 설정할 수 있는 요청 빌더
    public func patch(_ path: String) -> NXRequestBuilder {
        request(method: .patch, path: path)
    }

    /// 지정 경로를 기준으로 타입을 지정한 `PATCH` 요청 빌더 생성
    ///
    /// - Parameters:
    ///   - path: 설정된 기본 URL을 기준으로 하는 상대 경로 또는 스킴을 포함한 절대 URL 문자열
    ///   - type: 성공 응답 디코딩 대상 타입
    /// - Returns: `Response` 디코딩 타입을 지정한 요청 빌더
    @available(*, deprecated, message: "Use patch(_:) followed by send(as:).")
    public func patch<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .patch, path: path)
    }

    /// 지정 경로를 기준으로 타입을 지정하지 않은 `DELETE` 요청 빌더 생성
    ///
    /// - Parameter path: 설정된 기본 URL을 기준으로 하는 상대 경로 또는 스킴을 포함한 절대 URL 문자열
    /// - Returns: 전송 전에 추가로 설정할 수 있는 요청 빌더
    public func delete(_ path: String) -> NXRequestBuilder {
        request(method: .delete, path: path)
    }

    /// 지정 경로를 기준으로 타입을 지정한 `DELETE` 요청 빌더 생성
    ///
    /// - Parameters:
    ///   - path: 설정된 기본 URL을 기준으로 하는 상대 경로 또는 스킴을 포함한 절대 URL 문자열
    ///   - type: 성공 응답 디코딩 대상 타입
    /// - Returns: `Response` 디코딩 타입을 지정한 요청 빌더
    @available(*, deprecated, message: "Use delete(_:) followed by send(as:).")
    public func delete<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .delete, path: path)
    }

    /// 엔드포인트에서 타입을 지정한 요청 구성
    ///
    /// - Parameter endpoint: HTTP 메서드, 경로, 선택적 요청 설정을 정의한 엔드포인트
    /// - Returns: 엔드포인트 기반 타입 지정 요청 빌더
    public func request<E: NXEndpoint>(_ endpoint: E) -> NXTypedRequestBuilder<E.Response> {
        endpoint.configure(typedRequest(method: endpoint.method, path: endpoint.path))
    }

    /// 엔드포인트 요청 전송 및 응답 디코딩
    ///
    /// - Parameter endpoint: 요청 동작을 정의한 엔드포인트
    /// - Returns: 엔드포인트 응답 디코딩 결과
    public func send<E: NXEndpoint>(_ endpoint: E) async throws -> E.Response {
        try await request(endpoint).requestBuilder.send(as: E.Response.self)
    }

    func request(method: NXHTTPMethod, path: String) -> NXRequestBuilder {
        NXRequestBuilder(
            clientConfiguration: configuration,
            responseCacheStore: responseCacheStore,
            authRefreshCoordinator: authRefreshCoordinator,
            requestSpec: RequestSpec(method: method, path: path)
        )
    }

    func typedRequest<Response: Decodable>(method: NXHTTPMethod, path: String) -> NXTypedRequestBuilder<Response> {
        NXTypedRequestBuilder(requestBuilder: request(method: method, path: path))
    }
}
