//
//  NXAuthRefreshConcurrencyTests.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("인증 토큰 갱신 동시성 테스트")
struct NXAuthRefreshConcurrencyTests {
    @Test("동시 401 오십 건은 refresh 한 번과 요청별 한 번 재전송만 수행한다")
    func concurrentUnauthorizedRequestsShareOneRefresh() async throws {
        let counter = AttemptCounter()
        let refreshStartProbe = RefreshStartProbe()
        let waiterProbe = RefreshWaiterProbe(expectedCount: 50)
        let refreshCompletionGate = RefreshCompletionGate()
        let provider = RefreshTestProvider(
            currentToken: "old-token",
            refreshResult: .success("new-token"),
            refreshStartProbe: refreshStartProbe,
            refreshCompletionGate: refreshCompletionGate
        )
        let logger = MemoryLogger()
        let client = makeClient(
            counter: counter,
            logger: logger,
            authTokenProvider: provider,
            onWaiterRegistered: {
                Task {
                    await waiterProbe.recordWaiter()
                }
            }
        )
        let request = client.get("/users/me").authorized()

        let task = Task {
            try await Self.send(request, count: 50)
        }
        await refreshStartProbe.waitForStart()
        await waiterProbe.waitForWaiters()
        await refreshCompletionGate.release()
        let users = try await task.value

        #expect(users == Array(repeating: UserDTO(id: 1, name: "refreshed"), count: 50))
        #expect(await counter.value() == 100)
        #expect(await provider.refreshCount() == 1)
        #expect(await logger.authRefreshLogs().count == 1)
    }

    @Test("같은 client 값 복사본은 진행 중인 refresh를 공유한다")
    func copiedClientSharesInFlightRefresh() async throws {
        let counter = AttemptCounter()
        let refreshStartProbe = RefreshStartProbe()
        let waiterProbe = RefreshWaiterProbe(expectedCount: 2)
        let refreshCompletionGate = RefreshCompletionGate()
        let provider = RefreshTestProvider(
            currentToken: "old-token",
            refreshResult: .success("new-token"),
            refreshStartProbe: refreshStartProbe,
            refreshCompletionGate: refreshCompletionGate
        )
        let logger = MemoryLogger()
        let client = makeClient(
            counter: counter,
            logger: logger,
            authTokenProvider: provider,
            onWaiterRegistered: {
                Task {
                    await waiterProbe.recordWaiter()
                }
            }
        )
        let copiedClient = client

        async let firstUser = client.get("/users/me").authorized().send(as: UserDTO.self)
        async let secondUser = copiedClient.get("/users/me").authorized().send(as: UserDTO.self)
        await refreshStartProbe.waitForStart()
        await waiterProbe.waitForWaiters()
        await refreshCompletionGate.release()
        let firstResult = try await firstUser
        let secondResult = try await secondUser

        #expect([firstResult, secondResult] == Array(repeating: UserDTO(id: 1, name: "refreshed"), count: 2))
        #expect(await counter.value() == 4)
        #expect(await provider.refreshCount() == 1)
        #expect(await logger.authRefreshLogs().count == 1)
    }

    @Test("동시 refresh 실패 요청은 같은 timeout 결과를 받는다")
    func concurrentUnauthorizedRequestsShareRefreshFailure() async {
        let counter = AttemptCounter()
        let refreshStartProbe = RefreshStartProbe()
        let waiterProbe = RefreshWaiterProbe(expectedCount: 50)
        let refreshCompletionGate = RefreshCompletionGate()
        let provider = RefreshTestProvider(
            currentToken: "old-token",
            refreshResult: .failure(URLError(.timedOut)),
            refreshStartProbe: refreshStartProbe,
            refreshCompletionGate: refreshCompletionGate
        )
        let logger = MemoryLogger()
        let client = makeClient(
            counter: counter,
            logger: logger,
            authTokenProvider: provider,
            onWaiterRegistered: {
                Task {
                    await waiterProbe.recordWaiter()
                }
            }
        )
        let request = client.get("/users/me").authorized()

        let task = Task {
            await Self.sendFailures(request, count: 50)
        }
        await refreshStartProbe.waitForStart()
        await waiterProbe.waitForWaiters()
        await refreshCompletionGate.release()
        let errors = await task.value

        #expect(errors.count == 50)
        #expect(errors.allSatisfy { error in
            guard case .timeout = error else {
                return false
            }
            return true
        })
        #expect(await counter.value() == 50)
        #expect(await provider.refreshCount() == 1)
        #expect(await logger.authRefreshLogs().count == 1)
    }

    @Test("nil refresh 결과는 원래 401을 재전송 없이 보존한다")
    func nilRefreshResultPreservesUnauthorizedResponse() async {
        let counter = AttemptCounter()
        let provider = RefreshTestProvider(
            currentToken: "old-token",
            refreshResult: .success(nil)
        )
        let logger = MemoryLogger()
        let client = makeClient(
            counter: counter,
            logger: logger,
            authTokenProvider: provider
        )

        await #expect {
            let _: UserDTO = try await client.get("/users/me").authorized().send(as: UserDTO.self)
        } throws: { error in
            guard case let NXError.invalidStatus(statusCode, data) = error else {
                return false
            }
            return statusCode == 401 && data == Data(#"{"message":"expired"}"#.utf8)
        }

        #expect(await counter.value() == 1)
        #expect(await provider.refreshCount() == 1)
        let logs = await logger.authRefreshLogs()
        #expect(logs.count == 1)
        #expect(!logs[0].succeeded)
    }

    @Test("호출자 취소는 공유 refresh와 다른 요청을 취소하지 않는다")
    func cancellingCallerDoesNotCancelSharedRefresh() async throws {
        let counter = AttemptCounter()
        let refreshStartProbe = RefreshStartProbe()
        let waiterProbe = RefreshWaiterProbe(expectedCount: 2)
        let refreshCompletionGate = RefreshCompletionGate()
        let provider = RefreshTestProvider(
            currentToken: "old-token",
            refreshResult: .success("new-token"),
            refreshStartProbe: refreshStartProbe,
            refreshCompletionGate: refreshCompletionGate
        )
        let logger = MemoryLogger()
        let client = makeClient(
            counter: counter,
            logger: logger,
            authTokenProvider: provider,
            onWaiterRegistered: {
                Task {
                    await waiterProbe.recordWaiter()
                }
            }
        )

        let firstTask = Task {
            try await client.get("/users/me").authorized().send(as: UserDTO.self)
        }
        await refreshStartProbe.waitForStart()

        let secondTask = Task {
            try await client.get("/users/me").authorized().send(as: UserDTO.self)
        }
        await waiterProbe.waitForWaiters()
        firstTask.cancel()

        await #expect {
            let _: UserDTO = try await firstTask.value
        } throws: { error in
            guard case .cancelled = error as? NXError else {
                return false
            }
            return true
        }
        await refreshCompletionGate.release()

        let secondUser = try await secondTask.value

        #expect(secondUser == UserDTO(id: 1, name: "refreshed"))
        #expect(await counter.value() == 3)
        #expect(await provider.refreshCount() == 1)
        #expect(await logger.authRefreshLogs().count == 1)
    }

}

private extension NXAuthRefreshConcurrencyTests {
    func makeClient(
        counter: AttemptCounter,
        logger: any NXLogger,
        authTokenProvider: any NXAuthTokenProvider,
        onWaiterRegistered: (@Sendable () -> Void)? = nil,
        onRefreshCompleted: (@Sendable () -> Void)? = nil
    ) -> NXAPIClient {
        NXAPIClient(
            configuration: NXClientConfiguration(
                baseURL: URL(string: "https://example.com")!,
                transport: ClosureTransport { request in
                    _ = await counter.increment()

                    switch request.value(forHTTPHeaderField: "Authorization") {
                    case "Bearer old-token":
                        return makeRawResponse(statusCode: 401, body: #"{"message":"expired"}"#)
                    case "Bearer new-token":
                        return makeRawResponse(statusCode: 200, body: #"{"id":1,"name":"refreshed"}"#)
                    default:
                        Issue.record("예상하지 않은 Authorization header")
                        return makeRawResponse(statusCode: 500, body: "{}")
                    }
                },
                logger: logger,
                authTokenProvider: authTokenProvider
            ),
            onWaiterRegistered: onWaiterRegistered,
            onRefreshCompleted: onRefreshCompleted
        )
    }

    static func send(_ request: NXRequestBuilder, count: Int) async throws -> [UserDTO] {
        try await withThrowingTaskGroup(of: UserDTO.self) { group in
            for _ in 0..<count {
                group.addTask {
                    try await request.send(as: UserDTO.self)
                }
            }

            var users: [UserDTO] = []
            for try await user in group {
                users.append(user)
            }
            return users
        }
    }

    static func sendFailures(_ request: NXRequestBuilder, count: Int) async -> [NXError] {
        await withTaskGroup(of: NXError?.self) { group in
            for _ in 0..<count {
                group.addTask {
                    do {
                        let _: UserDTO = try await request.send(as: UserDTO.self)
                        return nil
                    } catch let error as NXError {
                        return error
                    } catch {
                        return .unknown(error)
                    }
                }
            }

            var errors: [NXError] = []
            for await error in group {
                if let error {
                    errors.append(error)
                }
            }
            return errors
        }
    }

    func expectCancelled(_ task: Task<UserDTO, any Error>) async {
        await #expect {
            let _: UserDTO = try await task.value
        } throws: { error in
            guard case .cancelled = error as? NXError else {
                return false
            }
            return true
        }
    }
}

extension NXAuthRefreshConcurrencyTests {
    @Test("모든 취소 caller 뒤 완료된 refresh는 새 refresh를 허용한다")
    func cancelledCallersDoNotRetainCompletedRefresh() async throws {
        let counter = AttemptCounter()
        let refreshStartProbe = RefreshStartProbe()
        let waiterProbe = RefreshWaiterProbe(expectedCount: 2)
        let refreshCompletionGate = RefreshCompletionGate()
        let refreshCompletionProbe = RefreshCompletionProbe()
        let provider = RefreshTestProvider(
            currentToken: "old-token",
            refreshResult: .success("new-token"),
            refreshStartProbe: refreshStartProbe,
            refreshCompletionGate: refreshCompletionGate
        )
        let logger = MemoryLogger()
        let client = makeClient(
            counter: counter,
            logger: logger,
            authTokenProvider: provider,
            onWaiterRegistered: {
                Task {
                    await waiterProbe.recordWaiter()
                }
            },
            onRefreshCompleted: {
                Task {
                    await refreshCompletionProbe.recordCompletion()
                }
            }
        )

        let firstTask = Task {
            try await client.get("/users/me").authorized().send(as: UserDTO.self)
        }
        await refreshStartProbe.waitForStart()

        let secondTask = Task {
            try await client.get("/users/me").authorized().send(as: UserDTO.self)
        }
        await waiterProbe.waitForWaiters()
        firstTask.cancel()
        secondTask.cancel()

        await expectCancelled(firstTask)
        await expectCancelled(secondTask)
        await refreshCompletionGate.release()
        await refreshCompletionProbe.waitForCompletion()

        #expect(await provider.refreshCount() == 1)
        #expect(await logger.authRefreshLogs().count == 1)

        let user = try await client.get("/users/me").authorized().send(as: UserDTO.self)

        #expect(user == UserDTO(id: 1, name: "refreshed"))
        #expect(await counter.value() == 4)
        #expect(await provider.refreshCount() == 2)
        #expect(await logger.authRefreshLogs().count == 2)
    }
}
