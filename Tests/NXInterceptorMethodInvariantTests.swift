//
//  NXInterceptorMethodInvariantTests.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("인터셉터 method 불변 계약 테스트")
struct NXInterceptorMethodInvariantTests {
    @Test("global interceptor의 GET에서 POST 변경은 전송 전에 차단한다")
    func globalInterceptorChangingGetToPostIsRejected() async {
        let counter = AttemptCounter()
        let logger = MemoryLogger()
        let client = makeClient(
            counter: counter,
            logger: logger,
            interceptors: [MethodReplacingInterceptor(method: "POST")]
        )

        await expectInvalidRequest(
            client.get("/users"),
            counter: counter,
            logger: logger
        )
    }

    @Test("request interceptor의 GET에서 PATCH 변경은 전송 전에 차단한다")
    func requestInterceptorChangingGetToPatchIsRejected() async {
        let counter = AttemptCounter()
        let logger = MemoryLogger()
        let client = makeClient(counter: counter, logger: logger)

        await expectInvalidRequest(
            client
                .get("/users")
                .intercept(MethodReplacingInterceptor(method: "PATCH")),
            counter: counter,
            logger: logger
        )
    }

    @Test("request interceptor의 POST에서 GET 변경은 전송 전에 차단한다")
    func requestInterceptorChangingPostToGetIsRejected() async {
        let counter = AttemptCounter()
        let logger = MemoryLogger()
        let client = makeClient(counter: counter, logger: logger)

        await expectInvalidRequest(
            client
                .post("/users")
                .intercept(MethodReplacingInterceptor(method: "GET")),
            counter: counter,
            logger: logger
        )
    }

    private func makeClient(
        counter: AttemptCounter,
        logger: MemoryLogger,
        interceptors: [any NXHTTPInterceptor] = []
    ) -> NXAPIClient {
        NXAPIClient(
            configuration: NXClientConfiguration(
                baseURL: URL(string: "https://example.com")!,
                transport: ClosureTransport { _ in
                    _ = await counter.increment()
                    return makeRawResponse(statusCode: 200, body: #"{"id":1,"name":"unexpected"}"#)
                },
                logger: logger,
                interceptors: interceptors,
                cache: .memory(ttl: 10)
            )
        )
    }

    private func expectInvalidRequest(
        _ builder: NXRequestBuilder,
        counter: AttemptCounter,
        logger: MemoryLogger
    ) async {
        await #expect {
            let _: UserDTO = try await builder.send(as: UserDTO.self)
        } throws: { error in
            guard case NXError.invalidRequest = error else {
                return false
            }
            return true
        }

        #expect(await counter.value() == 0)
        #expect(await logger.allEvents().isEmpty)
    }
}

private struct MethodReplacingInterceptor: NXHTTPInterceptor {
    let method: String?

    func intercept(
        context: NXRequestExecutionContext,
        next: @escaping @Sendable (NXRequestExecutionContext) async throws -> NXRawResponse
    ) async throws -> NXRawResponse {
        var request = context.request
        request.httpMethod = method
        return try await next(context.replacingRequest(request))
    }
}
