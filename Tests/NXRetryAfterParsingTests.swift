//
//  NXRetryAfterParsingTests.swift
//  Nexa
//
//  Created by opfic on 8/22/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("Retry-After HTTP-date 해석 테스트")
struct NXRetryAfterParsingTests {
    @Test("RFC 850 두 자리 연도는 현재 시각 기준 50년 규칙을 적용한다")
    func rfc850DateUsesHTTPDateYearRule() async throws {
        let calendar = Calendar(identifier: .gregorian)
        let referenceDate = calendar.date(
            from: DateComponents(year: 2026, month: 1, day: 1)
        )!
        let serverDate = calendar.date(
            from: DateComponents(year: 2060, month: 11, day: 6, hour: 8, minute: 49, second: 37)
        )!
        let policy = RetryPolicy(
            maxAttempts: 2,
            maximumServerDelay: .greatestFiniteMagnitude
        )

        let delay = try await retryDelay(
            header: rfc850DateString(from: serverDate),
            policy: policy,
            now: referenceDate
        )

        #expect(delay == serverDate.timeIntervalSince(referenceDate))
    }

    @Test("GMT가 아닌 Retry-After 시간대는 local backoff를 사용한다")
    func unsupportedTimezoneUsesLocalBackoff() async throws {
        let delay = try await retryDelay(
            header: "Thu, 01 Jan 1970 00:02:00 PST",
            policy: RetryPolicy(maxAttempts: 2, backoff: .fixed(4)),
            now: Date.distantPast
        )

        #expect(delay == 4)
    }

    @Test("과거 HTTP-date는 0초 지연을 사용한다")
    func pastHTTPDateUsesZeroDelay() async throws {
        let delay = try await retryDelay(
            header: "Thu, 01 Jan 1970 00:00:00 GMT",
            policy: RetryPolicy(maxAttempts: 2),
            now: Date(timeIntervalSince1970: 1)
        )

        #expect(delay == 0)
    }

    @Test("음수 Retry-After는 local backoff를 사용한다")
    func negativeRetryAfterUsesLocalBackoff() async throws {
        let delay = try await retryDelay(
            header: "-1",
            policy: RetryPolicy(maxAttempts: 2, backoff: .fixed(4)),
            now: Date.distantPast
        )

        #expect(delay == 4)
    }

    @Test("부호가 있는 Retry-After는 local backoff를 사용한다")
    func signedRetryAfterUsesLocalBackoff() async throws {
        let delay = try await retryDelay(
            header: "+1",
            policy: RetryPolicy(maxAttempts: 2, backoff: .fixed(4)),
            now: Date.distantPast
        )

        #expect(delay == 4)
    }

    @Test("큰 Retry-After 숫자는 서버 지연 상한을 사용한다")
    func overflowingRetryAfterUsesServerDelayCap() async throws {
        let delay = try await retryDelay(
            header: String(repeating: "9", count: 100),
            policy: RetryPolicy(maxAttempts: 2, maximumServerDelay: 60),
            now: Date.distantPast
        )

        #expect(delay == 60)
    }

    @Test("429와 503 외 상태 코드의 Retry-After는 local backoff를 사용한다")
    func retryAfterOutsideSupportedStatusUsesLocalBackoff() async throws {
        let delay = try await retryDelay(
            header: "120",
            policy: RetryPolicy(maxAttempts: 2, backoff: .fixed(4)),
            now: Date.distantPast,
            statusCode: 500
        )

        #expect(delay == 4)
    }

    @Test("재시도 불가 상태의 Retry-After는 추가 attempt를 만들지 않는다")
    func nonRetryableStatusDoesNotRetryWithRetryAfter() async throws {
        let recorder = RetryAfterRecorder()
        let logger = MemoryLogger()
        let counter = AttemptCounter()
        let dependencies = await recorder.dependencies(now: Date.distantPast)
        let request = URLRequest(url: URL(string: "https://example.com/users")!)
        var specification = RequestSpec(method: .get, path: "/users")
        specification.retryPolicy = RetryPolicy(maxAttempts: 2, backoff: .fixed(4))
        let context = NXRequestExecutionContext(
            request: request,
            requestIdentifier: specification.requestIdentifier,
            attemptNumber: 1,
            userInfo: specification.userInfo,
            specification: specification,
            clientConfiguration: NXClientConfiguration(
                baseURL: URL(string: "https://example.com")!,
                logger: logger
            )
        )

        let response = try await NXRetryInterceptor(dependencies: dependencies).intercept(context: context) { _ in
            _ = await counter.increment()
            return makeRawResponse(
                statusCode: 400,
                body: "{}",
                headers: ["Retry-After": "120"]
            )
        }

        #expect(response.response.statusCode == 400)
        #expect(await counter.value() == 1)
        #expect(await recorder.delays().isEmpty)
        #expect(await logger.retryLogs().isEmpty)
    }

    private func retryDelay(
        header: String,
        policy: RetryPolicy,
        now: Date,
        statusCode: Int = 429
    ) async throws -> TimeInterval {
        let recorder = RetryAfterRecorder()
        let dependencies = await recorder.dependencies(now: now)
        let request = URLRequest(url: URL(string: "https://example.com/users")!)
        var specification = RequestSpec(method: .get, path: "/users")
        specification.retryPolicy = policy
        let context = NXRequestExecutionContext(
            request: request,
            requestIdentifier: specification.requestIdentifier,
            attemptNumber: 1,
            userInfo: specification.userInfo,
            specification: specification,
            clientConfiguration: NXClientConfiguration(
                baseURL: URL(string: "https://example.com")!
            )
        )

        _ = try await NXRetryInterceptor(dependencies: dependencies).intercept(context: context) { context in
            if context.attemptNumber == 1 {
                return makeRawResponse(
                    statusCode: statusCode,
                    body: "{}",
                    headers: ["Retry-After": header]
                )
            }

            return makeRawResponse(statusCode: 200, body: "{}")
        }

        return await recorder.delays()[0]
    }

    private func rfc850DateString(from date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "EEEE',' dd-MMM-yy HH':'mm':'ss 'GMT'"
        return formatter.string(from: date)
    }
}

private actor RetryAfterRecorder {
    private var recordedDelays: [TimeInterval] = []

    func dependencies(now: Date) -> NXRetryExecutionDependencies {
        NXRetryExecutionDependencies(
            now: { now },
            sleep: { delay in
                await self.record(delay: delay)
            },
            randomUnit: { 0 }
        )
    }

    func delays() -> [TimeInterval] {
        recordedDelays
    }

    private func record(delay: TimeInterval) {
        recordedDelays.append(delay)
    }
}
