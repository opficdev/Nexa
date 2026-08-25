//
//  NXResponseCacheStore.swift
//  Nexa
//
//  Created by opfic on 6/19/26.
//

import Foundation

struct NXResponseCacheValidators: Sendable {
    let entityTag: String?
    let lastModified: String?

    init?(response: HTTPURLResponse) {
        let entityTag = response.value(forHTTPHeaderField: "ETag")
        let lastModified = response.value(forHTTPHeaderField: "Last-Modified")

        guard entityTag != nil || lastModified != nil else {
            return nil
        }

        self.entityTag = entityTag
        self.lastModified = lastModified
    }
}

struct NXCacheRevalidationContext: Sendable {
    let cachedResponse: NXRawResponse
    let validators: NXResponseCacheValidators
}

actor NXResponseCacheStore {
    // cache key별 응답과 만료 시각 보관 store
    private var responses: [NXRequestCacheKey: CachedResponse] = [:]
    // cache key별 진행 중 요청 task 보관 store
    private var inFlightTasks: [NXRequestCacheKey: Task<NXRawResponse, any Error>] = [:]

    // cache 조회와 저장을 조정하는 메서드
    func response(
        for key: NXRequestCacheKey,
        ttl: TimeInterval,
        revalidatesExpiredResponse: Bool,
        shouldCache: @escaping @Sendable (NXRawResponse) -> Bool,
        load: @escaping @Sendable (NXCacheRevalidationContext?) async throws -> NXRawResponse
    ) async throws -> NXRawResponse {
        let now = Date()
        // 만료 응답과 validator 전달 revalidation context
        var revalidationContext: NXCacheRevalidationContext?

        if let cachedResponse = responses[key] {
            if now < cachedResponse.expirationDate {
                return cachedResponse.rawResponse
            }

            responses.removeValue(forKey: key)

            if revalidatesExpiredResponse,
               cachedResponse.rawResponse.response.statusCode == 200,
               let validators = cachedResponse.validators {
                revalidationContext = NXCacheRevalidationContext(
                    cachedResponse: cachedResponse.rawResponse,
                    validators: validators
                )
            }
        }

        if let task = inFlightTasks[key] {
            return try await task.value
        }

        let task = Task {
            try await load(revalidationContext)
        }
        inFlightTasks[key] = task

        do {
            let rawResponse = try await task.value
            inFlightTasks[key] = nil

            if shouldCache(rawResponse) {
                responses[key] = CachedResponse(
                    rawResponse: rawResponse,
                    expirationDate: Date().addingTimeInterval(ttl),
                    validators: rawResponse.response.statusCode == 200
                        ? NXResponseCacheValidators(response: rawResponse.response)
                        : nil
                )
            }

            return rawResponse
        } catch {
            inFlightTasks[key] = nil
            throw error
        }
    }

    private struct CachedResponse: Sendable {
        let rawResponse: NXRawResponse
        let expirationDate: Date
        let validators: NXResponseCacheValidators?
    }
}
