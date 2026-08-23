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
        let participantGate = RefreshParticipantGate(expectedCount: 50)
        let provider = GatedTokenProvider(refreshedToken: "new-token")
        let logger = MemoryLogger()
        let coordinator = NXAuthRefreshCoordinator()

        let task = Task {
            try await withThrowingTaskGroup(of: String?.self) { group in
                for _ in 0..<50 {
                    group.addTask {
                        await participantGate.recordParticipant()
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
        await participantGate.waitForParticipants()
        await provider.waitForRefreshStart()
        await provider.releaseRefresh()
        let tokens = try await task.value

        #expect(tokens == Array(repeating: "new-token", count: 50))
        #expect(await provider.refreshCount() == 1)
        #expect(await logger.authRefreshLogs().count == 1)
    }
}

private actor GatedTokenProvider: NXAuthTokenProvider {
    let refreshedToken: String?
    private var refreshInvocationCount = 0
    private var didStartRefresh = false
    private var startContinuation: CheckedContinuation<Void, Never>?
    private var refreshContinuation: CheckedContinuation<Void, Never>?
    private var isRefreshReleased = false

    init(refreshedToken: String?) {
        self.refreshedToken = refreshedToken
    }

    func currentAccessToken() async throws -> String? {
        nil
    }

    func refreshAccessToken() async throws -> String? {
        refreshInvocationCount += 1
        didStartRefresh = true
        startContinuation?.resume()
        startContinuation = nil

        if !isRefreshReleased {
            await withCheckedContinuation { continuation in
                refreshContinuation = continuation
            }
        }

        return refreshedToken
    }

    func waitForRefreshStart() async {
        guard !didStartRefresh else {
            return
        }

        await withCheckedContinuation { continuation in
            startContinuation = continuation
        }
    }

    func releaseRefresh() {
        isRefreshReleased = true
        refreshContinuation?.resume()
        refreshContinuation = nil
    }

    func refreshCount() -> Int {
        refreshInvocationCount
    }
}

private actor RefreshParticipantGate {
    private let expectedCount: Int
    private var participantCount = 0
    private var continuation: CheckedContinuation<Void, Never>?

    init(expectedCount: Int) {
        self.expectedCount = expectedCount
    }

    func recordParticipant() {
        participantCount += 1

        guard expectedCount <= participantCount else {
            return
        }

        continuation?.resume()
        continuation = nil
    }

    func waitForParticipants() async {
        guard participantCount < expectedCount else {
            return
        }

        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }
}
