//
//  NXRequestBuildLogicTests.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("요청 빌드 로직 테스트")
struct NXRequestBuildLogicTests {
    @Test("상대 경로 요청을 URLRequest로 조립한다")
    func assemblesRelativePathRequest() async throws {
        let client = makeClient(baseURL: URL(string: "https://example.com/api")!)
        let builder = client.post("/users")

        let request = try await builder
            .query("page", 1)
            .header("X-Trace", "abc")
            .timeout(5)
            .body(Data("hello".utf8))
            .contentType("text/plain")
            .preparedURLRequest()

        #expect(request.httpMethod == "POST")
        #expect(request.url?.absoluteString == "https://example.com/api/users?page=1")
        #expect(request.value(forHTTPHeaderField: "X-Global") == "global")
        #expect(request.value(forHTTPHeaderField: "X-Trace") == "abc")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "text/plain")
        #expect(request.timeoutInterval == 5)
        #expect(request.httpBody == Data("hello".utf8))
    }

    @Test("절대 경로 요청은 baseURL 대신 절대 경로를 사용한다")
    func assemblesAbsolutePathRequest() async throws {
        let client = makeClient(baseURL: URL(string: "https://example.com/api")!)
        let builder = client.get("https://other.example.com/v1/me")

        let request = try await builder
            .query("include", "profile")
            .preparedURLRequest()

        #expect(request.httpMethod == "GET")
        #expect(request.url?.absoluteString == "https://other.example.com/v1/me?include=profile")
        #expect(request.value(forHTTPHeaderField: "X-Global") == "global")
    }

    @Test("baseURL path와 요청 path를 슬래시 규칙에 맞게 병합한다")
    func mergesBaseAndRequestPath() async throws {
        let client = makeClient(baseURL: URL(string: "https://example.com/api/")!)
        let builder = client.get("users/me")

        let request = try await builder
            .preparedURLRequest()

        #expect(request.url?.absoluteString == "https://example.com/api/users/me")
    }

    @Test("요청 path의 후행 슬래시는 유지한다")
    func preservesTrailingSlashInRequestPath() async throws {
        let client = makeClient(baseURL: URL(string: "https://example.com/api")!)
        let builder = client.get("users/")

        let request = try await builder.preparedURLRequest()

        #expect(request.url?.absoluteString == "https://example.com/api/users/")
    }

    @Test("요청 path가 루트 슬래시만 전달되어도 후행 슬래시는 유지한다")
    func preservesTrailingSlashWhenRequestPathIsRootSlash() async throws {
        let client = makeClient(baseURL: URL(string: "https://example.com/api")!)
        let builder = client.get("/")

        let request = try await builder.preparedURLRequest()

        #expect(request.url?.absoluteString == "https://example.com/api/")
    }

    private func makeClient(baseURL: URL) -> NXAPIClient {
        NXAPIClient(
            configuration: NXClientConfiguration(
                baseURL: baseURL,
                headers: ["X-Global": "global"]
            )
        )
    }
}
