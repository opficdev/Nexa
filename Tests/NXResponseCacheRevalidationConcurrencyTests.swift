//
//  NXResponseCacheRevalidationConcurrencyTests.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("응답 cache 재검증 동시성 테스트")
struct NXCacheRevalidationConcurrencyTests {
    @Test("만료된 동일 GET 다섯 건은 재검증 transport를 하나로 합친다")
    func identicalConcurrentExpiredGetRequestsShareRevalidatedResponse() async throws {
        let attemptCounter = AttemptCounter()
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
                try await Task.sleep(nanoseconds: 50_000_000)
                return makeRawResponse(
                    statusCode: 304,
                    body: "",
                    path: "/users",
                    headers: ["ETag": "v1"]
                )
            },
            cache: .revalidatingMemory(ttl: 0.01)
        )

        _ = try await client.get("/users").send()
        try await Task.sleep(nanoseconds: 20_000_000)
        let users = try await withThrowingTaskGroup(of: UserDTO.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    try await client.get("/users").send(as: UserDTO.self)
                }
            }

            var values: [UserDTO] = []
            for try await user in group {
                values.append(user)
            }
            return values
        }

        #expect(users == Array(repeating: UserDTO(id: 1, name: "cached"), count: 5))
        #expect(await attemptCounter.value() == 2)
    }

    @Test("취소된 재검증 waiter도 공유 결과를 반환한다")
    func cancellingRevalidationWaiterDoesNotCancelSharedResponse() async throws {
        let attemptCounter = AttemptCounter()
        let revalidationStartProbe = RevalidationStartProbe()
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

                await revalidationStartProbe.recordStart()
                try await Task.sleep(nanoseconds: 50_000_000)
                return makeRawResponse(
                    statusCode: 304,
                    body: "",
                    path: "/users",
                    headers: ["ETag": "v1"]
                )
            },
            cache: .revalidatingMemory(ttl: 0.01)
        )

        _ = try await client.get("/users").send()
        try await Task.sleep(nanoseconds: 20_000_000)
        let firstTask = Task {
            try await client.get("/users").send(as: UserDTO.self)
        }
        await revalidationStartProbe.waitForStart()
        firstTask.cancel()

        let secondUser = try await client.get("/users").send(as: UserDTO.self)
        let firstUser = try await firstTask.value

        #expect(firstUser == secondUser)
        #expect(secondUser == UserDTO(id: 1, name: "cached"))
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

private actor RevalidationStartProbe {
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
