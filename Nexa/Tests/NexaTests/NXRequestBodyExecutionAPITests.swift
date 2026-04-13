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

        let builder = try client.post("/users").json(UserPayload(userName: "opfic"))

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

        let builder = try client.post("/users").json(UserPayload(userName: "opfic"), encoder: overrideEncoder)

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

        let builder = client
            .post("/users")
            .body(payload, contentType: "text/plain")

        guard case let .data(data) = builder.requestSpec.body else {
            Issue.record("body data not found")
            return
        }

        #expect(data == payload)
        #expect(builder.requestSpec.headers["Content-Type"] == "text/plain")
    }

    @Test("실행 API는 빌드 로직 전 단계에서 invalidRequest 에러를 던진다")
    func executionAPIsThrowInvalidRequestBeforeBuildLogic() async {
        let client = makeClient()
        let builder = client.get("/users")

        await expectInvalidRequest {
            _ = try await builder.raw()
        }

        await expectInvalidRequest {
            let _: UserPayload = try await builder.send(as: UserPayload.self)
        }

        await expectInvalidRequest {
            try await builder.sendVoid()
        }
    }

    private func makeClient(encoder: JSONEncoder = JSONEncoder()) -> NXAPIClient {
        NXAPIClient(
            configuration: NXClientConfiguration(
                baseURL: URL(string: "https://example.com")!,
                encoder: encoder
            )
        )
    }

    private func expectInvalidRequest(_ operation: () async throws -> Void) async {
        do {
            try await operation()
            Issue.record("Expected NXError.invalidRequest")
        } catch let error as NXError {
            guard case let .invalidRequest(message) = error else {
                Issue.record("Unexpected NXError: \(error)")
                return
            }
            #expect(message.contains("Request execution API"))
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
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
