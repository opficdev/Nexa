//
//  NXRetryExecutionTests.swift
//  Nexa
//
//  Created by opfic on 8/22/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("재시도 실행 순서 테스트")
struct NXRetryExecutionTests {
    @Test("status 재시도는 requestEnd 뒤 retry log와 다음 requestStart를 남긴다")
    func statusRetryPreservesLoggerOrder() async throws {
        let logger = MemoryLogger()
        let counter = AttemptCounter()
        let configuration = makeConfiguration(
            logger: logger,
            transport: ClosureTransport { _ in
                let attemptNumber = await counter.increment()

                if attemptNumber == 1 {
                    return makeRawResponse(statusCode: 503, body: "{}")
                }

                return makeRawResponse(statusCode: 200, body: "{}")
            }
        )

        _ = try await executeRaw(
            configuration: configuration,
            policy: NXRetryPolicy(maxAttempts: 2),
            dependencies: noDelayDependencies()
        )

        #expect(await retryEvents(from: logger) == [
            .requestStart(1),
            .requestEnd(1),
            .retry(2),
            .requestStart(2),
            .requestEnd(2)
        ])
    }

    @Test("전송 오류 재시도는 requestFailure 뒤 retry log를 남긴다")
    func transportFailureRetryPreservesLoggerOrder() async throws {
        let logger = MemoryLogger()
        let counter = AttemptCounter()
        let configuration = makeConfiguration(
            logger: logger,
            transport: ClosureTransport { _ in
                let attemptNumber = await counter.increment()

                if attemptNumber == 1 {
                    throw URLError(.timedOut)
                }

                return makeRawResponse(statusCode: 200, body: "{}")
            }
        )

        _ = try await executeRaw(
            configuration: configuration,
            policy: NXRetryPolicy(maxAttempts: 2),
            dependencies: noDelayDependencies()
        )

        #expect(await retryEvents(from: logger) == [
            .requestStart(1),
            .requestFailure(1),
            .retry(2),
            .requestStart(2),
            .requestEnd(2)
        ])
    }

    @Test("대기 중 취소는 다음 request start와 transport attempt를 막는다")
    func cancellationDuringRetryDelayPreventsNextAttempt() async {
        let sleeper = RetrySleepGate()
        let logger = MemoryLogger()
        let counter = AttemptCounter()
        let configuration = makeConfiguration(
            logger: logger,
            transport: ClosureTransport { _ in
                _ = await counter.increment()
                throw URLError(.timedOut)
            }
        )
        let policy = NXRetryPolicy(maxAttempts: 2, backoff: .fixed(1))
        let task = Task {
            try await executeRaw(
                configuration: configuration,
                policy: policy,
                dependencies: await sleeper.dependencies()
            )
        }

        await sleeper.waitUntilStarted()
        task.cancel()

        await #expect {
            _ = try await task.value
        } throws: { error in
            guard case NXError.cancelled = error else {
                return false
            }
            return true
        }

        #expect(await counter.value() == 1)
        #expect(await requestStartAttempts(from: logger) == [1])
    }

    private func makeConfiguration(
        logger: any NXLogger,
        transport: any NXHTTPTransport
    ) -> NXClientConfiguration {
        NXClientConfiguration(
            baseURL: URL(string: "https://example.com")!,
            transport: transport,
            logger: logger
        )
    }

    private func executeRaw(
        configuration: NXClientConfiguration,
        policy: NXRetryPolicy,
        dependencies: NXRetryExecutionDependencies
    ) async throws -> NXRawResponse {
        var specification = RequestSpec(method: .get, path: "/users")
        specification.retryPolicy = policy

        return try await NXRequestExecutor.executeRaw(
            clientConfiguration: configuration,
            responseCacheStore: nil,
            authRefreshCoordinator: NXAuthRefreshCoordinator(),
            requestSpec: specification,
            retryExecutionDependencies: dependencies
        )
    }

    private func noDelayDependencies() -> NXRetryExecutionDependencies {
        NXRetryExecutionDependencies(
            now: { Date() },
            sleep: { _ in },
            randomUnit: { 0 }
        )
    }

    private func retryEvents(from logger: MemoryLogger) async -> [RetryEvent] {
        await logger.allEvents().compactMap { event in
            switch event {
            case let .requestStart(log):
                return .requestStart(log.attemptNumber)
            case let .requestEnd(log):
                return .requestEnd(log.attemptNumber)
            case let .requestFailure(log):
                return .requestFailure(log.attemptNumber)
            case let .retry(log):
                return .retry(log.nextAttemptNumber)
            case .authRefresh:
                return nil
            }
        }
    }

    private func requestStartAttempts(from logger: MemoryLogger) async -> [Int] {
        await logger.allEvents().compactMap { event in
            guard case let .requestStart(log) = event else {
                return nil
            }
            return log.attemptNumber
        }
    }
}

private enum RetryEvent: Equatable {
    case requestStart(Int)
    case requestEnd(Int)
    case requestFailure(Int)
    case retry(Int)
}

private actor RetrySleepGate {
    private var hasStarted = false
    private var startContinuation: CheckedContinuation<Void, Never>?

    func dependencies() -> NXRetryExecutionDependencies {
        NXRetryExecutionDependencies(
            now: { Date() },
            sleep: { _ in
                await self.markStarted()
                try await Task.sleep(nanoseconds: .max)
            },
            randomUnit: { 0 }
        )
    }

    func waitUntilStarted() async {
        if hasStarted {
            return
        }

        await withCheckedContinuation { continuation in
            startContinuation = continuation
        }
    }

    private func markStarted() {
        hasStarted = true
        startContinuation?.resume()
        startContinuation = nil
    }
}
