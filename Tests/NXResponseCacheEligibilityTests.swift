//
//  NXResponseCacheEligibilityTests.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("응답 cache 대상 경계 테스트")
struct NXCacheEligibilityTests {
    @Test("memory cache는 만료 뒤 validator header를 추가하지 않는다")
    func memoryCacheDoesNotAddValidatorHeaders() async throws {
        let attemptCounter = AttemptCounter()
        let client = makeClient(
            transport: ClosureTransport { request in
                let attemptNumber = await attemptCounter.increment()

                if attemptNumber == 2 {
                    #expect(request.value(forHTTPHeaderField: "If-None-Match") == nil)
                    #expect(request.value(forHTTPHeaderField: "If-Modified-Since") == nil)
                }

                return makeRawResponse(
                    statusCode: 200,
                    body: #"{"id":\#(attemptNumber),"name":"cached"}"#,
                    path: "/users",
                    headers: ["ETag": "v1"]
                )
            },
            cache: .memory(ttl: 0.01)
        )

        _ = try await client.get("/users").send()
        try await Task.sleep(nanoseconds: 20_000_000)
        let user = try await client.get("/users").send(as: UserDTO.self)

        #expect(user == UserDTO(id: 2, name: "cached"))
        #expect(await attemptCounter.value() == 2)
    }

    @Test("validator 없는 200은 재검증 header 없이 다시 요청한다")
    func validatorless200DoesNotAddValidatorHeaders() async throws {
        let attemptCounter = AttemptCounter()
        let client = makeClient(
            transport: ClosureTransport { request in
                let attemptNumber = await attemptCounter.increment()

                if attemptNumber == 2 {
                    #expect(request.value(forHTTPHeaderField: "If-None-Match") == nil)
                    #expect(request.value(forHTTPHeaderField: "If-Modified-Since") == nil)
                }

                return makeRawResponse(
                    statusCode: 200,
                    body: #"{"id":\#(attemptNumber),"name":"cached"}"#,
                    path: "/users"
                )
            },
            cache: .revalidatingMemory(ttl: 0.01)
        )

        _ = try await client.get("/users").send()
        try await Task.sleep(nanoseconds: 20_000_000)
        let user = try await client.get("/users").send(as: UserDTO.self)

        #expect(user == UserDTO(id: 2, name: "cached"))
        #expect(await attemptCounter.value() == 2)
    }

    @Test("body가 있는 GET은 재검증 cache를 사용하지 않는다")
    func getWithBodyDoesNotUseRevalidationCache() async throws {
        let attemptCounter = AttemptCounter()
        let client = makeClient(
            transport: ClosureTransport { request in
                let attemptNumber = await attemptCounter.increment()

                #expect(request.value(forHTTPHeaderField: "If-None-Match") == nil)
                return makeRawResponse(
                    statusCode: 200,
                    body: #"{"id":\#(attemptNumber),"name":"body"}"#,
                    path: "/users",
                    headers: ["ETag": "v1"]
                )
            },
            cache: .revalidatingMemory(ttl: 10)
        )

        _ = try await client.get("/users").body(Data("request".utf8)).send()
        let user = try await client.get("/users").body(Data("request".utf8)).send(as: UserDTO.self)

        #expect(user == UserDTO(id: 2, name: "body"))
        #expect(await attemptCounter.value() == 2)
    }

    @Test("POST는 재검증 cache를 사용하지 않는다")
    func postDoesNotUseRevalidationCache() async throws {
        let attemptCounter = AttemptCounter()
        let client = makeClient(
            transport: ClosureTransport { request in
                let attemptNumber = await attemptCounter.increment()

                #expect(request.value(forHTTPHeaderField: "If-None-Match") == nil)
                return makeRawResponse(
                    statusCode: 200,
                    body: #"{"id":\#(attemptNumber),"name":"posted"}"#,
                    path: "/users",
                    headers: ["ETag": "v1"]
                )
            },
            cache: .revalidatingMemory(ttl: 10)
        )

        _ = try await client.post("/users").send()
        let user = try await client.post("/users").send(as: UserDTO.self)

        #expect(user == UserDTO(id: 2, name: "posted"))
        #expect(await attemptCounter.value() == 2)
    }

    private func makeClient(
        transport: any NXHTTPTransport,
        cache: NXCache
    ) -> NXAPIClient {
        NXAPIClient(
            configuration: NXClientConfiguration(
                baseURL: URL(string: "https://example.com")!,
                transport: transport,
                cache: cache
            )
        )
    }
}
