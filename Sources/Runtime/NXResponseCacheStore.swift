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
    private var responses: [NXRequestCacheKey: CachedResponse] = [:]
    private var inFlightTasks: [NXRequestCacheKey: Task<NXRawResponse, any Error>] = [:]

    func response(
        for key: NXRequestCacheKey,
        ttl: TimeInterval,
        shouldCache: @escaping @Sendable (NXRawResponse) -> Bool,
        load: @escaping @Sendable () async throws -> NXRawResponse
    ) async throws -> NXRawResponse {
        let now = Date()

        if let cachedResponse = responses[key] {
            if now < cachedResponse.expirationDate {
                return cachedResponse.rawResponse
            }

            responses.removeValue(forKey: key)
        }

        if let task = inFlightTasks[key] {
            return try await task.value
        }

        let task = Task {
            try await load()
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
