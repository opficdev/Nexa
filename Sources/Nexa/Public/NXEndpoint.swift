//
//  NXEndpoint.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation

/// Describes a reusable API endpoint with a fixed response type.
///
/// ## Overview
///
/// Use an endpoint when the same request shape should be reusable and keep its response type attached.
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
    /// Response type produced when the endpoint request succeeds.
    associatedtype Response: Decodable
    /// HTTP method used for the request.
    var method: NXHTTPMethod { get }
    /// Path relative to the client's base URL.
    var path: String { get }
    /// Applies endpoint-specific customization to the builder before sending.
    ///
    /// - Parameter builder: Default typed request builder created from `method` and `path`.
    /// - Returns: Customized typed request builder.
    func configure(_ builder: NXTypedRequestBuilder<Response>) -> NXTypedRequestBuilder<Response>
}

public extension NXEndpoint {
    /// Returns the builder unchanged when the endpoint needs no extra customization.
    ///
    /// - Parameter builder: Default typed request builder created from `method` and `path`.
    /// - Returns: The same builder instance.
    func configure(_ builder: NXTypedRequestBuilder<Response>) -> NXTypedRequestBuilder<Response> {
        builder
    }
}
