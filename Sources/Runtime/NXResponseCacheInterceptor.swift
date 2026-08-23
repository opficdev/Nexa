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
        guard case let .memory(ttl) = cache,
              0 < ttl,
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
            ttl: ttl,
            shouldCache: { rawResponse in
                200 <= rawResponse.response.statusCode && rawResponse.response.statusCode < 300
            },
            load: {
                try await next(context)
            }
        )
    }
}
