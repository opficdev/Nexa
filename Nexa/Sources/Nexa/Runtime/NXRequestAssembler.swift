//
//  NXRequestAssembler.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation

enum NXRequestAssembler {
    static func assemble(clientConfiguration: NXClientConfiguration, requestSpec: RequestSpec) throws -> URLRequest {
        let assembledURL = try assembleURL(baseURL: clientConfiguration.baseURL, requestSpec: requestSpec)
        var request = URLRequest(url: assembledURL)
        request.httpMethod = requestSpec.method.rawValue

        request.allHTTPHeaderFields = mergedHeaders(
            clientConfiguration: clientConfiguration,
            requestSpec: requestSpec
        )

        if let requestBody = requestSpec.body {
            request.httpBody = requestBody.data
        }

        if let timeout = requestSpec.timeout {
            request.timeoutInterval = timeout
        }

        return request
    }

    static func assembleURL(baseURL: URL, requestSpec: RequestSpec) throws -> URL {
        if let absoluteURL = URL(string: requestSpec.path), absoluteURL.scheme != nil {
            return appendQueryItems(url: absoluteURL, queryItems: requestSpec.queryItems)
        }

        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else {
            throw NXError.invalidRequest("Invalid base URL")
        }

        components.path = mergedPath(basePath: components.path, requestPath: requestSpec.path)
        components.queryItems = mergedQueryItems(existing: components.queryItems ?? [], adding: requestSpec.queryItems)

        guard let finalURL = components.url else {
            throw NXError.invalidRequest("Failed to construct request URL")
        }

        return finalURL
    }

    private static func mergedPath(basePath: String, requestPath: String) -> String {
        let normalizedBasePath = basePath.isEmpty ? "/" : (basePath.hasPrefix("/") ? basePath : "/\(basePath)")
        let normalizedRequestPath = requestPath.hasPrefix("/") ? String(requestPath.dropFirst()) : requestPath

        guard !normalizedRequestPath.isEmpty else {
            return normalizedBasePath
        }

        if normalizedBasePath == "/" {
            return "/\(normalizedRequestPath)"
        }

        if normalizedBasePath.hasSuffix("/") {
            return "\(normalizedBasePath)\(normalizedRequestPath)"
        }

        return "\(normalizedBasePath)/\(normalizedRequestPath)"
    }

    private static func mergedHeaders(clientConfiguration: NXClientConfiguration, requestSpec: RequestSpec) -> [String: String] {
        clientConfiguration.headers.merging(requestSpec.headers) { $1 }
    }

    private static func mergedQueryItems(existing: [URLQueryItem], adding: [URLQueryItem]) -> [URLQueryItem]? {
        let queryItems = existing + adding
        return queryItems.isEmpty ? nil : queryItems
    }

    private static func appendQueryItems(url: URL, queryItems: [URLQueryItem]) -> URL {
        guard queryItems.isEmpty == false else {
            return url
        }

        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return url
        }

        let existingQueryItems = components.queryItems ?? []
        components.queryItems = existingQueryItems + queryItems
        return components.url ?? url
    }
}
