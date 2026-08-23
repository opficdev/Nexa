//
//  NXAuthRefreshCoordinatorTests.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("인증 토큰 갱신 coordinator 테스트")
struct NXAuthRefreshCoordinatorTests {
    @Test("동시 refresh 요청은 하나의 Task 결과와 log를 공유한다")
    func concurrentRefreshCallsShareOneTaskAndOneLog() async throws {
        let provider = DelayedTokenProvider(refreshedToken: "new-token")
        let logger = MemoryLogger()
        let coordinator = NXAuthRefreshCoordinator()

        let tokens = try await withThrowingTaskGroup(of: String?.self) { group in
            for _ in 0..<50 {
                group.addTask {
                    try await coordinator.refreshAccessToken(
                        using: provider,
                        logger: logger,
                        requestIdentifier: UUID()
                    )
                }
            }

            var tokens: [String?] = []
            for try await token in group {
                tokens.append(token)
            }
            return tokens
        }

        #expect(tokens == Array(repeating: "new-token", count: 50))
        #expect(await provider.refreshCount() == 1)
        #expect(await logger.authRefreshLogs().count == 1)
    }
}

private actor DelayedTokenProvider: NXAuthTokenProvider {
    let refreshedToken: String?
    private var refreshInvocationCount = 0

    init(refreshedToken: String?) {
        self.refreshedToken = refreshedToken
    }

    func currentAccessToken() async throws -> String? {
        nil
    }

    func refreshAccessToken() async throws -> String? {
        refreshInvocationCount += 1
        try await Task.sleep(nanoseconds: 50_000_000)
        return refreshedToken
    }

    func refreshCount() -> Int {
        refreshInvocationCount
    }
}
