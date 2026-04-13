//
//  NXClientConfigurationProtocolTests.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("클라이언트 설정과 네트워크 프로토콜 테스트")
struct NXClientConfigurationProtocolTests {
    @Test("기본 서버 에러 디코더는 에러를 생성하지 않는다")
    func defaultServerErrorDecoderReturnsNil() {
        let decoder = NXDefaultServerErrorDecoder()
        let response = HTTPURLResponse(
            url: URL(string: "https://example.com")!,
            statusCode: 400,
            httpVersion: nil,
            headerFields: nil
        )!

        let result = decoder.decodeServerError(data: Data("{}".utf8), response: response, decoder: JSONDecoder())

        #expect(result == nil)
    }

    @Test("클라이언트 설정이 주입된 의존성과 값을 보존한다")
    func configurationStoresInjectedDependencies() {
        let transport = MockTransport()
        let authTokenProvider = MockAuthTokenProvider()
        let serverErrorDecoder = MockServerErrorDecoder()

        let configuration = NXClientConfiguration(
            baseURL: URL(string: "https://api.example.com")!,
            headers: ["X-App": "Nexa"],
            transport: transport,
            decoder: JSONDecoder(),
            encoder: JSONEncoder(),
            serverErrorDecoder: serverErrorDecoder,
            authTokenProvider: authTokenProvider
        )

        #expect(configuration.baseURL.absoluteString == "https://api.example.com")
        #expect(configuration.headers["X-App"] == "Nexa")
        #expect(configuration.transport is MockTransport)
        #expect(configuration.serverErrorDecoder is MockServerErrorDecoder)
        #expect(configuration.authTokenProvider is MockAuthTokenProvider)
    }

    @Test("클라이언트 설정 기본 생성자는 기본 의존성을 사용한다")
    func configurationUsesDefaultDependencies() {
        let configuration = NXClientConfiguration(baseURL: URL(string: "https://api.example.com")!)

        #expect(configuration.transport is NXURLSessionTransport)
        #expect(configuration.serverErrorDecoder is NXDefaultServerErrorDecoder)
        #expect(configuration.authTokenProvider == nil)
    }
}

private struct MockTransport: NXHTTPTransport {
    func send(_ request: URLRequest) async throws -> NXRawResponse {
        let response = HTTPURLResponse(
            url: request.url ?? URL(string: "https://example.com")!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!
        return NXRawResponse(data: Data(), response: response)
    }
}

private struct MockServerErrorDecoder: NXServerErrorDecoder {
    func decodeServerError(data: Data, response: HTTPURLResponse, decoder: JSONDecoder) -> (any Error)? {
        nil
    }
}

private actor MockAuthTokenProvider: NXAuthTokenProvider {
    func currentAccessToken() async throws -> String? {
        nil
    }

    func refreshAccessToken() async throws -> String? {
        nil
    }
}
