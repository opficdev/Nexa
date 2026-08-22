//
//  NXInterceptorChainTests.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("기본 인터셉터와 인터셉터 체인 테스트")
struct NXInterceptorChainTests {
    @Test("authorized 요청은 401 이후 토큰을 갱신하고 한 번 더 실행한다")
    func authorizedRequestRefreshesTokenAfterUnauthorizedResponse() async throws {
        let attemptCounter = AttemptCounter()
        let tokenProvider = TokenProviderStub(currentToken: "old-token", refreshedToken: "new-token")
        let logger = MemoryLogger()
        let client = makeClient(
            transport: ClosureTransport { request in
                let attemptNumber = await attemptCounter.increment()

                if attemptNumber == 1 {
                    #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer old-token")
                    return makeRawResponse(statusCode: 401, body: #"{"message":"expired"}"#, path: "/users/me")
                }

                #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer new-token")
                return makeRawResponse(statusCode: 200, body: #"{"id":1,"name":"opfic"}"#, path: "/users/me")
            },
            logger: logger,
            authTokenProvider: tokenProvider
        )

        let user = try await client
            .get("/users/me")
            .authorized()
            .send(as: UserDTO.self)

        #expect(user == UserDTO(id: 1, name: "opfic"))
        #expect(await attemptCounter.value() == 2)
        #expect(await tokenProvider.refreshCount() == 1)
        #expect(await logger.authRefreshLogs().count == 1)
    }

    @Test("retry 정책이 없으면 재시도하지 않는다")
    func requestWithoutRetryPolicyDoesNotRetry() async {
        let attemptCounter = AttemptCounter()
        let client = makeClient(
            transport: ClosureTransport { _ in
                _ = await attemptCounter.increment()
                throw URLError(.timedOut)
            }
        )

        await #expect {
            let _: UserDTO = try await client.get("/users").send(as: UserDTO.self)
        } throws: { error in
            guard case NXError.timeout = error else {
                return false
            }
            return true
        }

        #expect(await attemptCounter.value() == 1)
    }

    @Test("retry 정책이 있으면 실패 후 재시도한다")
    func requestWithRetryPolicyRetriesUntilSuccess() async throws {
        let attemptCounter = AttemptCounter()
        let logger = MemoryLogger()
        let client = makeClient(
            transport: ClosureTransport { _ in
                let attemptNumber = await attemptCounter.increment()

                if attemptNumber < 3 {
                    throw URLError(.timedOut)
                }

                return makeRawResponse(statusCode: 200, body: #"{"id":3,"name":"retry"}"#, path: "/users")
            },
            logger: logger
        )

        let user = try await client
            .get("/users")
            .retry(NXRetryPolicy(maxAttempts: 3))
            .send(as: UserDTO.self)

        #expect(user == UserDTO(id: 3, name: "retry"))
        #expect(await attemptCounter.value() == 3)
        #expect(await logger.retryLogs().count == 2)
    }

    @Test("전역 인터셉터와 요청 인터셉터가 순서대로 적용된다")
    func globalAndRequestInterceptorsAreApplied() async throws {
        let client = makeClient(
            transport: ClosureTransport { request in
                #expect(request.value(forHTTPHeaderField: "X-Global-Interceptor") == "global")
                #expect(request.value(forHTTPHeaderField: "X-Request-Interceptor") == "request")
                return makeRawResponse(statusCode: 200, body: #"{"id":7,"name":"chain"}"#, path: "/users")
            },
            interceptors: [HeaderInterceptor(name: "X-Global-Interceptor", value: "global")]
        )

        let user = try await client
            .get("/users")
            .intercept(HeaderInterceptor(name: "X-Request-Interceptor", value: "request"))
            .send(as: UserDTO.self)

        #expect(user == UserDTO(id: 7, name: "chain"))
    }

    @Test("로거는 민감한 헤더를 마스킹한 시작 로그를 남긴다")
    func loggerRedactsSensitiveHeaders() async throws {
        let logger = MemoryLogger()
        let tokenProvider = TokenProviderStub(currentToken: "secret-token", refreshedToken: "new-token")
        let client = makeClient(
            transport: ClosureTransport { request in
                #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer secret-token")
                return makeRawResponse(statusCode: 200, body: #"{"id":5,"name":"logger"}"#, path: "/users/me")
            },
            logger: logger,
            authTokenProvider: tokenProvider
        )

        let _: UserDTO = try await client
            .get("/users/me")
            .authorized()
            .header("Cookie", "session=abc")
            .send(as: UserDTO.self)

        let startLogs = await logger.startLogs()
        #expect(startLogs.count == 1)
        #expect(startLogs[0].headers["Authorization"] == "<redacted>")
        #expect(startLogs[0].headers["Cookie"] == "<redacted>")
    }

    @Test("APIClient send는 endpoint 응답 타입을 디코딩한다")
    func apiClientSendDecodesEndpointResponse() async throws {
        let client = makeClient(
            transport: ClosureTransport { request in
                #expect(request.url?.absoluteString == "https://example.com/users/42?include=profile")
                return makeRawResponse(statusCode: 200, body: #"{"id":42,"name":"endpoint"}"#, path: "/users/42")
            }
        )

        let user = try await client.send(UserEndpoint(identifier: 42))

        #expect(user == UserDTO(id: 42, name: "endpoint"))
    }

    private func makeClient(
        transport: any NXHTTPTransport,
        logger: any NXLogger = NXNoopLogger(),
        interceptors: [any NXHTTPInterceptor] = [],
        authTokenProvider: (any NXAuthTokenProvider)? = nil
    ) -> NXAPIClient {
        NXAPIClient(
            configuration: NXClientConfiguration(
                baseURL: URL(string: "https://example.com")!,
                transport: transport,
                logger: logger,
                interceptors: interceptors,
                authTokenProvider: authTokenProvider
            )
        )
    }
}

private struct HeaderInterceptor: NXHTTPInterceptor {
    let name: String
    let value: String

    func intercept(
        context: NXRequestExecutionContext,
        next: @escaping @Sendable (NXRequestExecutionContext) async throws -> NXRawResponse
    ) async throws -> NXRawResponse {
        var request = context.request
        request.setValue(value, forHTTPHeaderField: name)
        return try await next(context.replacingRequest(request))
    }
}
