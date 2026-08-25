//
//  NXRequestBuilder.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation

/// HTTP 요청 구성·전송의 값 의미론 builder
///
/// ## 개요
///
/// `NXRequestBuilder` 준비 요청 확인, `send()`로 `NXRawResponse` 획득, `send(as:)`로 응답 decoding 지원. `NXRawResponse` 실행 API는 `send()` 단일 노출
///
/// ```swift
/// import Foundation
/// import Nexa
///
/// let request = try await client
///     .post("/users")
///     .header("X-Trace-Id", UUID().uuidString)
///     .preparedURLRequest()
/// ```
///
/// ```swift
/// import Foundation
/// import Nexa
///
/// let response = try await client
///     .get("/users")
///     .accept("application/json")
///     .send()
/// ```
public struct NXRequestBuilder: Sendable {
    private let clientConfiguration: NXClientConfiguration
    private let responseCacheStore: NXResponseCacheStore?
    private let authRefreshCoordinator: NXAuthRefreshCoordinator
    private let requestSpec: RequestSpec

    init(
        clientConfiguration: NXClientConfiguration,
        responseCacheStore: NXResponseCacheStore?,
        authRefreshCoordinator: NXAuthRefreshCoordinator,
        requestSpec: RequestSpec
    ) {
        self.clientConfiguration = clientConfiguration
        self.responseCacheStore = responseCacheStore
        self.authRefreshCoordinator = authRefreshCoordinator
        self.requestSpec = requestSpec
    }

    /// 요청 URL 쿼리 항목 추가
    ///
    /// - Parameters:
    ///   - key: 쿼리 항목 이름
    ///   - value: `String(describing:)`로 변환한 쿼리 항목 값
    /// - Returns: 갱신된 request builder
    public func query(_ key: String, _ value: some CustomStringConvertible) -> Self {
        modifying { requestSpec in
            requestSpec.queryItems.append(URLQueryItem(name: key, value: String(describing: value)))
        }
    }

    /// 단일 HTTP header 설정/교체
    ///
    /// - Parameters:
    ///   - key: header field 이름
    ///   - value: header field 값
    /// - Returns: 갱신된 request builder
    public func header(_ key: String, _ value: String) -> Self {
        modifying { requestSpec in
            requestSpec.headers[key] = value
        }
    }

    /// 다수 HTTP header 병합
    ///
    /// - Parameter values: 추가 header field 이름/값. 키 충돌 시 새 값 우선
    /// - Returns: 갱신된 request builder
    public func headers(_ values: [String: String]) -> Self {
        modifying { requestSpec in
            requestSpec.headers.merge(values) { _, newValue in newValue }
        }
    }

    /// `Accept` header 설정
    ///
    /// - Parameter value: `Accept` header media type 값
    /// - Returns: 갱신된 request builder
    public func accept(_ value: String) -> Self {
        header("Accept", value)
    }

    /// 설정된 `NXAuthTokenProvider`를 통한 인증 필요 표시
    ///
    /// - Returns: 갱신된 request builder
    public func authorized() -> Self {
        modifying { requestSpec in
            requestSpec.authRequirement = .required
        }
    }

    /// 요청별 타임아웃 간격 설정
    ///
    /// - Parameter seconds: 타임아웃 간격(초). 음수 값은 `0` 보정
    /// - Returns: 갱신된 request builder
    public func timeout(_ seconds: TimeInterval) -> Self {
        modifying { requestSpec in
            requestSpec.timeout = max(0, seconds)
        }
    }

    /// `Encodable` 값 JSON encoding 및 `Content-Type` header 설정
    ///
    /// - Parameters:
    ///   - value: 요청 body encoding 대상 값
    ///   - encoder: 사용 encoder. 미지정 시 client 설정 encoder 사용
    /// - Returns: 갱신된 request builder
    public func json<T: Encodable>(_ value: T, encoder: JSONEncoder? = nil) throws -> Self {
        let selectedEncoder = encoder ?? clientConfiguration.encoder
        let encodedValue = try selectedEncoder.encode(value)

        return modifying { requestSpec in
            requestSpec.body = .data(encodedValue)
            requestSpec.headers["Content-Type"] = "application/json; charset=utf-8"
        }
    }

    /// 원시 요청 body data 설정
    ///
    /// - Parameter data: HTTP body 입력 data
    /// - Returns: 갱신된 request builder
    public func body(_ data: Data) -> Self {
        modifying { requestSpec in
            requestSpec.body = .data(data)
        }
    }

    /// `Content-Type` header 설정/교체
    ///
    /// - Parameter value: `Content-Type` header media type 값
    /// - Returns: 갱신된 request builder
    public func contentType(_ value: String) -> Self {
        modifying { requestSpec in
            requestSpec.headers["Content-Type"] = value
        }
    }

    /// 요청 retry policy 적용
    ///
    /// - Parameters:
    ///   - maxAttempts: 초기 요청 포함 최대 시도 횟수(기본 `3`)
    ///   - backoff: retry 간 지연 전략
    ///   - retryableStatusCodes: retry 유발 상태 코드 집합
    ///   - allowing: 기본 멱등 메서드와 함께 허용할 추가 HTTP 메서드
    ///   - maximumServerDelay: 서버 retry 지연 상한
    ///   - jitter: 로컬 backoff 지연 무작위화 설정
    /// - Returns: 갱신된 request builder
    public func retry(
        maxAttempts: Int = 3,
        backoff: NXRetryBackoff = .fixed(0),
        retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504],
        allowing: Set<NXHTTPMethod> = [],
        maximumServerDelay: TimeInterval = 60,
        jitter: NXRetryJitter = .none
    ) -> Self {
        modifying { requestSpec in
            requestSpec.retryPolicy = NXRetryPolicy(
                maxAttempts: maxAttempts,
                backoff: backoff,
                retryableStatusCodes: retryableStatusCodes,
                allowing: allowing,
                maximumServerDelay: maximumServerDelay,
                jitter: jitter
            )
        }
    }

    /// 요청 응답 validation policy 적용
    ///
    /// - Parameter policy: transport 응답 반환 후 적용 validation 규칙
    /// - Returns: 갱신된 request builder
    public func validate(_ policy: NXValidationPolicy) -> Self {
        modifying { requestSpec in
            requestSpec.validationPolicy = policy
        }
    }

    /// 요청 단위 interceptor 추가
    ///
    /// - Parameter interceptor: 전역 interceptor 뒤에 추가할 interceptor
    /// - Returns: 갱신된 request builder
    public func intercept(_ interceptor: any NXHTTPInterceptor) -> Self {
        modifying { requestSpec in
            requestSpec.requestInterceptors.append(interceptor)
        }
    }

    /// 최종 `URLRequest` 조립(전송 제외)
    ///
    /// - Returns: 완전 준비된 URLRequest
    public func preparedURLRequest() async throws -> URLRequest {
        try NXRequestAssembler.assemble(clientConfiguration: clientConfiguration, requestSpec: requestSpec)
    }

    /// 요청 전송 및 `NXRawResponse` 반환
    ///
    /// - Returns: `NXRawResponse`의 응답 data와 HTTP metadata
    public func send() async throws -> NXRawResponse {
        try await NXRequestExecutor.executeRaw(
            clientConfiguration: clientConfiguration,
            responseCacheStore: responseCacheStore,
            authRefreshCoordinator: authRefreshCoordinator,
            requestSpec: requestSpec
        )
    }

    /// 요청 전송 및 호출 context 결정 응답 type decoding
    ///
    /// - Returns: `Response` decoding 응답 값
    public func send<Response: Decodable>() async throws -> Response {
        try await send(as: Response.self)
    }

    /// 요청 전송 및 지정 응답 type decoding
    ///
    /// - Parameter type: 성공 응답 decoding 대상 type
    /// - Returns: `Response` decoding 응답 값
    public func send<Response: Decodable>(as type: Response.Type) async throws -> Response {
        try await decoded(type)
    }

    /// 응답 decoding용 type 지정 builder 변환
    ///
    /// - Parameter type: 성공 응답 decoding 대상 type
    /// - Returns: `Response` type 지정 request builder
    @available(*, deprecated, message: "Use send(as:) or a contextual send().")
    public func `as`<Response: Decodable>(_ type: Response.Type) -> NXTypedRequestBuilder<Response> {
        NXTypedRequestBuilder(requestBuilder: self)
    }

    func decoded<Response: Decodable>(_ type: Response.Type) async throws -> Response {
        try await NXRequestExecutor.executeDecode(
            clientConfiguration: clientConfiguration,
            responseCacheStore: responseCacheStore,
            authRefreshCoordinator: authRefreshCoordinator,
            requestSpec: requestSpec,
            responseType: Response.self
        )
    }

    var retryPolicy: NXRetryPolicy? {
        requestSpec.retryPolicy
    }

    func modifying(_ update: (inout RequestSpec) throws -> Void) rethrows -> Self {
        var copiedRequestSpec = requestSpec
        try update(&copiedRequestSpec)
        return Self(
            clientConfiguration: clientConfiguration,
            responseCacheStore: responseCacheStore,
            authRefreshCoordinator: authRefreshCoordinator,
            requestSpec: copiedRequestSpec
        )
    }
}
