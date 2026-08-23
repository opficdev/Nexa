//
//  NXRetryDelayTests.swift
//  Nexa
//
//  Created by opfic on 8/22/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("재시도 지연 테스트")
struct NXRetryDelayTests {
    @Test("Retry-After 초 단위는 서버 지연 상한을 적용한다", arguments: [429, 503])
    func retryAfterSecondsUsesServerDelayCap(statusCode: Int) async throws {
        let recorder = RetryExecutionRecorder()
        let logger = MemoryLogger()
        let policy = RetryPolicy(
            maxAttempts: 2,
            maximumServerDelay: 60,
            jitter: .full
        )

        _ = try await execute(
            policy: policy,
            responses: [
                makeRawResponse(
                    statusCode: statusCode,
                    body: "{}",
                    headers: ["Retry-After": "120"]
                ),
                makeRawResponse(statusCode: 200, body: "{}")
            ],
            logger: logger,
            dependencies: await recorder.dependencies(now: Date.distantPast, randomUnit: 0)
        )

        #expect(await recorder.delays() == [60])
        #expect(await logger.retryLogs().map(\.delay) == [60])
    }

    @Test("Retry-After HTTP-date는 주입된 현재 시각을 기준으로 계산한다")
    func retryAfterHTTPDateUsesInjectedCurrentTime() async throws {
        let recorder = RetryExecutionRecorder()
        let policy = RetryPolicy(maxAttempts: 2, maximumServerDelay: 180)
        let referenceDate = Date(timeIntervalSince1970: 0)

        _ = try await execute(
            policy: policy,
            responses: [
                makeRawResponse(
                    statusCode: 429,
                    body: "{}",
                    headers: ["Retry-After": "Thu, 01 Jan 1970 00:02:00 GMT"]
                ),
                makeRawResponse(statusCode: 200, body: "{}")
            ],
            dependencies: await recorder.dependencies(now: referenceDate, randomUnit: 0)
        )

        #expect(await recorder.delays() == [120])
    }

    @Test("잘못된 Retry-After는 local backoff로 복귀한다")
    func invalidRetryAfterUsesLocalBackoff() async throws {
        let recorder = RetryExecutionRecorder()
        let policy = RetryPolicy(maxAttempts: 2, backoff: .fixed(4))

        _ = try await execute(
            policy: policy,
            responses: [
                makeRawResponse(
                    statusCode: 429,
                    body: "{}",
                    headers: ["Retry-After": "later"]
                ),
                makeRawResponse(statusCode: 200, body: "{}")
            ],
            dependencies: await recorder.dependencies(now: Date.distantPast, randomUnit: 0)
        )

        #expect(await recorder.delays() == [4])
    }

    @Test("local jitter는 주입된 무작위 값으로 계산한다")
    func localJitterUsesInjectedRandomValue() async throws {
        let recorder = RetryExecutionRecorder()
        let policy = RetryPolicy(maxAttempts: 2, backoff: .fixed(4), jitter: .full)

        _ = try await execute(
            policy: policy,
            responses: [
                makeRawResponse(
                    statusCode: 500,
                    body: "{}",
                    headers: ["Retry-After": "120"]
                ),
                makeRawResponse(statusCode: 200, body: "{}")
            ],
            dependencies: await recorder.dependencies(now: Date.distantPast, randomUnit: 0.25)
        )

        #expect(await recorder.delays() == [1])
    }

    private func execute(
        policy: RetryPolicy,
        responses: [NXRawResponse],
        logger: any NXLogger = NXNoopLogger(),
        dependencies: NXRetryExecutionDependencies
    ) async throws -> NXRawResponse {
        let counter = AttemptCounter()
        let request = URLRequest(url: URL(string: "https://example.com/users")!)
        var specification = RequestSpec(method: .get, path: "/users")
        specification.retryPolicy = policy
        let configuration = NXClientConfiguration(
            baseURL: URL(string: "https://example.com")!,
            logger: logger
        )
        let context = NXRequestExecutionContext(
            request: request,
            requestIdentifier: specification.requestIdentifier,
            attemptNumber: 1,
            userInfo: specification.userInfo,
            specification: specification,
            clientConfiguration: configuration
        )

        return try await NXRetryInterceptor(dependencies: dependencies).intercept(context: context) { _ in
            let attemptNumber = await counter.increment()
            return responses[attemptNumber - 1]
        }
    }
}

private actor RetryExecutionRecorder {
    private var recordedDelays: [TimeInterval] = []

    func dependencies(now: Date, randomUnit: Double) -> NXRetryExecutionDependencies {
        NXRetryExecutionDependencies(
            now: { now },
            sleep: { delay in
                await self.record(delay: delay)
            },
            randomUnit: { randomUnit }
        )
    }

    func delays() -> [TimeInterval] {
        recordedDelays
    }

    private func record(delay: TimeInterval) {
        recordedDelays.append(delay)
    }
}
