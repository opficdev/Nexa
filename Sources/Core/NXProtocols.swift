//
//  NXProtocols.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// `URLRequest` 값을 실행하는 네트워크 전송 계층의 추상화입니다.
///
/// ## 개요
///
/// 테스트에서 네트워크 응답을 스텁 처리하거나 기본 `URLSession` 전송 계층을 교체하려면 `NXHTTPTransport`를 채택하세요.
public protocol NXHTTPTransport: Sendable {
    /// 준비된 요청을 전송하고 원시 HTTP 응답을 반환합니다.
    func send(_ request: URLRequest) async throws -> NXRawResponse
}

/// 실패한 서버 응답을 도메인별 오류로 디코딩합니다.
public protocol NXServerErrorDecoder: Sendable {
    /// 실패한 HTTP 응답에서 커스텀 오류를 디코딩하려고 시도합니다.
    func decodeServerError(data: Data, response: HTTPURLResponse, decoder: JSONDecoder) -> (any Error)?
}

/// 커스텀 오류를 생성하지 않는 기본 서버 오류 디코더입니다.
public struct NXDefaultServerErrorDecoder: NXServerErrorDecoder {
    /// 기본 서버 오류 디코더를 생성합니다.
    public init() {}

    /// 항상 `nil`을 반환합니다.
    public func decodeServerError(data: Data, response: HTTPURLResponse, decoder: JSONDecoder) -> (any Error)? {
        nil
    }
}

/// 인증 요청과 토큰 갱신을 위한 베어러 토큰을 제공합니다.
///
/// ## 개요
///
/// 요청이 `.authorized()`를 사용할 때는 인증 토큰 공급자를 구성하세요.
///
/// ```swift
/// import Nexa
///
/// actor AuthProvider: NXAuthTokenProvider {
///     func currentAccessToken() async throws -> String? {
///         "access-token"
///     }
///
///     func refreshAccessToken() async throws -> String? {
///         "refreshed-access-token"
///     }
/// }
/// ```
public protocol NXAuthTokenProvider: Sendable {
    /// 사용 가능한 현재 액세스 토큰을 반환합니다.
    func currentAccessToken() async throws -> String?
    /// 액세스 토큰을 갱신하고 갱신에 성공하면 새 값을 반환합니다.
    func refreshAccessToken() async throws -> String?
}
