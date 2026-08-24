//
//  NXAPIClient.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation

/// 단일 클라이언트 설정으로 HTTP 요청을 구성하고 전송하기 위한 공용 진입점입니다.
///
/// ## 개요
///
/// 클라이언트를 한 번 생성한 뒤 상대 경로로 요청을 시작하세요.
///
/// 캐시를 사용하면 각 `NXAPIClient` 초기화 시 독립적인 인메모리 캐시와 인플라이트 요청 저장소가 생성됩니다. 캐시 응답을 공유하려면 서비스나 의존성 컨테이너에서 하나의 클라이언트를 재사용하세요. 동일 클라이언트 값의 복사본은 같은 저장소를 유지합니다.
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
/// 모든 직접 요청은 메서드 기반 빌더를 사용하세요. `NXEndpoint`는 소스 호환성을 위해 타입 지정 빌더 구성 계약을 유지합니다.
public struct NXAPIClient: Sendable {
    private let configuration: NXClientConfiguration
    private let responseCacheStore: NXResponseCacheStore?
    private let authRefreshCoordinator: NXAuthRefreshCoordinator

    /// 모든 요청에 제공된 설정을 사용하는 클라이언트를 생성합니다.
    ///
    /// - Parameter configuration: 기본 URL, 전송 계층, 로거, 인증 공급자 같은 공용 설정입니다.
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

    /// 지정한 경로에 대한 타입 미지정 `GET` 요청 빌더를 생성합니다.
    ///
    /// - Parameter path: 설정된 기본 URL 기준 상대 경로입니다.
    /// - Returns: 전송 전에 추가로 설정할 수 있는 요청 빌더입니다.
    public func get(_ path: String = "") -> NXRequestBuilder {
        request(method: .get, path: path)
    }

    /// 지정한 경로에 대한 타입 지정 `GET` 요청 빌더를 생성합니다.
    ///
    /// - Parameters:
    ///   - path: 설정된 기본 URL 기준 상대 경로입니다.
    ///   - type: 요청이 성공했을 때 디코딩할 응답 타입입니다.
    /// - Returns: `Response`로 디코딩하는 타입 지정 요청 빌더입니다.
    @available(*, deprecated, message: "Use get(_:) followed by send(as:).")
    public func get<Response: Decodable>(
        _ path: String = "",
        as type: Response.Type
    ) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .get, path: path)
    }

    /// 지정한 경로에 대한 타입 미지정 `POST` 요청 빌더를 생성합니다.
    ///
    /// - Parameter path: 설정된 기본 URL 기준 상대 경로입니다.
    /// - Returns: 전송 전에 추가로 설정할 수 있는 요청 빌더입니다.
    public func post(_ path: String) -> NXRequestBuilder {
        request(method: .post, path: path)
    }

    /// 지정한 경로에 대한 타입 지정 `POST` 요청 빌더를 생성합니다.
    ///
    /// - Parameters:
    ///   - path: 설정된 기본 URL 기준 상대 경로입니다.
    ///   - type: 요청이 성공했을 때 디코딩할 응답 타입입니다.
    /// - Returns: `Response`로 디코딩하는 타입 지정 요청 빌더입니다.
    @available(*, deprecated, message: "Use post(_:) followed by send(as:).")
    public func post<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .post, path: path)
    }

    /// 지정한 경로에 대한 타입 미지정 `PUT` 요청 빌더를 생성합니다.
    ///
    /// - Parameter path: 설정된 기본 URL 기준 상대 경로입니다.
    /// - Returns: 전송 전에 추가로 설정할 수 있는 요청 빌더입니다.
    public func put(_ path: String) -> NXRequestBuilder {
        request(method: .put, path: path)
    }

    /// 지정한 경로에 대한 타입 지정 `PUT` 요청 빌더를 생성합니다.
    ///
    /// - Parameters:
    ///   - path: 설정된 기본 URL 기준 상대 경로입니다.
    ///   - type: 요청이 성공했을 때 디코딩할 응답 타입입니다.
    /// - Returns: `Response`로 디코딩하는 타입 지정 요청 빌더입니다.
    @available(*, deprecated, message: "Use put(_:) followed by send(as:).")
    public func put<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .put, path: path)
    }

    /// 지정한 경로에 대한 타입 미지정 `PATCH` 요청 빌더를 생성합니다.
    ///
    /// - Parameter path: 설정된 기본 URL 기준 상대 경로입니다.
    /// - Returns: 전송 전에 추가로 설정할 수 있는 요청 빌더입니다.
    public func patch(_ path: String) -> NXRequestBuilder {
        request(method: .patch, path: path)
    }

    /// 지정한 경로에 대한 타입 지정 `PATCH` 요청 빌더를 생성합니다.
    ///
    /// - Parameters:
    ///   - path: 설정된 기본 URL 기준 상대 경로입니다.
    ///   - type: 요청이 성공했을 때 디코딩할 응답 타입입니다.
    /// - Returns: `Response`로 디코딩하는 타입 지정 요청 빌더입니다.
    @available(*, deprecated, message: "Use patch(_:) followed by send(as:).")
    public func patch<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .patch, path: path)
    }

    /// 지정한 경로에 대한 타입 미지정 `DELETE` 요청 빌더를 생성합니다.
    ///
    /// - Parameter path: 설정된 기본 URL 기준 상대 경로입니다.
    /// - Returns: 전송 전에 추가로 설정할 수 있는 요청 빌더입니다.
    public func delete(_ path: String) -> NXRequestBuilder {
        request(method: .delete, path: path)
    }

    /// 지정한 경로에 대한 타입 지정 `DELETE` 요청 빌더를 생성합니다.
    ///
    /// - Parameters:
    ///   - path: 설정된 기본 URL 기준 상대 경로입니다.
    ///   - type: 요청이 성공했을 때 디코딩할 응답 타입입니다.
    /// - Returns: `Response`로 디코딩하는 타입 지정 요청 빌더입니다.
    @available(*, deprecated, message: "Use delete(_:) followed by send(as:).")
    public func delete<Response: Decodable>(_ path: String, as type: Response.Type) -> NXTypedRequestBuilder<Response> {
        typedRequest(method: .delete, path: path)
    }

    /// 엔드포인트 값에서 타입 지정 요청을 구성합니다.
    ///
    /// - Parameter endpoint: HTTP 메서드, 경로, 선택적 요청 커스터마이즈를 정의하는 엔드포인트입니다.
    /// - Returns: 엔드포인트 기반으로 설정된 타입 지정 요청 빌더입니다.
    public func request<E: NXEndpoint>(_ endpoint: E) -> NXTypedRequestBuilder<E.Response> {
        endpoint.configure(typedRequest(method: endpoint.method, path: endpoint.path))
    }

    /// 엔드포인트 요청을 전송하고 응답을 디코딩합니다.
    ///
    /// - Parameter endpoint: 요청 동작을 정의한 엔드포인트입니다.
    /// - Returns: 엔드포인트에 대한 디코딩된 응답 값입니다.
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
