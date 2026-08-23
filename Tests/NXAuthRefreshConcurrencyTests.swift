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
        let provider = RefreshTestProvider(
            currentToken: "old-token",
            refreshResult: .success("new-token")
        )
        let logger = MemoryLogger()
        let client = makeClient(
            counter: counter,
            logger: logger,
            authTokenProvider: provider
        )
        let request = client.get("/users/me").authorized()

        let users = try await send(request, count: 50)

        #expect(users == Array(repeating: UserDTO(id: 1, name: "refreshed"), count: 50))
        #expect(await counter.value() == 100)
        #expect(await provider.refreshCount() == 1)
        #expect(await logger.authRefreshLogs().count == 1)
    }

    @Test("같은 client 값 복사본은 진행 중인 refresh를 공유한다")
    func copiedClientSharesInFlightRefresh() async throws {
        let counter = AttemptCounter()
        let provider = RefreshTestProvider(
            currentToken: "old-token",
            refreshResult: .success("new-token")
        )
        let logger = MemoryLogger()
        let client = makeClient(
            counter: counter,
            logger: logger,
            authTokenProvider: provider
        )
        let copiedClient = client

        async let firstUser = client.get("/users/me").authorized().send(as: UserDTO.self)
        async let secondUser = copiedClient.get("/users/me").authorized().send(as: UserDTO.self)
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
        let provider = RefreshTestProvider(
            currentToken: "old-token",
            refreshResult: .failure(URLError(.timedOut))
        )
        let logger = MemoryLogger()
        let client = makeClient(
            counter: counter,
            logger: logger,
            authTokenProvider: provider
        )
        let request = client.get("/users/me").authorized()

        let errors = await sendFailures(request, count: 50)

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
        let provider = RefreshTestProvider(
            currentToken: "old-token",
            refreshResult: .success("new-token"),
            refreshStartProbe: refreshStartProbe
        )
        let logger = MemoryLogger()
        let client = makeClient(
            counter: counter,
            logger: logger,
            authTokenProvider: provider
        )

        let firstTask = Task {
            try await client.get("/users/me").authorized().send(as: UserDTO.self)
        }
        await refreshStartProbe.waitForStart()
        firstTask.cancel()

        let secondUser = try await client.get("/users/me").authorized().send(as: UserDTO.self)
        _ = try? await firstTask.value

        #expect(secondUser == UserDTO(id: 1, name: "refreshed"))
        #expect(await counter.value() == 4)
        #expect(await provider.refreshCount() == 1)
        #expect(await logger.authRefreshLogs().count == 1)
    }

    private func makeClient(
        counter: AttemptCounter,
        logger: any NXLogger,
        authTokenProvider: any NXAuthTokenProvider
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
            )
        )
    }

    private func send(_ request: NXRequestBuilder, count: Int) async throws -> [UserDTO] {
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

    private func sendFailures(_ request: NXRequestBuilder, count: Int) async -> [NXError] {
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
}

private actor RefreshTestProvider: NXAuthTokenProvider {
    private let currentToken: String?
    private let refreshResult: Result<String?, URLError>
    private let refreshStartProbe: RefreshStartProbe?
    private var refreshInvocationCount = 0

    init(
        currentToken: String?,
        refreshResult: Result<String?, URLError>,
        refreshStartProbe: RefreshStartProbe? = nil
    ) {
        self.currentToken = currentToken
        self.refreshResult = refreshResult
        self.refreshStartProbe = refreshStartProbe
    }

    func currentAccessToken() async throws -> String? {
        currentToken
    }

    func refreshAccessToken() async throws -> String? {
        refreshInvocationCount += 1
        await refreshStartProbe?.recordStart()
        try await Task.sleep(nanoseconds: 50_000_000)
        return try refreshResult.get()
    }

    func refreshCount() -> Int {
        refreshInvocationCount
    }
}

private actor RefreshStartProbe {
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
