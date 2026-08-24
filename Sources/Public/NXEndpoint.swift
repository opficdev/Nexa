//
//  NXEndpoint.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation

/// 고정 응답 타입을 갖는 재사용 가능한 API 엔드포인트를 설명합니다.
///
/// ## 개요
///
/// 동일한 요청 구조를 반복 사용하면서 응답 타입을 함께 유지해야 할 때 엔드포인트를 사용합니다.
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
    /// 엔드포인트 요청이 성공했을 때 생성되는 응답 타입입니다.
    associatedtype Response: Decodable
    /// 요청에 사용되는 HTTP 메서드입니다.
    var method: NXHTTPMethod { get }
    /// 클라이언트 기본 URL 기준 상대 경로입니다.
    var path: String { get }
    /// 전송 전에 엔드포인트별 커스터마이즈를 빌더에 적용합니다.
    ///
    /// - Parameter builder: `method`와 `path`로 생성한 기본 타입 지정 요청 빌더입니다.
    /// - Returns: 커스터마이즈된 타입 지정 요청 빌더입니다.
    func configure(_ builder: NXTypedRequestBuilder<Response>) -> NXTypedRequestBuilder<Response>
}

public extension NXEndpoint {
    /// 엔드포인트에 추가 커스터마이즈가 필요하지 않으면 빌더를 그대로 반환합니다.
    ///
    /// - Parameter builder: `method`와 `path`로 생성한 기본 타입 지정 요청 빌더입니다.
    /// - Returns: 동일한 빌더 인스턴스입니다.
    func configure(_ builder: NXTypedRequestBuilder<Response>) -> NXTypedRequestBuilder<Response> {
        builder
    }
}
