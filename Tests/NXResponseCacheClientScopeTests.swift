//
//  NXResponseCacheClientScopeTests.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("응답 cache client 범위 테스트")
struct NXResponseCacheClientScopeTests {
    @Test("별도 client는 완료된 cache를 공유하지 않고 값 복사본은 공유한다")
    func separateClientsDoNotShareCompletedCacheWhileCopiesShare() async throws {
        let attemptCounter = AttemptCounter()
        let transport = ClosureTransport { _ in
            let attemptNumber = await attemptCounter.increment()
            return makeRawResponse(
                statusCode: 200,
                body: #"{"id":\#(attemptNumber),"name":"cached"}"#,
                path: "/users"
            )
        }
        let firstClient = makeClient(transport: transport)
        let secondClient = makeClient(transport: transport)
        let copiedClient = firstClient

        let firstUser = try await firstClient.get("/users").send(as: UserDTO.self)
        let secondUser = try await secondClient.get("/users").send(as: UserDTO.self)
        let copiedUser = try await copiedClient.get("/users").send(as: UserDTO.self)

        #expect(firstUser == UserDTO(id: 1, name: "cached"))
        #expect(secondUser == UserDTO(id: 2, name: "cached"))
        #expect(copiedUser == firstUser)
        #expect(await attemptCounter.value() == 2)
    }

    @Test("별도 client는 진행 중인 GET을 공유하지 않는다")
    func separateClientsDoNotShareInFlightRequest() async throws {
        let attemptCounter = AttemptCounter()
        let transport = ClosureTransport { _ in
            _ = await attemptCounter.increment()
            try await Task.sleep(nanoseconds: 50_000_000)
            return makeRawResponse(statusCode: 200, body: #"{"id":1,"name":"cached"}"#)
        }
        let firstClient = makeClient(transport: transport)
        let secondClient = makeClient(transport: transport)

        async let firstUser = firstClient.get("/users").send(as: UserDTO.self)
        async let secondUser = secondClient.get("/users").send(as: UserDTO.self)
        _ = try await (firstUser, secondUser)

        #expect(await attemptCounter.value() == 2)
    }

    @Test("같은 client 값의 복사본은 진행 중인 GET을 공유한다")
    func copiedClientSharesInFlightRequest() async throws {
        let attemptCounter = AttemptCounter()
        let transport = ClosureTransport { _ in
            _ = await attemptCounter.increment()
            try await Task.sleep(nanoseconds: 50_000_000)
            return makeRawResponse(statusCode: 200, body: #"{"id":1,"name":"cached"}"#)
        }
        let client = makeClient(transport: transport)
        let copiedClient = client

        async let firstUser = client.get("/users").send(as: UserDTO.self)
        async let secondUser = copiedClient.get("/users").send(as: UserDTO.self)
        _ = try await (firstUser, secondUser)

        #expect(await attemptCounter.value() == 1)
    }

    private func makeClient(transport: any NXHTTPTransport) -> NXAPIClient {
        NXAPIClient(
            configuration: NXClientConfiguration(
                baseURL: URL(string: "https://example.com")!,
                transport: transport,
                cache: .memory(ttl: 10)
            )
        )
    }
}
