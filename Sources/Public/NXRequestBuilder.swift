//
//  NXRequestBuilder.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation

/// HTTP 요청 구성과 전송을 값 의미론으로 다루는 빌더입니다.
///
/// ## 개요
///
/// `NXRequestBuilder`를 사용해 준비된 요청을 확인하고 `send()`로 `NXRawResponse`를 받거나 `send(as:)`로 응답을 디코딩할 수 있습니다. 원시 응답 실행 API는 `send()`뿐입니다.
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

    /// 요청 URL에 쿼리 항목을 추가합니다.
    ///
    /// - Parameters:
    ///   - key: 쿼리 항목 이름입니다.
    ///   - value: `String(describing:)`로 변환한 쿼리 항목 값입니다.
    /// - Returns: 업데이트된 요청 빌더입니다.
    public func query(_ key: String, _ value: some CustomStringConvertible) -> Self {
        modifying { requestSpec in
            requestSpec.queryItems.append(URLQueryItem(name: key, value: String(describing: value)))
        }
    }

    /// 단일 HTTP 헤더를 설정하거나 교체합니다.
    ///
    /// - Parameters:
    ///   - key: 헤더 필드 이름입니다.
    ///   - value: 헤더 필드 값입니다.
    /// - Returns: 업데이트된 요청 빌더입니다.
    public func header(_ key: String, _ value: String) -> Self {
        modifying { requestSpec in
            requestSpec.headers[key] = value
        }
    }

    /// 요청에 여러 HTTP 헤더를 병합합니다.
    ///
    /// - Parameter values: 추가할 헤더 필드 이름/값입니다. 기존 키는 새 값으로 덮어씁니다.
    /// - Returns: 업데이트된 요청 빌더입니다.
    public func headers(_ values: [String: String]) -> Self {
        modifying { requestSpec in
            requestSpec.headers.merge(values) { _, newValue in newValue }
        }
    }

    /// `Accept` 헤더를 설정합니다.
    ///
    /// - Parameter value: `Accept` 헤더의 미디어 타입 값입니다.
    /// - Returns: 업데이트된 요청 빌더입니다.
    public func accept(_ value: String) -> Self {
        header("Accept", value)
    }

    /// 설정된 인증 토큰 공급자를 통해 인증이 필요함을 표시합니다.
    ///
    /// - Returns: 업데이트된 요청 빌더입니다.
    public func authorized() -> Self {
        modifying { requestSpec in
            requestSpec.authRequirement = .required
        }
    }

    /// 요청별 타임아웃 간격을 설정합니다.
    ///
    /// - Parameter seconds: 타임아웃 간격(초). 음수 값은 `0`으로 보정됩니다.
    /// - Returns: 업데이트된 요청 빌더입니다.
    public func timeout(_ seconds: TimeInterval) -> Self {
        modifying { requestSpec in
            requestSpec.timeout = max(0, seconds)
        }
    }

    /// `Encodable` 값을 JSON으로 인코딩하고 `Content-Type` 헤더를 설정합니다.
    ///
    /// - Parameters:
    ///   - value: 요청 본문에 인코딩할 값입니다.
    ///   - encoder: 사용할 인코더입니다. 생략하면 클라이언트 설정의 인코더를 사용합니다.
    /// - Returns: 업데이트된 요청 빌더입니다.
    public func json<T: Encodable>(_ value: T, encoder: JSONEncoder? = nil) throws -> Self {
        let selectedEncoder = encoder ?? clientConfiguration.encoder
        let encodedValue = try selectedEncoder.encode(value)

        return modifying { requestSpec in
            requestSpec.body = .data(encodedValue)
            requestSpec.headers["Content-Type"] = "application/json; charset=utf-8"
        }
    }

    /// 원시 요청 본문 데이터를 설정합니다.
    ///
    /// - Parameter data: HTTP 본문에 넣을 데이터입니다.
    /// - Returns: 업데이트된 요청 빌더입니다.
    public func body(_ data: Data) -> Self {
        modifying { requestSpec in
            requestSpec.body = .data(data)
        }
    }

    /// `Content-Type` 헤더를 설정하거나 교체합니다.
    ///
    /// - Parameter value: `Content-Type` 헤더의 미디어 타입 값입니다.
    /// - Returns: 업데이트된 요청 빌더입니다.
    public func contentType(_ value: String) -> Self {
        modifying { requestSpec in
            requestSpec.headers["Content-Type"] = value
        }
    }

    /// 요청에 재시도 정책을 적용합니다.
    ///
    /// - Parameters:
    ///   - maxAttempts: 초기 요청을 포함한 최대 시도 횟수입니다. 기본값은 `3`입니다.
    ///   - backoff: 재시도 간 사용되는 지연 전략입니다.
    ///   - retryableStatusCodes: 재시도를 유발할 상태 코드입니다.
    ///   - allowing: 기본 멱등 메서드와 함께 재시도를 허용할 추가 HTTP 메서드입니다.
    ///   - maximumServerDelay: 서버 제공 재시도 지연에 적용되는 상한값입니다.
    ///   - jitter: 로컬 백오프 지연에 적용되는 무작위화입니다.
    /// - Returns: 업데이트된 요청 빌더입니다.
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

    /// 요청에 응답 유효성 정책을 적용합니다.
    ///
    /// - Parameter policy: 전송 계층이 응답을 반환한 뒤 적용할 유효성 검사 규칙입니다.
    /// - Returns: 업데이트된 요청 빌더입니다.
    public func validate(_ policy: NXValidationPolicy) -> Self {
        modifying { requestSpec in
            requestSpec.validationPolicy = policy
        }
    }

    /// 요청 단위 인터셉터를 추가합니다.
    ///
    /// - Parameter interceptor: 전역 인터셉터 뒤에 추가할 인터셉터입니다.
    /// - Returns: 업데이트된 요청 빌더입니다.
    public func intercept(_ interceptor: any NXHTTPInterceptor) -> Self {
        modifying { requestSpec in
            requestSpec.requestInterceptors.append(interceptor)
        }
    }

    /// 최종 `URLRequest`를 전송하지 않고 조립합니다.
    ///
    /// - Returns: 완전히 준비된 URLRequest입니다.
    public func preparedURLRequest() async throws -> URLRequest {
        try NXRequestAssembler.assemble(clientConfiguration: clientConfiguration, requestSpec: requestSpec)
    }

    /// 요청을 전송하고 원시 HTTP 응답을 반환합니다.
    ///
    /// - Returns: 원시 응답 데이터와 HTTP 메타데이터입니다.
    public func send() async throws -> NXRawResponse {
        try await NXRequestExecutor.executeRaw(
            clientConfiguration: clientConfiguration,
            responseCacheStore: responseCacheStore,
            authRefreshCoordinator: authRefreshCoordinator,
            requestSpec: requestSpec
        )
    }

    /// 요청을 전송하고 호출 문맥에서 결정된 응답 타입으로 응답을 디코딩합니다.
    ///
    /// - Returns: `Response`에 대한 디코딩된 응답 값입니다.
    public func send<Response: Decodable>() async throws -> Response {
        try await send(as: Response.self)
    }

    /// 요청을 전송하고 지정한 응답 타입으로 디코딩합니다.
    ///
    /// - Parameter type: 요청이 성공했을 때 디코딩할 응답 타입입니다.
    /// - Returns: `Response`에 대한 디코딩된 응답 값입니다.
    public func send<Response: Decodable>(as type: Response.Type) async throws -> Response {
        try await decoded(type)
    }

    /// 응답을 디코딩할 타입 지정 빌더로 변환합니다.
    ///
    /// - Parameter type: 요청이 성공했을 때 디코딩할 응답 타입입니다.
    /// - Returns: `Response`용 타입 지정 요청 빌더입니다.
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
