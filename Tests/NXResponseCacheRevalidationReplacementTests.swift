//
//  NXResponseCacheRevalidationReplacementTests.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("응답 cache 재검증 교체 테스트")
struct NXCacheRevalidationReplacementTests {
    @Test("변경된 200은 body와 ETag를 교체한다")
    func changed200ReplacesBodyAndETag() async throws {
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
                        statusCode: 200,
                        body: #"{"id":2,"name":"updated"}"#,
                        path: "/users",
                        headers: ["ETag": "v2"]
                    )
                default:
                    #expect(request.value(forHTTPHeaderField: "If-None-Match") == "v2")
                    return makeRawResponse(
                        statusCode: 304,
                        body: "",
                        path: "/users",
                        headers: ["ETag": "v2"]
                    )
                }
            }
        )

        let firstUser = try await client.get("/users").send(as: UserDTO.self)
        try await Task.sleep(nanoseconds: 20_000_000)
        let secondUser = try await client.get("/users").send(as: UserDTO.self)
        try await Task.sleep(nanoseconds: 20_000_000)
        let thirdUser = try await client.get("/users").send(as: UserDTO.self)

        #expect(firstUser == UserDTO(id: 1, name: "cached"))
        #expect(secondUser == UserDTO(id: 2, name: "updated"))
        #expect(thirdUser == secondUser)
        #expect(await attemptCounter.value() == 3)
    }

    @Test("재검증 실패 뒤 stale response를 복원하지 않는다")
    func revalidationFailureDoesNotRestoreStaleResponse() async throws {
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

                throw URLError(.timedOut)
            }
        )

        _ = try await client.get("/users").send()
        try await Task.sleep(nanoseconds: 20_000_000)

        for _ in 0..<2 {
            await #expect {
                let _: UserDTO = try await client.get("/users").send(as: UserDTO.self)
            } throws: { error in
                guard case NXError.timeout = error else {
                    return false
                }
                return true
            }
        }

        #expect(await attemptCounter.value() == 3)
    }

    private func makeClient(transport: any NXHTTPTransport) -> NXAPIClient {
        NXAPIClient(
            configuration: NXClientConfiguration(
                baseURL: URL(string: "https://example.com")!,
                transport: transport,
                cache: .revalidatingMemory(ttl: 0.01)
            )
        )
    }
}
