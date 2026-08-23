//
//  NXResponseCacheRevalidationBoundaryTests.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("응답 cache 재검증 경계 테스트")
struct NXResponseCacheRevalidationBoundaryTests {
    @Test("logger에는 내부 조건부 header를 기록하지 않는다")
    func loggerDoesNotRecordInternalConditionalHeaders() async throws {
        let attemptCounter = AttemptCounter()
        let logger = MemoryLogger()
        let client = makeClient(
            transport: ClosureTransport { request in
                let attemptNumber = await attemptCounter.increment()

                if attemptNumber == 1 {
                    return makeRawResponse(
                        statusCode: 200,
                        body: #"{"id":1,"name":"cached"}"#,
                        path: "/users",
                        headers: ["ETag": "v1"]
                    )
                }

                #expect(request.value(forHTTPHeaderField: "If-None-Match") == "v1")
                return makeRawResponse(
                    statusCode: 304,
                    body: "",
                    path: "/users",
                    headers: ["ETag": "v1"]
                )
            },
            logger: logger
        )

        _ = try await client.get("/users").send()
        try await Task.sleep(nanoseconds: 20_000_000)
        _ = try await client.get("/users").send()
        let startLogs = await logger.startLogs()

        #expect(startLogs.count == 2)
        #expect(startLogs[1].headers["If-None-Match"] == nil)
        #expect(startLogs[1].headers["If-Modified-Since"] == nil)
    }

    @Test("authorized GET은 validator 재검증을 사용하지 않는다")
    func authorizedGetDoesNotUseValidatorRevalidation() async throws {
        let attemptCounter = AttemptCounter()
        let tokenProvider = TokenProviderStub(currentToken: "token", refreshedToken: nil)
        let client = makeClient(
            transport: ClosureTransport { request in
                let attemptNumber = await attemptCounter.increment()

                #expect(request.value(forHTTPHeaderField: "If-None-Match") == nil)
                #expect(request.value(forHTTPHeaderField: "If-Modified-Since") == nil)
                return makeRawResponse(
                    statusCode: 200,
                    body: #"{"id":\#(attemptNumber),"name":"authorized"}"#,
                    path: "/users",
                    headers: ["ETag": "v1"]
                )
            },
            authTokenProvider: tokenProvider
        )

        let firstUser = try await client.get("/users").authorized().send(as: UserDTO.self)
        let secondUser = try await client.get("/users").authorized().send(as: UserDTO.self)

        #expect(firstUser == UserDTO(id: 1, name: "authorized"))
        #expect(secondUser == UserDTO(id: 2, name: "authorized"))
        #expect(await attemptCounter.value() == 2)
    }

    @Test("재검증 response URL을 합성 cache response에 보존한다")
    func revalidationResponseURLIsStoredWithSynthesizedResponse() async throws {
        let attemptCounter = AttemptCounter()
        let revalidationURL = URL(string: "https://example.com/redirected/users")!
        let client = makeClient(
            transport: ClosureTransport { request in
                let attemptNumber = await attemptCounter.increment()

                if attemptNumber == 1 {
                    return makeRawResponse(
                        statusCode: 200,
                        body: #"{"id":1,"name":"cached"}"#,
                        path: "/users",
                        headers: ["ETag": "v1"]
                    )
                }

                #expect(request.value(forHTTPHeaderField: "If-None-Match") == "v1")
                return makeRawResponse(
                    statusCode: 304,
                    body: "",
                    path: "/redirected/users",
                    headers: ["ETag": "v1"]
                )
            }
        )

        _ = try await client.get("/users").send()
        try await Task.sleep(nanoseconds: 20_000_000)
        let revalidatedResponse = try await client.get("/users").send()
        let cachedResponse = try await client.get("/users").send()

        #expect(revalidatedResponse.data == Data(#"{"id":1,"name":"cached"}"#.utf8))
        #expect(revalidatedResponse.response.statusCode == 200)
        #expect(revalidatedResponse.response.url == revalidationURL)
        #expect(cachedResponse.response.url == revalidationURL)
        #expect(await attemptCounter.value() == 2)
    }

    private func makeClient(
        transport: any NXHTTPTransport,
        logger: any NXLogger = NXNoopLogger(),
        authTokenProvider: (any NXAuthTokenProvider)? = nil
    ) -> NXAPIClient {
        NXAPIClient(
            configuration: NXClientConfiguration(
                baseURL: URL(string: "https://example.com")!,
                transport: transport,
                logger: logger,
                cache: .revalidatingMemory(ttl: 0.01),
                authTokenProvider: authTokenProvider
            )
        )
    }
}
