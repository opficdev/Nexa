//
//  NXRequestSpec.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

enum NXAuthRequirement: Sendable {
    case none
    case required
}

struct RequestSpec: Sendable {
    var method: NXHTTPMethod
    var path: String
    var queryItems: [URLQueryItem]
    var headers: [String: String]
    var body: NXRequestBody?
    var timeout: TimeInterval?
    var authRequirement: NXAuthRequirement
    var retryPolicy: NXRetryPolicy?
    var validationPolicy: NXValidationPolicy
    var requestInterceptors: [any NXHTTPInterceptor]
    var userInfo: [String: String]
    var requestIdentifier: UUID

    init(method: NXHTTPMethod, path: String) {
        self.method = method
        self.path = path
        queryItems = []
        headers = [:]
        body = nil
        timeout = nil
        authRequirement = .none
        retryPolicy = nil
        validationPolicy = .successStatusCode
        requestInterceptors = []
        userInfo = [:]
        requestIdentifier = UUID()
    }
}
