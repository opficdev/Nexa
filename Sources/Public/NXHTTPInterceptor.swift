//
//  NXHTTPInterceptor.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// 요청 실행 단계 하나를 가로채 체인의 진행 방식을 결정합니다.
///
/// ## 개요
///
/// 추적, 커스텀 헤더, 응답 관찰 같은 횡단 관심사가 필요할 때 인터셉터를 구현하세요. 인터셉터는 요청 URL, 헤더, 바디를 바꿀 수 있으나 설정된 HTTP 메서드는 유지해야 합니다.
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
    /// 요청 실행 단계 하나를 처리합니다.
    ///
    /// - Parameters:
    ///   - context: 현재 요청 실행 상태입니다.
    ///   - next: 인터셉터 체인을 이어주는 클로저입니다.
    /// - Returns: 현재 인터셉터 또는 이후 단계에서 생성된 원시 HTTP 응답입니다.
    func intercept(
        context: NXRequestExecutionContext,
        next: @escaping @Sendable (NXRequestExecutionContext) async throws -> NXRawResponse
    ) async throws -> NXRawResponse
}

/// 인터셉터에게 노출되는 현재 요청 실행 상태의 스냅샷입니다.
///
/// `NXRequestExecutionContext`는 준비된 요청, 요청 식별자, 재시도 시도 번호, 커스텀 메타데이터를 인터셉터에서 조회할 수 있게 합니다.
public struct NXRequestExecutionContext: Sendable {
    /// 현재 실행 중인 요청입니다.
    public let request: URLRequest
    /// 동일한 논리적 요청의 모든 시도에서 공유되는 안정적인 식별자입니다.
    public let requestIdentifier: UUID
    /// 현재 시도 번호(`1`부터 시작)입니다.
    public let attemptNumber: Int
    /// 요청에 붙는 커스텀 문자열 메타데이터입니다.
    public let userInfo: [String: String]

    let specification: RequestSpec
    let clientConfiguration: NXClientConfiguration
    let authRefreshCoordinator: NXAuthRefreshCoordinator

    /// 다른 요청 값으로 만든 컨텍스트 사본을 반환합니다.
    ///
    /// - Parameter request: 이후 체인에서 사용할 대체 요청입니다. `httpMethod`는 설정된 요청 메서드와 같아야 합니다.
    /// - Returns: 업데이트된 요청을 담은 새 실행 컨텍스트입니다.
    ///
    /// 다른 값이거나 누락된 `httpMethod`를 가진 요청을 전달하면, 이후 인터셉터/로깅/캐시/트랜스포트 전에 ``NXError/invalidRequest(_:)``로 실행이 종료됩니다.
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
