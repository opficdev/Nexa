//
//  NXAPIClient.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation

/// 단일 client 설정 기반 HTTP 요청 구성·전송 공용 진입점
///
/// ## 개요
///
/// client 단일 생성 후 상대 경로 기반 요청 시작
///
/// cache 사용 시 각 `NXAPIClient` 초기화마다 독립 메모리 cache와 진행 중 request store 생성. cache 응답 공유는 서비스 또는 DI 계층에서 client 단일 재사용으로 보장. 동일 client 값 복사본은 동일 store 유지
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
/// 직접 요청은 method 기반 builder 경로, `NXEndpoint`는 type 지정 builder 구성 contract의 source 호환성 유지
public struct NXAPIClient: Sendable {
    private let configuration: NXClientConfiguration
    private let responseCacheStore: NXResponseCacheStore?
    private let authRefreshCoordinator: NXAuthRefreshCoordinator

    /// 모든 요청 공통 설정 반영 client 생성
    ///
    /// - Parameter configuration: 기본 URL, transport, logger, `NXAuthTokenProvider` 같은 공용 설정
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

    /// 지정 경로 기준 type 미지정 `GET` request builder 생성
    ///
    /// - Parameter path: 설정된 기본 URL 기준 상대 경로
    /// - Returns: 전송 전 추가 설정 가능한 request builder
    public func get(_ path: String = "") -> NXRequestBuilder {
        request(method: .get, path: path)
    }

    /// 지정 경로 기준 type 지정 `GET` request builder 생성
    ///
    /// - Parameters:
    ///   - path: 설정된 기본 URL 기준 상대 경로
    ///   - type: 성공 응답 decoding 대상 type
    /// - Returns: `Response` decoding type 지정 request builder
    @available(*, deprecated, message: "Use get(_:) followed by send(as:).")
    public func get<Response: Decodable>(
        _ path: String = "",
        as type: Response.Type
    ) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .get, path: path)
    }

    /// 지정 경로 기준 type 미지정 `POST` request builder 생성
    ///
    /// - Parameter path: 설정된 기본 URL 기준 상대 경로
    /// - Returns: 전송 전 추가 설정 가능한 request builder
    public func post(_ path: String) -> NXRequestBuilder {
        request(method: .post, path: path)
    }

    /// 지정 경로 기준 type 지정 `POST` request builder 생성
    ///
    /// - Parameters:
    ///   - path: 설정된 기본 URL 기준 상대 경로
    ///   - type: 성공 응답 decoding 대상 type
    /// - Returns: `Response` decoding type 지정 request builder
    @available(*, deprecated, message: "Use post(_:) followed by send(as:).")
    public func post<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .post, path: path)
    }

    /// 지정 경로 기준 type 미지정 `PUT` request builder 생성
    ///
    /// - Parameter path: 설정된 기본 URL 기준 상대 경로
    /// - Returns: 전송 전 추가 설정 가능한 request builder
    public func put(_ path: String) -> NXRequestBuilder {
        request(method: .put, path: path)
    }

    /// 지정 경로 기준 type 지정 `PUT` request builder 생성
    ///
    /// - Parameters:
    ///   - path: 설정된 기본 URL 기준 상대 경로
    ///   - type: 성공 응답 decoding 대상 type
    /// - Returns: `Response` decoding type 지정 request builder
    @available(*, deprecated, message: "Use put(_:) followed by send(as:).")
    public func put<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .put, path: path)
    }

    /// 지정 경로 기준 type 미지정 `PATCH` request builder 생성
    ///
    /// - Parameter path: 설정된 기본 URL 기준 상대 경로
    /// - Returns: 전송 전 추가 설정 가능한 request builder
    public func patch(_ path: String) -> NXRequestBuilder {
        request(method: .patch, path: path)
    }

    /// 지정 경로 기준 type 지정 `PATCH` request builder 생성
    ///
    /// - Parameters:
    ///   - path: 설정된 기본 URL 기준 상대 경로
    ///   - type: 성공 응답 decoding 대상 type
    /// - Returns: `Response` decoding type 지정 request builder
    @available(*, deprecated, message: "Use patch(_:) followed by send(as:).")
    public func patch<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .patch, path: path)
    }

    /// 지정 경로 기준 type 미지정 `DELETE` request builder 생성
    ///
    /// - Parameter path: 설정된 기본 URL 기준 상대 경로
    /// - Returns: 전송 전 추가 설정 가능한 request builder
    public func delete(_ path: String) -> NXRequestBuilder {
        request(method: .delete, path: path)
    }

    /// 지정 경로 기준 type 지정 `DELETE` request builder 생성
    ///
    /// - Parameters:
    ///   - path: 설정된 기본 URL 기준 상대 경로
    ///   - type: 성공 응답 decoding 대상 type
    /// - Returns: `Response` decoding type 지정 request builder
    @available(*, deprecated, message: "Use delete(_:) followed by send(as:).")
    public func delete<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .delete, path: path)
    }

    /// endpoint에서 type 지정 요청 구성
    ///
    /// - Parameter endpoint: HTTP method, 경로, 선택적 요청 customization 정의 endpoint
    /// - Returns: endpoint 기반 type 지정 request builder
    public func request<E: NXEndpoint>(_ endpoint: E) -> NXTypedRequestBuilder<E.Response> {
        endpoint.configure(typedRequest(method: endpoint.method, path: endpoint.path))
    }

    /// endpoint 요청 전송 및 응답 decoding
    ///
    /// - Parameter endpoint: 요청 동작 정의 endpoint
    /// - Returns: endpoint 응답 decoding 결과
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
