//
//  NXProtocols.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// `URLRequest` 실행 네트워크 transport 추상화
///
/// ## 개요
///
/// 테스트에서 네트워크 응답 stub 처리 또는 기본 `URLSession` transport 교체 시 `NXHTTPTransport` 채택
public protocol NXHTTPTransport: Sendable {
    /// 준비된 요청 transport 및 `NXRawResponse` 반환
    func send(_ request: URLRequest) async throws -> NXRawResponse
}

/// 실패한 서버 응답의 도메인별 오류 decoding
public protocol NXServerErrorDecoder: Sendable {
    /// 실패한 HTTP 응답 기반 사용자 정의 오류 decoding 시도
    func decodeServerError(data: Data, response: HTTPURLResponse, decoder: JSONDecoder) -> (any Error)?
}

/// 사용자 정의 오류 미생성 기본 서버 오류 decoder
public struct NXDefaultServerErrorDecoder: NXServerErrorDecoder {
    /// 기본 서버 오류 decoder initialization
    public init() {}

    /// 항상 `nil` 반환
    public func decodeServerError(data: Data, response: HTTPURLResponse, decoder: JSONDecoder) -> (any Error)? {
        nil
    }
}

/// 인증 요청·토큰 갱신용 베어러 token provider
///
/// ## 개요
///
/// `.authorized()` 사용 시 `NXAuthTokenProvider` 구성 point
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
    /// 사용 가능한 현재 액세스 토큰 반환
    func currentAccessToken() async throws -> String?
    /// 액세스 토큰 갱신 및 갱신 성공 시 새 값 반환
    func refreshAccessToken() async throws -> String?
}
