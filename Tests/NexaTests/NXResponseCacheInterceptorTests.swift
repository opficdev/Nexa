//
//  NXResponseCacheInterceptorTests.swift
//  Nexa
//
//  Created by opfic on 6/19/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("응답 캐시와 중복 요청 방지 테스트")
struct NXResponseCacheInterceptorTests {
    @Test("동일한 GET 요청이 동시에 실행되면 transport 호출을 하나로 합친다")
    func identicalConcurrentGetRequestsShareInFlightResponse() async throws {
        let attemptCounter = AttemptCounter()
        let client = makeClient(
            transport: ClosureTransport { _ in
                _ = await attemptCounter.increment()
                try await Task.sleep(nanoseconds: 50_000_000)
                return makeRawResponse(statusCode: 200, body: #"{"id":1,"name":"cached"}"#, path: "/users")
            },
            cache: .memory(ttl: 10)
        )

        let users = try await withThrowingTaskGroup(of: UserDTO.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    try await client.get("/users").send(as: UserDTO.self)
                }
            }

            var values: [UserDTO] = []
            for try await value in group {
                values.append(value)
            }
            return values
        }

        #expect(users == Array(repeating: UserDTO(id: 1, name: "cached"), count: 5))
        #expect(await attemptCounter.value() == 1)
    }

    @Test("TTL 안의 동일한 GET 요청은 캐시 응답을 반환한다")
    func identicalGetRequestWithinTTLUsesCachedResponse() async throws {
        let attemptCounter = AttemptCounter()
        let client = makeClient(
            transport: ClosureTransport { _ in
                let attemptNumber = await attemptCounter.increment()
                return makeRawResponse(
                    statusCode: 200,
                    body: #"{"id":\#(attemptNumber),"name":"cached"}"#,
                    path: "/users"
                )
            },
            cache: .memory(ttl: 10)
        )

        let firstUser = try await client.get("/users").send(as: UserDTO.self)
        let secondUser = try await client.get("/users").send(as: UserDTO.self)

        #expect(firstUser == UserDTO(id: 1, name: "cached"))
        #expect(secondUser == firstUser)
        #expect(await attemptCounter.value() == 1)
    }

    @Test("호출자 Task 취소는 진행 중인 동일 GET 요청을 제거하지 않는다")
    func cancellingCallerTaskDoesNotRemoveInFlightResponse() async throws {
        let attemptCounter = AttemptCounter()
        let requestStartProbe = RequestStartProbe()
        let client = makeClient(
            transport: ClosureTransport { _ in
                _ = await attemptCounter.increment()
                await requestStartProbe.recordStart()
                try await Task.sleep(nanoseconds: 50_000_000)
                return makeRawResponse(statusCode: 200, body: #"{"id":1,"name":"cached"}"#, path: "/users")
            },
            cache: .memory(ttl: 10)
        )

        let firstTask = Task {
            try await client.get("/users").send(as: UserDTO.self)
        }
        await requestStartProbe.waitForStart()
        firstTask.cancel()

        let secondUser = try await client.get("/users").send(as: UserDTO.self)
        _ = try? await firstTask.value

        #expect(secondUser == UserDTO(id: 1, name: "cached"))
        #expect(await attemptCounter.value() == 1)
    }

    @Test("TTL이 지난 GET 요청은 새로 실행한다")
    func getRequestAfterTTLExecutesAgain() async throws {
        let attemptCounter = AttemptCounter()
        let client = makeClient(
            transport: ClosureTransport { _ in
                let attemptNumber = await attemptCounter.increment()
                return makeRawResponse(
                    statusCode: 200,
                    body: #"{"id":\#(attemptNumber),"name":"cached"}"#,
                    path: "/users"
                )
            },
            cache: .memory(ttl: 0.01)
        )

        let firstUser = try await client.get("/users").send(as: UserDTO.self)
        try await Task.sleep(nanoseconds: 20_000_000)
        let secondUser = try await client.get("/users").send(as: UserDTO.self)

        #expect(firstUser == UserDTO(id: 1, name: "cached"))
        #expect(secondUser == UserDTO(id: 2, name: "cached"))
        #expect(await attemptCounter.value() == 2)
    }

    @Test("TTL이 지난 캐시 응답은 실패한 재요청에 재사용하지 않는다")
    func expiredCacheResponseIsNotReusedAfterReloadFailure() async throws {
        let attemptCounter = AttemptCounter()
        let client = makeClient(
            transport: ClosureTransport { _ in
                let attemptNumber = await attemptCounter.increment()

                if attemptNumber == 1 {
                    return makeRawResponse(
                        statusCode: 200,
                        body: #"{"id":1,"name":"cached"}"#,
                        path: "/users"
                    )
                }

                throw URLError(.timedOut)
            },
            cache: .memory(ttl: 0.01)
        )

        let firstUser = try await client.get("/users").send(as: UserDTO.self)
        try await Task.sleep(nanoseconds: 20_000_000)

        await #expect {
            let _: UserDTO = try await client.get("/users").send(as: UserDTO.self)
        } throws: { error in
            guard case NXError.timeout = error else {
                return false
            }
            return true
        }

        #expect(firstUser == UserDTO(id: 1, name: "cached"))
        #expect(await attemptCounter.value() == 2)
    }

    @Test("POST 요청은 캐시하지 않는다")
    func postRequestDoesNotUseCache() async throws {
        let attemptCounter = AttemptCounter()
        let client = makeClient(
            transport: ClosureTransport { _ in
                let attemptNumber = await attemptCounter.increment()
                return makeRawResponse(
                    statusCode: 200,
                    body: #"{"id":\#(attemptNumber),"name":"posted"}"#,
                    path: "/users"
                )
            },
            cache: .memory(ttl: 10)
        )

        let firstUser = try await client.post("/users").send(as: UserDTO.self)
        let secondUser = try await client.post("/users").send(as: UserDTO.self)

        #expect(firstUser == UserDTO(id: 1, name: "posted"))
        #expect(secondUser == UserDTO(id: 2, name: "posted"))
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

private actor RequestStartProbe {
    private var didStart = false
    private var continuations: [CheckedContinuation<Void, Never>] = []

    func recordStart() {
        didStart = true
        continuations.forEach { continuation in
            continuation.resume()
        }
        continuations.removeAll()
    }

    func waitForStart() async {
        if didStart {
            return
        }

        await withCheckedContinuation { continuation in
            continuations.append(continuation)
        }
    }
}
