//
//  NXProtocols.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// `URLRequest`를 실행하는 네트워크 전송 추상화
///
/// ## 개요
///
/// 테스트에서 네트워크 응답을 스텁으로 처리하거나 기본 `URLSession` 전송을 교체할 때 `NXHTTPTransport` 채택
public protocol NXHTTPTransport: Sendable {
    /// 준비된 요청을 전송하고 `NXRawResponse` 반환
    func send(_ request: URLRequest) async throws -> NXRawResponse
}

/// 실패한 서버 응답의 도메인별 오류 디코딩
public protocol NXServerErrorDecoder: Sendable {
    /// 실패한 HTTP 응답을 기반으로 사용자 정의 오류 디코딩 시도
    func decodeServerError(data: Data, response: HTTPURLResponse, decoder: JSONDecoder) -> (any Error)?
}

/// 사용자 정의 오류를 생성하지 않는 기본 서버 오류 디코더
public struct NXDefaultServerErrorDecoder: NXServerErrorDecoder {
    /// 기본 서버 오류 디코더 초기화
    public init() {}

    /// 항상 `nil` 반환
    public func decodeServerError(data: Data, response: HTTPURLResponse, decoder: JSONDecoder) -> (any Error)? {
        nil
    }
}

/// 인증 요청과 토큰 갱신을 위한 Bearer 토큰 제공자
///
/// ## 개요
///
/// `.authorized()` 사용 시 `NXAuthTokenProvider` 구성 지점
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
