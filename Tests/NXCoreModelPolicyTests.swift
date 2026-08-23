//
//  NXCoreModelPolicyTests.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("Core 모델과 정책 타입 테스트")
struct NXCoreModelPolicyTests {
    @Test("HTTP 메서드 rawValue가 예상값과 일치한다")
    func httpMethodRawValues() {
        #expect(NXHTTPMethod.get.rawValue == "GET")
        #expect(NXHTTPMethod.post.rawValue == "POST")
        #expect(NXHTTPMethod.put.rawValue == "PUT")
        #expect(NXHTTPMethod.patch.rawValue == "PATCH")
        #expect(NXHTTPMethod.delete.rawValue == "DELETE")
    }

    @Test("요청 바디가 data를 유지한다")
    func requestBodyStoresData() {
        let payload = Data("hello".utf8)
        let body = NXRequestBody.data(payload)

        #expect(body.data == payload)
    }

    @Test("원시 응답 모델이 데이터와 상태코드를 보존한다")
    func rawResponseStoresDataAndStatusCode() {
        let payload = Data("{}".utf8)
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        let rawResponse = NXRawResponse(data: payload, response: response)

        #expect(rawResponse.data == payload)
        #expect(rawResponse.response.statusCode == 200)
    }

    @Test("재시도 정책이 최소 시도 횟수와 backoff 지연 계산을 보장한다")
    func retryPolicyNormalizesAttemptsAndBackoff() {
        let retryPolicy = NXRetryPolicy(maxAttempts: 0, backoff: .fixed(-1))

        #expect(retryPolicy.maxAttempts == 1)

        let fixedDelay = NXRetryBackoff.fixed(-1)
        #expect(fixedDelay.delay(forAttempt: 1) == 0)

        let exponentialDelay = NXRetryBackoff.exponential(base: 0.5, maxDelay: 2)
        #expect(exponentialDelay.delay(forAttempt: 1) == 0.5)
        #expect(exponentialDelay.delay(forAttempt: 2) == 1.0)
        #expect(exponentialDelay.delay(forAttempt: 3) == 2.0)
        #expect(exponentialDelay.delay(forAttempt: 4) == 2.0)
    }

    @Test("재시도 정책이 멱등 method와 서버 지연 기본값을 제공한다")
    func retryPolicyDefaultRetrySemantics() {
        let defaultRetryPolicy = NXRetryPolicy(maxAttempts: 2)
        let retryPolicy = NXRetryPolicy(maxAttempts: 2, maximumServerDelay: -1)

        #expect(defaultRetryPolicy.allowedMethods == [.get, .head, .put, .delete, .options])
        #expect(defaultRetryPolicy.maximumServerDelay == 60)
        #expect(defaultRetryPolicy.jitter == .none)
        #expect(retryPolicy.maximumServerDelay == 0)
    }

    @Test("응답 검증 정책이 상태코드 허용 규칙을 적용한다")
    func validationPolicyAllowsExpectedStatusCodes() {
        #expect(NXValidationPolicy.none.allows(statusCode: 404) == true)
        #expect(NXValidationPolicy.successStatusCode.allows(statusCode: 200) == true)
        #expect(NXValidationPolicy.successStatusCode.allows(statusCode: 404) == false)
        #expect(NXValidationPolicy.statusCodes([201, 202]).allows(statusCode: 201) == true)
        #expect(NXValidationPolicy.statusCodes([201, 202]).allows(statusCode: 404) == false)
    }

    @Test("요청 스펙 초기화 시 기본값이 올바르게 설정된다")
    func requestSpecDefaultValues() {
        let requestSpec = RequestSpec(method: .get, path: "/users")

        #expect(requestSpec.method == .get)
        #expect(requestSpec.path == "/users")
        #expect(requestSpec.queryItems.isEmpty)
        #expect(requestSpec.headers.isEmpty)
        #expect(requestSpec.body == nil)
        #expect(requestSpec.timeout == nil)
        #expect(requestSpec.authRequirement == .none)
        #expect(requestSpec.retryPolicy == nil)
        #expect(isSuccessStatusCode(requestSpec.validationPolicy))
        #expect(requestSpec.userInfo.isEmpty)
    }

    @Test("에러 enum이 주요 케이스를 표현한다")
    func errorCases() {
        let urlError = URLError(.timedOut)

        guard case let .transport(capturedError) = NXError.transport(urlError) else {
            Issue.record("transport case mapping failed")
            return
        }
        #expect(capturedError.code == .timedOut)

        guard case let .invalidStatus(statusCode, data) = NXError.invalidStatus(
            statusCode: 500,
            data: Data("x".utf8)
        ) else {
            Issue.record("invalidStatus case mapping failed")
            return
        }
        #expect(statusCode == 500)
        #expect(data == Data("x".utf8))
    }

    private func isSuccessStatusCode(_ policy: NXValidationPolicy) -> Bool {
        if case .successStatusCode = policy {
            return true
        }
        return false
    }
}
