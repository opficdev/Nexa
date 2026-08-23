//
//  NXRetryBuilderAPITests.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("재시도 builder API 테스트")
struct NXRetryBuilderAPITests {
    @Test("allowing은 기본 GET 재시도를 유지한다")
    func allowingPreservesDefaultGetRetry() async throws {
        let counter = AttemptCounter()
        let client = makeClient { _ in
            let attemptNumber = await counter.increment()

            if attemptNumber < 3 {
                throw URLError(.timedOut)
            }

            return makeRawResponse(statusCode: 200, body: #"{"id":3,"name":"retry"}"#)
        }

        let user = try await client
            .get("/users")
            .retry(maxAttempts: 3, allowing: [.post])
            .send(as: UserDTO.self)

        #expect(user == UserDTO(id: 3, name: "retry"))
        #expect(await counter.value() == 3)
    }

    @Test("기본 POST 재시도는 실행하지 않는다")
    func defaultPostDoesNotRetry() async {
        let counter = AttemptCounter()
        let client = makeClient { _ in
            _ = await counter.increment()
            throw URLError(.timedOut)
        }

        await #expect {
            let _: UserDTO = try await client
                .post("/users")
                .retry(maxAttempts: 3)
                .send(as: UserDTO.self)
        } throws: { error in
            guard case NXError.timeout = error else {
                return false
            }
            return true
        }

        #expect(await counter.value() == 1)
    }

    @Test("allowing POST는 재시도를 허용한다")
    func allowingPostRetriesUntilMaximumAttempts() async throws {
        let counter = AttemptCounter()
        let client = makeClient { _ in
            let attemptNumber = await counter.increment()

            if attemptNumber < 3 {
                throw URLError(.timedOut)
            }

            return makeRawResponse(statusCode: 200, body: #"{"id":3,"name":"created"}"#)
        }

        let user = try await client
            .post("/users")
            .retry(maxAttempts: 3, allowing: [.post])
            .send(as: UserDTO.self)

        #expect(user == UserDTO(id: 3, name: "created"))
        #expect(await counter.value() == 3)
    }

    @Test("typed builder는 모든 retry parameter를 내부 정책에 전달한다")
    func typedBuilderForwardsRetryParameters() async throws {
        let client = makeClient { _ in
            makeRawResponse(statusCode: 200, body: #"{"id":1,"name":"typed"}"#)
        }
        let builder = client
            .request(RetryingGetEndpoint())
            .retry(
                maxAttempts: 0,
                backoff: .exponential(base: 0.5, maxDelay: 2),
                retryableStatusCodes: [418],
                allowing: [.post],
                maximumServerDelay: 0,
                jitter: .full
            )

        guard let retryPolicy = builder.retryPolicy else {
            Issue.record("retry policy missing")
            return
        }

        #expect(retryPolicy.maxAttempts == 1)
        #expect(retryPolicy.backoff.delay(forAttempt: 3) == 2)
        #expect(retryPolicy.retryableStatusCodes == [418])
        #expect(retryPolicy.allowedMethods == [.get, .head, .put, .delete, .options, .post])
        #expect(retryPolicy.maximumServerDelay == 0)
        #expect(retryPolicy.jitter == .full)
    }

    @Test("typed builder는 custom status 재시도를 실행한다")
    func typedBuilderRetriesCustomStatus() async throws {
        let counter = AttemptCounter()
        let client = makeClient { _ in
            let attemptNumber = await counter.increment()

            if attemptNumber == 1 {
                return makeRawResponse(statusCode: 418, body: "{}")
            }

            return makeRawResponse(statusCode: 200, body: #"{"id":2,"name":"typed"}"#)
        }

        let user = try await client
            .request(RetryingGetEndpoint())
            .retry(maxAttempts: 2, retryableStatusCodes: [418])
            .send()

        #expect(user == UserDTO(id: 2, name: "typed"))
        #expect(await counter.value() == 2)
    }

    @Test("endpoint configure는 typed retry builder를 유지한다")
    func endpointConfigureUsesTypedRetryBuilder() async throws {
        let counter = AttemptCounter()
        let client = makeClient { _ in
            let attemptNumber = await counter.increment()

            if attemptNumber == 1 {
                throw URLError(.timedOut)
            }

            return makeRawResponse(statusCode: 200, body: #"{"id":2,"name":"endpoint"}"#)
        }

        let user = try await client.request(RetryingPostEndpoint()).send()

        #expect(user == UserDTO(id: 2, name: "endpoint"))
        #expect(await counter.value() == 2)
    }

    private func makeClient(
        transport: @escaping @Sendable (URLRequest) async throws -> NXRawResponse
    ) -> NXAPIClient {
        NXAPIClient(
            configuration: NXClientConfiguration(
                baseURL: URL(string: "https://example.com")!,
                transport: ClosureTransport(sendClosure: transport)
            )
        )
    }
}

private struct RetryingPostEndpoint: NXEndpoint {
    typealias Response = UserDTO

    var method: NXHTTPMethod { .post }
    var path: String { "/users" }

    func configure(_ builder: NXTypedRequestBuilder<UserDTO>) -> NXTypedRequestBuilder<UserDTO> {
        builder.retry(maxAttempts: 2, allowing: [.post])
    }
}

private struct RetryingGetEndpoint: NXEndpoint {
    typealias Response = UserDTO

    var method: NXHTTPMethod { .get }
    var path: String { "/users" }
}
