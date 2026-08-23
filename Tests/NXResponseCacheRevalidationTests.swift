//
//  NXResponseCacheRevalidationTests.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("응답 cache validator 재검증 테스트")
struct NXResponseCacheRevalidationTests {
    @Test("일치 ETag의 body 없는 304는 cached 200으로 반환한다")
    func matchingETag304UsesCachedBody() async throws {
        let attemptCounter = AttemptCounter()
        let client = makeClient(
            transport: ClosureTransport { request in
                let attemptNumber = await attemptCounter.increment()

                if attemptNumber == 1 {
                    return makeRawResponse(
                        statusCode: 200,
                        body: #"{"id":1,"name":"cached"}"#,
                        path: "/users",
                        headers: [
                            "ETag": "v1",
                            "Content-Length": "24"
                        ]
                    )
                }

                #expect(request.value(forHTTPHeaderField: "If-None-Match") == "v1")
                return makeRawResponse(
                    statusCode: 304,
                    body: "",
                    path: "/users",
                    headers: [
                        "ETag": "v1",
                        "X-Revalidated": "yes",
                        "Content-Length": "0"
                    ]
                )
            },
            cache: .revalidatingMemory(ttl: 0.01)
        )

        _ = try await client.get("/users").send()
        try await Task.sleep(nanoseconds: 20_000_000)
        let response = try await client.get("/users").send()

        #expect(response.data == Data(#"{"id":1,"name":"cached"}"#.utf8))
        #expect(response.response.statusCode == 200)
        #expect(response.response.value(forHTTPHeaderField: "ETag") == "v1")
        #expect(response.response.value(forHTTPHeaderField: "X-Revalidated") == "yes")
        #expect(response.response.value(forHTTPHeaderField: "Content-Length") == "24")
        #expect(await attemptCounter.value() == 2)
    }

    @Test("Last-Modified만 있는 cached 200을 조건부 재검증한다")
    func lastModified304UsesCachedBody() async throws {
        let attemptCounter = AttemptCounter()
        let lastModified = "Sat, 22 Aug 2026 00:00:00 GMT"
        let client = makeClient(
            transport: ClosureTransport { request in
                let attemptNumber = await attemptCounter.increment()

                if attemptNumber == 1 {
                    return makeRawResponse(
                        statusCode: 200,
                        body: #"{"id":1,"name":"cached"}"#,
                        path: "/users",
                        headers: ["Last-Modified": lastModified]
                    )
                }

                #expect(request.value(forHTTPHeaderField: "If-None-Match") == nil)
                #expect(request.value(forHTTPHeaderField: "If-Modified-Since") == lastModified)
                return makeRawResponse(
                    statusCode: 304,
                    body: "",
                    path: "/users",
                    headers: ["Last-Modified": lastModified]
                )
            },
            cache: .revalidatingMemory(ttl: 0.01)
        )

        _ = try await client.get("/users").send()
        try await Task.sleep(nanoseconds: 20_000_000)
        let response = try await client.get("/users").send()

        #expect(response.data == Data(#"{"id":1,"name":"cached"}"#.utf8))
        #expect(response.response.statusCode == 200)
        #expect(await attemptCounter.value() == 2)
    }

    @Test("불일치 ETag의 304는 cached body와 결합하지 않는다")
    func mismatchedETag304DoesNotReuseCachedBody() async throws {
        let attemptCounter = AttemptCounter()
        let client = makeClient(
            transport: ClosureTransport { request in
                let attemptNumber = await attemptCounter.increment()

                switch attemptNumber {
                case 1:
                    return makeRawResponse(
                        statusCode: 200,
                        body: #"{"id":1,"name":"cached"}"#,
                        path: "/users",
                        headers: ["ETag": "v1"]
                    )
                case 2:
                    #expect(request.value(forHTTPHeaderField: "If-None-Match") == "v1")
                    return makeRawResponse(
                        statusCode: 304,
                        body: "",
                        path: "/users",
                        headers: ["ETag": "v2"]
                    )
                default:
                    #expect(request.value(forHTTPHeaderField: "If-None-Match") == nil)
                    return makeRawResponse(
                        statusCode: 200,
                        body: #"{"id":2,"name":"updated"}"#,
                        path: "/users",
                        headers: ["ETag": "v2"]
                    )
                }
            },
            cache: .revalidatingMemory(ttl: 0.01)
        )

        _ = try await client.get("/users").send()
        try await Task.sleep(nanoseconds: 20_000_000)

        await #expect {
            let _: UserDTO = try await client.get("/users").send(as: UserDTO.self)
        } throws: { error in
            guard case NXError.invalidStatus(statusCode: 304, data: _) = error else {
                return false
            }
            return true
        }

        let user = try await client.get("/users").send(as: UserDTO.self)

        #expect(user == UserDTO(id: 2, name: "updated"))
        #expect(await attemptCounter.value() == 3)
    }

    @Test("body가 있는 304는 cached body와 결합하지 않는다")
    func bodyful304DoesNotReuseCachedBody() async throws {
        let attemptCounter = AttemptCounter()
        let client = makeClient(
            transport: ClosureTransport { _ in
                let attemptNumber = await attemptCounter.increment()

                if attemptNumber == 1 {
                    return makeRawResponse(
                        statusCode: 200,
                        body: #"{"id":1,"name":"cached"}"#,
                        path: "/users",
                        headers: ["ETag": "v1"]
                    )
                }

                return makeRawResponse(
                    statusCode: 304,
                    body: #"{"id":1,"name":"unexpected"}"#,
                    path: "/users",
                    headers: ["ETag": "v1"]
                )
            },
            cache: .revalidatingMemory(ttl: 0.01)
        )

        _ = try await client.get("/users").send()
        try await Task.sleep(nanoseconds: 20_000_000)

        await #expect {
            let _: UserDTO = try await client.get("/users").send(as: UserDTO.self)
        } throws: { error in
            guard case NXError.invalidStatus(statusCode: 304, data: _) = error else {
                return false
            }
            return true
        }
    }

    @Test("revalidation cache의 201은 TTL 뒤 무조건 요청으로 갱신한다")
    func revalidatingMemoryReloadsExpired201WithoutValidators() async throws {
        let attemptCounter = AttemptCounter()
        let client = makeClient(
            transport: ClosureTransport { request in
                let attemptNumber = await attemptCounter.increment()

                if attemptNumber == 2 {
                    #expect(request.value(forHTTPHeaderField: "If-None-Match") == nil)
                    #expect(request.value(forHTTPHeaderField: "If-Modified-Since") == nil)
                }

                return makeRawResponse(
                    statusCode: 201,
                    body: #"{"id":\#(attemptNumber),"name":"created"}"#,
                    path: "/users",
                    headers: ["ETag": "v1"]
                )
            },
            cache: .revalidatingMemory(ttl: 0.01)
        )

        let firstUser = try await client.get("/users").send(as: UserDTO.self)
        try await Task.sleep(nanoseconds: 20_000_000)
        let secondUser = try await client.get("/users").send(as: UserDTO.self)

        #expect(firstUser == UserDTO(id: 1, name: "created"))
        #expect(secondUser == UserDTO(id: 2, name: "created"))
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
