//
//  NXEndpoint.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation

public protocol NXEndpoint {
    associatedtype Response: Decodable
    var method: NXHTTPMethod { get }
    var path: String { get }
    func configure(_ builder: NXRequestBuilder) -> NXRequestBuilder
}

public extension NXEndpoint {
    func configure(_ builder: NXRequestBuilder) -> NXRequestBuilder {
        builder
    }
}
