//
//  NXRetryInterceptorTests.swift
//  Nexa
//
//  Created by opfic on 8/22/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("재시도 인터셉터 테스트")
struct NXRetryInterceptorTests {
    @Test("기본 멱등 method는 전송 오류 뒤 재시도한다", arguments: [
        NXHTTPMethod.get,
        .head,
        .put,
        .delete,
        .options
    ])
    func idempotentMethodsRetryAfterTransportFailure(method: NXHTTPMethod) async {
        #expect(await attemptCount(method: method, policy: NXRetryPolicy(maxAttempts: 2)) == 2)
    }

    @Test("POST와 PATCH는 명시 허용 전 재시도하지 않는다", arguments: [
        NXHTTPMethod.post,
        .patch
    ])
    func nonIdempotentMethodsDoNotRetryByDefault(method: NXHTTPMethod) async {
        #expect(await attemptCount(method: method, policy: NXRetryPolicy(maxAttempts: 2)) == 1)
    }

    @Test("명시 허용한 POST는 전송 오류 뒤 재시도한다")
    func optInMethodRetriesAfterTransportFailure() async {
        let policy = NXRetryPolicy(maxAttempts: 2, allowing: [.post])

        #expect(await attemptCount(method: .post, policy: policy) == 2)
    }

    private func attemptCount(method: NXHTTPMethod, policy: NXRetryPolicy) async -> Int {
        let counter = AttemptCounter()
        var request = URLRequest(url: URL(string: "https://example.com/users")!)
        request.httpMethod = method.rawValue
        var specification = RequestSpec(method: method, path: "/users")
        specification.retryPolicy = policy
        let configuration = NXClientConfiguration(
            baseURL: URL(string: "https://example.com")!
        )
        let context = NXRequestExecutionContext(
            request: request,
            requestIdentifier: specification.requestIdentifier,
            attemptNumber: 1,
            userInfo: specification.userInfo,
            specification: specification,
            clientConfiguration: configuration
        )

        do {
            _ = try await NXRetryInterceptor().intercept(context: context) { _ in
                _ = await counter.increment()
                throw URLError(.timedOut)
            }
        } catch {
            return await counter.value()
        }

        return await counter.value()
    }

}
