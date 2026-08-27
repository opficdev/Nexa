//
//  NXEndpoint.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation

/// 고정 응답 타입을 갖는 재사용 가능한 API 엔드포인트 정의
///
/// ## 개요
///
/// 동일한 요청 구조를 반복해서 사용하고 응답 타입을 보존할 수 있는 엔드포인트 정의
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
/// struct UserEndpoint: NXEndpoint {
///     let identifier: Int
///
///     var method: NXHTTPMethod { .get }
///     var path: String { "/users/\(identifier)" }
///
///     func configure(_ builder: NXTypedRequestBuilder<User>) -> NXTypedRequestBuilder<User> {
///         builder.query("include", "profile")
///     }
/// }
///
/// let user = try await client.send(UserEndpoint(identifier: 42))
/// ```
public protocol NXEndpoint {
    /// 엔드포인트 요청 성공 시 디코딩 대상 응답 타입
    associatedtype Response: Decodable
    /// 요청에 사용되는 HTTP 메서드
    var method: NXHTTPMethod { get }
    /// 클라이언트 기본 URL을 기준으로 하는 상대 경로 또는 스킴을 포함한 절대 URL 문자열
    var path: String { get }
    /// 전송 전에 엔드포인트별 추가 설정을 빌더에 적용
    ///
    /// - Parameter builder: `method`와 `path`를 기반으로 만든 타입 지정 요청 빌더
    /// - Returns: 추가 설정을 적용한 타입 지정 요청 빌더
    func configure(_ builder: NXTypedRequestBuilder<Response>) -> NXTypedRequestBuilder<Response>
}

public extension NXEndpoint {
    /// 엔드포인트에 추가 설정이 필요하지 않을 때 빌더 원본 반환
    ///
    /// - Parameter builder: `method`와 `path`를 기반으로 만든 타입 지정 요청 빌더
    /// - Returns: 동일한 빌더 인스턴스
    func configure(_ builder: NXTypedRequestBuilder<Response>) -> NXTypedRequestBuilder<Response> {
        builder
    }
}
