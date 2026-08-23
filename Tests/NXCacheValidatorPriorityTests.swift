//
//  NXCacheValidatorPriorityTests.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("응답 cache validator 우선순위 테스트")
struct NXCacheValidatorPriorityTests {
    @Test("ETag와 Last-Modified가 함께 있으면 ETag 일치를 우선한다")
    func eTagTakesPrecedenceOverLastModified() async throws {
        let attemptCounter = AttemptCounter()
        let cachedLastModified = "Sat, 22 Aug 2026 00:00:00 GMT"
        let responseLastModified = "Sun, 23 Aug 2026 00:00:00 GMT"
        let client = NXAPIClient(
            configuration: NXClientConfiguration(
                baseURL: URL(string: "https://example.com")!,
                transport: ClosureTransport { request in
                    let attemptNumber = await attemptCounter.increment()

                    if attemptNumber == 1 {
                        return makeRawResponse(
                            statusCode: 200,
                            body: #"{"id":1,"name":"cached"}"#,
                            path: "/users",
                            headers: [
                                "ETag": "v1",
                                "Last-Modified": cachedLastModified
                            ]
                        )
                    }

                    #expect(request.value(forHTTPHeaderField: "If-None-Match") == "v1")
                    #expect(request.value(forHTTPHeaderField: "If-Modified-Since") == cachedLastModified)
                    return makeRawResponse(
                        statusCode: 304,
                        body: "",
                        path: "/users",
                        headers: [
                            "ETag": "v1",
                            "Last-Modified": responseLastModified
                        ]
                    )
                },
                cache: .revalidatingMemory(ttl: 0.01)
            )
        )

        _ = try await client.get("/users").send()
        try await Task.sleep(nanoseconds: 20_000_000)
        let response = try await client.get("/users").send()

        #expect(response.data == Data(#"{"id":1,"name":"cached"}"#.utf8))
        #expect(response.response.statusCode == 200)
        #expect(response.response.value(forHTTPHeaderField: "Last-Modified") == responseLastModified)
    }
}
