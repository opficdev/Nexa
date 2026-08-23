//
//  NXDeclarativeRequestDSLTests.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("선언형 요청 DSL 기본 구조 테스트")
struct NXDeclarativeRequestDSLTests {
    @Test("HTTP 메서드 진입점이 요청 스펙의 메서드와 경로를 설정한다")
    func apiClientVerbEntryPoints() async throws {
        let client = makeClient()

        let getRequest = try await client.get("/users").preparedURLRequest()
        #expect(getRequest.httpMethod == "GET")
        #expect(getRequest.url?.path == "/users")

        let postRequest = try await client.post("/users").preparedURLRequest()
        #expect(postRequest.httpMethod == "POST")
        #expect(postRequest.url?.path == "/users")

        let deleteRequest = try await client.delete("/users/1").preparedURLRequest()
        #expect(deleteRequest.httpMethod == "DELETE")
        #expect(deleteRequest.url?.path == "/users/1")
    }

    @Test("Endpoint 요청이 configure를 통해 빌더를 구성한다")
    func endpointConfiguration() async throws {
        let client = makeClient()
        let request = try await client.request(UsersEndpoint()).preparedURLRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.url?.path == "/users")
        #expect(request.url?.query == "page=1")
    }

    @Test("RequestBuilder modifier가 원본을 변경하지 않고 새 값을 생성한다")
    func requestBuilderValueSemantics() async throws {
        let client = makeClient()

        let originalBuilder = client.get("/users")
        let modifiedBuilder = originalBuilder
            .query("page", 1)
            .header("X-Trace", "abc")
            .authorized()
            .timeout(-3)

        let originalRequest = try await originalBuilder.preparedURLRequest()
        #expect(originalRequest.url?.query == nil)
        #expect(originalRequest.value(forHTTPHeaderField: "X-Trace") == nil)

        let modifiedRequest = try await modifiedBuilder.preparedURLRequest()
        #expect(modifiedRequest.url?.query == "page=1")
        #expect(modifiedRequest.value(forHTTPHeaderField: "X-Trace") == "abc")
        #expect(modifiedRequest.timeoutInterval == 0)
    }

    @Test("headers와 accept modifier가 헤더를 누적한다")
    func headerModifiers() async throws {
        let client = makeClient()

        let request = try await client.get("/users")
            .headers(["A": "1", "B": "2"])
            .accept("application/json")
            .preparedURLRequest()

        #expect(request.value(forHTTPHeaderField: "A") == "1")
        #expect(request.value(forHTTPHeaderField: "B") == "2")
        #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
    }

    private func makeClient() -> NXAPIClient {
        NXAPIClient(
            configuration: NXClientConfiguration(
                baseURL: URL(string: "https://example.com")!
            )
        )
    }
}

private struct UsersEndpoint: NXEndpoint {
    typealias Response = [String]

    var method: NXHTTPMethod { .get }
    var path: String { "/users" }

    func configure(_ builder: NXTypedRequestBuilder<Response>) -> NXTypedRequestBuilder<Response> {
        builder.query("page", 1)
    }
}
