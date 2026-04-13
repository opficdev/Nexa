//
//  NXRequestBodyExecutionAPITests.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("요청 본문 처리와 실행 API 테스트")
struct NXRequestBodyExecutionAPITests {
    @Test("json 본문은 설정 인코더를 사용해 인코딩한다")
    func jsonBodyUsesConfigurationEncoder() throws {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        let client = makeClient(encoder: encoder)

        let builder: NXRequestBuilder<UserDTO> = try client.post("/users").json(UserPayload(userName: "opfic"))

        guard case let .data(data) = builder.requestSpec.body else {
            Issue.record("body data not found")
            return
        }

        let dictionary = try XCTJSON.dictionary(from: data)
        #expect(dictionary["user_name"] as? String == "opfic")
    }

    @Test("json 본문은 전달된 인코더를 우선 사용한다")
    func jsonBodyUsesOverrideEncoder() throws {
        let defaultEncoder = JSONEncoder()
        defaultEncoder.keyEncodingStrategy = .convertToSnakeCase

        let overrideEncoder = JSONEncoder()
        let client = makeClient(encoder: defaultEncoder)

        let builder: NXRequestBuilder<UserDTO> = try client.post("/users").json(UserPayload(userName: "opfic"), encoder: overrideEncoder)

        guard case let .data(data) = builder.requestSpec.body else {
            Issue.record("body data not found")
            return
        }

        let dictionary = try XCTJSON.dictionary(from: data)
        #expect(dictionary["userName"] as? String == "opfic")
    }

    @Test("body는 데이터와 Content-Type 헤더를 저장한다")
    func rawBodyStoresDataAndHeader() {
        let client = makeClient()
        let payload = Data("hello".utf8)

        let builder: NXRequestBuilder<UserDTO> = client
            .post("/users")
            .body(payload, contentType: "text/plain")

        guard case let .data(data) = builder.requestSpec.body else {
            Issue.record("body data not found")
            return
        }

        #expect(data == payload)
        #expect(builder.requestSpec.headers["Content-Type"] == "text/plain")
    }

    @Test("실행 API는 transport 응답을 사용한다")
    func executionAPIsUseTransportResponses() async throws {
        let client = makeClient(
            transport: ClosureTransport { request in
                #expect(request.url?.absoluteString == "https://example.com/users")
                return makeRawResponse(
                    statusCode: 200,
                    body: #"{"id":1,"name":"opfic"}"#,
                    path: "/users"
                )
            }
        )
        let builder: NXRequestBuilder<UserDTO> = client.get("/users")

        let rawResponse = try await builder.raw()
        #expect(rawResponse.response.statusCode == 200)

        let user = try await builder.send()
        #expect(user == UserDTO(id: 1, name: "opfic"))

        try await builder.sendVoid()
    }

    private func makeClient(
        encoder: JSONEncoder = JSONEncoder(),
        transport: any NXHTTPTransport = NXURLSessionTransport()
    ) -> NXAPIClient {
        NXAPIClient(
            configuration: NXClientConfiguration(
                baseURL: URL(string: "https://example.com")!,
                transport: transport,
                encoder: encoder
            )
        )
    }
}

private struct UserPayload: Codable {
    var userName: String
}

private enum XCTJSON {
    static func dictionary(from data: Data) throws -> [String: Any] {
        let object = try JSONSerialization.jsonObject(with: data)
        guard let dictionary = object as? [String: Any] else {
            throw NXError.invalidRequest("JSON payload is not dictionary")
        }
        return dictionary
    }
}
