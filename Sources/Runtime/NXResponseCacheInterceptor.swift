//
//  NXResponseCacheInterceptor.swift
//  Nexa
//
//  Created by opfic on 6/19/26.
//

import Foundation

struct NXResponseCacheInterceptor: NXHTTPInterceptor {
    let cache: NXCache
    let store: NXResponseCacheStore

    func intercept(
        context: NXRequestExecutionContext,
        next: @escaping @Sendable (NXRequestExecutionContext) async throws -> NXRawResponse
    ) async throws -> NXRawResponse {
        let cachePolicy: (ttl: TimeInterval, revalidatesExpiredResponse: Bool)? = switch cache {
        case let .memory(ttl):
            (ttl, false)
        case let .revalidatingMemory(ttl):
            (ttl, true)
        case .disabled:
            nil
        }

        guard let cachePolicy,
              0 < cachePolicy.ttl,
              context.specification.method == .get,
              context.specification.authRequirement == .none,
              context.specification.body == nil else {
            return try await next(context)
        }

        guard let key = NXRequestCacheKey(request: context.request) else {
            return try await next(context)
        }

        return try await store.response(
            for: key,
            ttl: cachePolicy.ttl,
            revalidatesExpiredResponse: cachePolicy.revalidatesExpiredResponse,
            shouldCache: { rawResponse in
                200 <= rawResponse.response.statusCode && rawResponse.response.statusCode < 300
            },
            load: { revalidationContext in
                var request = context.request

                if let entityTag = revalidationContext?.validators.entityTag {
                    request.setValue(entityTag, forHTTPHeaderField: "If-None-Match")
                }

                if let lastModified = revalidationContext?.validators.lastModified {
                    request.setValue(lastModified, forHTTPHeaderField: "If-Modified-Since")
                }

                let rawResponse = try await next(context.replacingRequest(request))
                return Self.revalidatedResponse(
                    rawResponse: rawResponse,
                    revalidationContext: revalidationContext
                )
            }
        )
    }

    private static func revalidatedResponse(
        rawResponse: NXRawResponse,
        revalidationContext: NXCacheRevalidationContext?
    ) -> NXRawResponse {
        guard rawResponse.response.statusCode == 304,
              rawResponse.data.isEmpty,
              let revalidationContext,
              validatorsMatch(
                  cached: revalidationContext.validators,
                  response: rawResponse.response
              ),
              let url = rawResponse.response.url ?? revalidationContext.cachedResponse.response.url,
              let response = HTTPURLResponse(
                  url: url,
                  statusCode: 200,
                  httpVersion: nil,
                  headerFields: mergedHeaderFields(
                      cached: revalidationContext.cachedResponse.response,
                      revalidation: rawResponse.response
                  )
              ) else {
            return rawResponse
        }

        return NXRawResponse(
            data: revalidationContext.cachedResponse.data,
            response: response
        )
    }

    private static func validatorsMatch(
        cached: NXResponseCacheValidators,
        response: HTTPURLResponse
    ) -> Bool {
        if let entityTag = cached.entityTag {
            return entityTag == response.value(forHTTPHeaderField: "ETag")
        }

        guard let lastModified = cached.lastModified else {
            return false
        }

        return lastModified == response.value(forHTTPHeaderField: "Last-Modified")
    }

    private static func mergedHeaderFields(
        cached: HTTPURLResponse,
        revalidation: HTTPURLResponse
    ) -> [String: String] {
        var headerFields = stringHeaderFields(from: cached)

        for (name, value) in stringHeaderFields(from: revalidation) {
            guard name.caseInsensitiveCompare("Content-Length") != .orderedSame else {
                continue
            }

            let replacedNames = headerFields.keys.filter {
                $0.caseInsensitiveCompare(name) == .orderedSame
            }
            replacedNames.forEach { headerFields.removeValue(forKey: $0) }
            headerFields[name] = value
        }

        return headerFields
    }

    private static func stringHeaderFields(from response: HTTPURLResponse) -> [String: String] {
        response.allHeaderFields.reduce(into: [:]) { headerFields, entry in
            guard let name = entry.key as? String else {
                return
            }

            headerFields[name] = String(describing: entry.value)
        }
    }
}
