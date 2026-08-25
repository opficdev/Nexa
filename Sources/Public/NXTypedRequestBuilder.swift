//
//  NXTypedRequestBuilder.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// 특정 응답 type decoding 요청의 값 의미론 builder
///
/// ## 개요
///
/// `NXTypedRequestBuilder`는 `NXEndpoint` 구성 compatibility 목적 유지. `NXRawResponse` 실행 API 미노출. method 기반 요청은 `NXRequestBuilder.send(as:)` 사용
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
/// let user = try await client
///     .get("/users/me")
///     .query("include", "profile")
///     .accept("application/json")
///     .send(as: User.self)
/// ```
public struct NXTypedRequestBuilder<Response>: Sendable where Response: Decodable {
    let requestBuilder: NXRequestBuilder

    /// 요청 URL 쿼리 항목 추가
    ///
    /// - Parameters:
    ///   - key: 쿼리 항목 이름
    ///   - value: `String(describing:)`로 변환한 쿼리 항목 값
    /// - Returns: 갱신된 type 지정 request builder
    public func query(_ key: String, _ value: some CustomStringConvertible) -> Self {
        Self(requestBuilder: requestBuilder.query(key, value))
    }

    /// 단일 HTTP header 설정/교체
    ///
    /// - Parameters:
    ///   - key: header field 이름
    ///   - value: header field 값
    /// - Returns: 갱신된 type 지정 request builder
    public func header(_ key: String, _ value: String) -> Self {
        Self(requestBuilder: requestBuilder.header(key, value))
    }

    /// 다수 HTTP header 병합
    ///
    /// - Parameter values: 추가 header field 이름/값. 키 충돌 시 새 값 우선
    /// - Returns: 갱신된 type 지정 request builder
    public func headers(_ values: [String: String]) -> Self {
        Self(requestBuilder: requestBuilder.headers(values))
    }

    /// `Accept` header 설정
    ///
    /// - Parameter value: `Accept` header media type 값
    /// - Returns: 갱신된 type 지정 request builder
    public func accept(_ value: String) -> Self {
        Self(requestBuilder: requestBuilder.accept(value))
    }

    /// 설정된 `NXAuthTokenProvider`를 통한 인증 필요 표시
    ///
    /// - Returns: 갱신된 type 지정 request builder
    public func authorized() -> Self {
        Self(requestBuilder: requestBuilder.authorized())
    }

    /// 요청별 타임아웃 간격 설정
    ///
    /// - Parameter seconds: 타임아웃 간격(초). 음수 값은 `0` 보정
    /// - Returns: 갱신된 type 지정 request builder
    public func timeout(_ seconds: TimeInterval) -> Self {
        Self(requestBuilder: requestBuilder.timeout(seconds))
    }

    /// `Encodable` 값 JSON encoding 및 `Content-Type` header 설정
    ///
    /// - Parameters:
    ///   - value: 요청 body encoding 대상 값
    ///   - encoder: 사용 encoder. 미지정 시 client 설정 encoder 사용
    /// - Returns: 갱신된 type 지정 request builder
    public func json<T: Encodable>(_ value: T, encoder: JSONEncoder? = nil) throws -> Self {
        try Self(requestBuilder: requestBuilder.json(value, encoder: encoder))
    }

    /// 원시 요청 body data 설정
    ///
    /// - Parameter data: HTTP body 입력 data
    /// - Returns: 갱신된 type 지정 request builder
    public func body(_ data: Data) -> Self {
        Self(requestBuilder: requestBuilder.body(data))
    }

    /// `Content-Type` header 설정/교체
    ///
    /// - Parameter value: `Content-Type` header media type 값
    /// - Returns: 갱신된 type 지정 request builder
    public func contentType(_ value: String) -> Self {
        Self(requestBuilder: requestBuilder.contentType(value))
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
    /// - Returns: 갱신된 type 지정 request builder
    public func retry(
        maxAttempts: Int = 3,
        backoff: NXRetryBackoff = .fixed(0),
        retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504],
        allowing: Set<NXHTTPMethod> = [],
        maximumServerDelay: TimeInterval = 60,
        jitter: NXRetryJitter = .none
    ) -> Self {
        Self(requestBuilder: requestBuilder.retry(
            maxAttempts: maxAttempts,
            backoff: backoff,
            retryableStatusCodes: retryableStatusCodes,
            allowing: allowing,
            maximumServerDelay: maximumServerDelay,
            jitter: jitter
        ))
    }

    /// 요청 응답 validation policy 적용
    ///
    /// - Parameter policy: transport 응답 반환 후 적용 validation 규칙
    /// - Returns: 갱신된 type 지정 request builder
    public func validate(_ policy: NXValidationPolicy) -> Self {
        Self(requestBuilder: requestBuilder.validate(policy))
    }

    /// 요청 단위 interceptor 추가
    ///
    /// - Parameter interceptor: 전역 interceptor 뒤에 추가할 interceptor
    /// - Returns: 갱신된 type 지정 request builder
    public func intercept(_ interceptor: any NXHTTPInterceptor) -> Self {
        Self(requestBuilder: requestBuilder.intercept(interceptor))
    }

    /// 최종 `URLRequest` 조립(전송 제외)
    ///
    /// - Returns: 완전 준비된 URLRequest
    public func preparedURLRequest() async throws -> URLRequest {
        try await requestBuilder.preparedURLRequest()
    }

    /// 요청 전송 및 `Response` 응답 decoding
    ///
    /// - Returns: 응답 decoding 결과
    /// - Throws: 요청 실패/decoding 실패 시 `NXError` 발생
    public func send() async throws -> Response {
        try await requestBuilder.send(as: Response.self)
    }

    var retryPolicy: NXRetryPolicy? {
        requestBuilder.retryPolicy
    }
}
