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
    func apiClientVerbEntryPoints() {
        let client = makeClient()

        let getBuilder = client.get("/users")
        #expect(getBuilder.requestSpec.method == .get)
        #expect(getBuilder.requestSpec.path == "/users")

        let postBuilder = client.post("/users")
        #expect(postBuilder.requestSpec.method == .post)
        #expect(postBuilder.requestSpec.path == "/users")

        let deleteBuilder = client.delete("/users/1")
        #expect(deleteBuilder.requestSpec.method == .delete)
        #expect(deleteBuilder.requestSpec.path == "/users/1")
    }

    @Test("Endpoint 요청이 configure를 통해 빌더를 구성한다")
    func endpointConfiguration() {
        let client = makeClient()
        let builder = client.request(UsersEndpoint())

        #expect(builder.requestSpec.method == .get)
        #expect(builder.requestSpec.path == "/users")
        #expect(builder.requestSpec.queryItems.count == 1)
        #expect(builder.requestSpec.queryItems.first?.name == "page")
        #expect(builder.requestSpec.queryItems.first?.value == "1")
    }

    @Test("RequestBuilder modifier가 원본을 변경하지 않고 새 값을 생성한다")
    func requestBuilderValueSemantics() {
        let client = makeClient()

        let originalBuilder = client.get("/users")
        let modifiedBuilder = originalBuilder
            .query("page", 1)
            .header("X-Trace", "abc")
            .authorized()
            .timeout(-3)

        #expect(originalBuilder.requestSpec.queryItems.isEmpty)
        #expect(originalBuilder.requestSpec.headers.isEmpty)
        #expect(originalBuilder.requestSpec.authRequirement == .none)
        #expect(originalBuilder.requestSpec.timeout == nil)

        #expect(modifiedBuilder.requestSpec.queryItems.count == 1)
        #expect(modifiedBuilder.requestSpec.headers["X-Trace"] == "abc")
        #expect(modifiedBuilder.requestSpec.authRequirement == .required)
        #expect(modifiedBuilder.requestSpec.timeout == 0)
    }

    @Test("headers와 accept modifier가 헤더를 누적한다")
    func headerModifiers() {
        let client = makeClient()

        let builder = client.get("/users")
            .headers(["A": "1", "B": "2"])
            .accept("application/json")

        #expect(builder.requestSpec.headers["A"] == "1")
        #expect(builder.requestSpec.headers["B"] == "2")
        #expect(builder.requestSpec.headers["Accept"] == "application/json")
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

    func configure(_ builder: NXRequestBuilder) -> NXRequestBuilder {
        builder.query("page", 1)
    }
}
