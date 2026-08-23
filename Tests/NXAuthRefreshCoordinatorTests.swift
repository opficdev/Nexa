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
        let waiterProbe = RefreshWaiterProbe(expectedCount: 50)
        let provider = GatedTokenProvider(refreshedToken: "new-token")
        let logger = MemoryLogger()
        let coordinator = NXAuthRefreshCoordinator {
            Task {
                await waiterProbe.recordWaiter()
            }
        }

        let task = Task {
            try await withThrowingTaskGroup(of: String?.self) { group in
                for _ in 0..<50 {
                    group.addTask {
                        return try await coordinator.refreshAccessToken(
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
        }
        await provider.waitForRefreshStart()
        await waiterProbe.waitForWaiters()
        await provider.releaseRefresh()
        let tokens = try await task.value

        #expect(tokens == Array(repeating: "new-token", count: 50))
        #expect(await provider.refreshCount() == 1)
        #expect(await logger.authRefreshLogs().count == 1)
    }
}
