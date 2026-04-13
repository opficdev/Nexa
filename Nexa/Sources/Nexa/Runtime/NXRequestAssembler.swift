//
//  NXRequestAssembler.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation

enum RequestAssembler {
    static func compile(clientConfiguration: NXClientConfiguration, requestSpec: RequestSpec) throws -> URLRequest {
        let compiledURL = try compileURL(baseURL: clientConfiguration.baseURL, requestSpec: requestSpec)
        var request = URLRequest(url: compiledURL)
        request.httpMethod = requestSpec.method.rawValue

        mergedHeaders(clientConfiguration: clientConfiguration, requestSpec: requestSpec).forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }

        if let requestBody = requestSpec.body {
            request.httpBody = requestBody.data
        }

        if let timeout = requestSpec.timeout {
            request.timeoutInterval = timeout
        }

        return request
    }

    static func compileURL(baseURL: URL, requestSpec: RequestSpec) throws -> URL {
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
        let trimmedBasePath = basePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let trimmedRequestPath = requestPath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        if trimmedBasePath.isEmpty {
            return "/\(trimmedRequestPath)"
        }

        if trimmedRequestPath.isEmpty {
            return "/\(trimmedBasePath)"
        }

        return "/\(trimmedBasePath)/\(trimmedRequestPath)"
    }

    private static func mergedHeaders(clientConfiguration: NXClientConfiguration, requestSpec: RequestSpec) -> [String: String] {
        var headerValues = clientConfiguration.headers
        requestSpec.headers.forEach { key, value in
            headerValues[key] = value
        }
        return headerValues
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
