//
//  NXHTTPInterceptor.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// 요청 실행 단계 가로채기와 체인 진행 방식 결정
///
/// ## 개요
///
/// 추적, 사용자 정의 header, 응답 관찰 같은 횡단 관심사 처리용 interceptor 구현. 요청 URL/header/body 변경 허용, 설정된 HTTP method 보존
///
/// ```swift
/// import Foundation
/// import Nexa
///
/// struct TraceInterceptor: NXHTTPInterceptor {
///     func intercept(
///         context: NXRequestExecutionContext,
///         next: @escaping @Sendable (NXRequestExecutionContext) async throws -> NXRawResponse
///     ) async throws -> NXRawResponse {
///         var request = context.request
///         request.setValue(UUID().uuidString, forHTTPHeaderField: "X-Trace-Id")
///         return try await next(context.replacingRequest(request))
///     }
/// }
/// ```
public protocol NXHTTPInterceptor: Sendable {
    /// 요청 실행 단계 단위 처리
    ///
    /// - Parameters:
    ///   - context: 현재 요청 실행 상태
    ///   - next: interceptor chain 연결 closure
    /// - Returns: 현재 interceptor 또는 이후 단계 생성 `NXRawResponse`
    func intercept(
        context: NXRequestExecutionContext,
        next: @escaping @Sendable (NXRequestExecutionContext) async throws -> NXRawResponse
    ) async throws -> NXRawResponse
}

/// interceptor 노출용 현재 요청 실행 상태 snapshot
///
/// `NXRequestExecutionContext`의 준비된 요청, 요청 식별자, retry 시도 번호, 사용자 정의 metadata를 interceptor에서 조회 가능
public struct NXRequestExecutionContext: Sendable {
    /// 현재 실행 중인 요청
    public let request: URLRequest
    /// 동일 논리 요청 전체 시도에서 공유되는 안정적 식별자
    public let requestIdentifier: UUID
    /// 현재 시도 번호(`1`부터 시작)
    public let attemptNumber: Int
    /// 요청 바인딩용 사용자 정의 문자열 metadata 값
    public let userInfo: [String: String]

    let specification: RequestSpec
    let clientConfiguration: NXClientConfiguration
    let authRefreshCoordinator: NXAuthRefreshCoordinator

    /// 대체 요청 기반 context 사본 생성
    ///
    /// - Parameter request: 이후 chain에서 사용할 대체 요청(`httpMethod`는 설정된 요청 method와 동일)
    /// - Returns: 갱신된 요청 포함 신규 실행 context
    ///
    /// `httpMethod` 값 불일치 또는 누락 요청 전달 시, 이후 interceptor/logging/cache/transport 이전 ``NXError/invalidRequest(_:)`` 실행 종료
    public func replacingRequest(_ request: URLRequest) -> Self {
        Self(
            request: request,
            requestIdentifier: requestIdentifier,
            attemptNumber: attemptNumber,
            userInfo: userInfo,
            specification: specification,
            clientConfiguration: clientConfiguration,
            authRefreshCoordinator: authRefreshCoordinator
        )
    }

    func withAttemptNumber(_ attemptNumber: Int) -> Self {
        Self(
            request: request,
            requestIdentifier: requestIdentifier,
            attemptNumber: attemptNumber,
            userInfo: userInfo,
            specification: specification,
            clientConfiguration: clientConfiguration,
            authRefreshCoordinator: authRefreshCoordinator
        )
    }
}
