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
/// 추적, 사용자 정의 헤더, 응답 관찰 같은 횡단 관심사를 처리하는 인터셉터 구현. 요청 URL, 헤더, 본문 변경을 허용하고 설정된 HTTP 메서드 보존
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
    ///   - next: 인터셉터 체인을 연결하는 클로저
    /// - Returns: 현재 인터셉터 또는 이후 단계가 생성한 `NXRawResponse`
    func intercept(
        context: NXRequestExecutionContext,
        next: @escaping @Sendable (NXRequestExecutionContext) async throws -> NXRawResponse
    ) async throws -> NXRawResponse
}

/// 인터셉터에 제공하는 현재 요청 실행 상태 스냅샷
///
/// `NXRequestExecutionContext`의 준비된 요청, 요청 식별자, 재시도 번호를 인터셉터에서 조회 가능
/// `userInfo`는 현재 공개 요청 빌더에서 설정되지 않아 빈 딕셔너리로 전달
public struct NXRequestExecutionContext: Sendable {
    /// 현재 실행 중인 요청
    public let request: URLRequest
    /// 동일 논리 요청 전체 시도에서 공유되는 안정적 식별자
    public let requestIdentifier: UUID
    /// 현재 시도 번호(`1`부터 시작)
    public let attemptNumber: Int
    /// 현재 공개 요청 빌더에서 설정되지 않아 빈 딕셔너리로 전달되는 메타데이터 값
    public let userInfo: [String: String]

    let specification: RequestSpec
    let clientConfiguration: NXClientConfiguration
    let authRefreshCoordinator: NXAuthRefreshCoordinator

    /// 대체 요청을 기반으로 실행 상태 사본 생성
    ///
    /// - Parameter request: 이후 체인에서 사용할 대체 요청(`httpMethod`는 설정된 요청 메서드와 동일)
    /// - Returns: 갱신된 요청을 포함한 신규 실행 상태
    ///
    /// `httpMethod` 값이 다르거나 누락된 요청을 전달하면 이후 인터셉터, 로깅, 캐시, 전송이 실행되기 전에 ``NXError/invalidRequest(_:)``로 종료
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
