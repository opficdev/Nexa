//
//  NXEndpoint.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation

/// 고정 응답 type을 갖는 재사용 가능한 API endpoint 설명
///
/// ## 개요
///
/// 동일 요청 구조 반복 사용 및 응답 type 보존이 필요한 재사용 가능한 endpoint 정의
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
    /// endpoint 요청 성공 시 decoding 대상 응답 type
    associatedtype Response: Decodable
    /// 요청에 사용되는 HTTP 메서드
    var method: NXHTTPMethod { get }
    /// client 기본 URL 기준 상대 경로
    var path: String { get }
    /// 전송 전 endpoint별 customization을 builder에 적용
    ///
    /// - Parameter builder: `method`와 `path` 기반 기본 type 지정 request builder
    /// - Returns: customization 적용 type 지정 request builder
    func configure(_ builder: NXTypedRequestBuilder<Response>) -> NXTypedRequestBuilder<Response>
}

public extension NXEndpoint {
    /// endpoint 추가 customization 미필요 시 builder 원본 반환
    ///
    /// - Parameter builder: `method`와 `path` 기반 기본 type 지정 request builder
    /// - Returns: 동일 builder instance
    func configure(_ builder: NXTypedRequestBuilder<Response>) -> NXTypedRequestBuilder<Response> {
        builder
    }
}
