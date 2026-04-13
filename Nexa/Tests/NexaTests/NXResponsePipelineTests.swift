//
//  NXResponsePipelineTests.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("응답 검증과 디코딩 파이프라인 테스트")
struct NXResponsePipelineTests {
    @Test("응답 검증은 허용된 상태코드를 통과시킨다")
    func validateAllowsExpectedStatusCode() throws {
        let configuration = makeConfiguration()
        let requestSpec = RequestSpec(method: .get, path: "/users")
        let rawResponse = makeRawResponse(statusCode: 200, body: "{}")

        try NXResponsePipeline.validate(
            clientConfiguration: configuration,
            requestSpec: requestSpec,
            rawResponse: rawResponse
        )
    }

    @Test("응답 검증은 서버 에러 디코더를 우선 사용한다")
    func validateUsesServerErrorDecoderFirst() {
        let configuration = makeConfiguration(serverErrorDecoder: MockServerErrorDecoder())
        let requestSpec = RequestSpec(method: .get, path: "/users")
        let rawResponse = makeRawResponse(statusCode: 400, body: "{\"message\":\"bad request\"}")

        do {
            try NXResponsePipeline.validate(
                clientConfiguration: configuration,
                requestSpec: requestSpec,
                rawResponse: rawResponse
            )
            Issue.record("Expected server error")
        } catch let error as NXError {
            guard case let .server(statusCode, _, underlying) = error else {
                Issue.record("Unexpected NXError: \(error)")
                return
            }
            #expect(statusCode == 400)
            #expect((underlying as? MockAPIError)?.message == "bad request")
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("응답 디코딩은 디코더를 사용해 모델을 반환한다")
    func decodeReturnsDecodedModel() throws {
        let configuration = makeConfiguration()
        let rawResponse = makeRawResponse(statusCode: 200, body: "{\"id\":1,\"name\":\"opfic\"}")

        let user = try NXResponsePipeline.decode(
            clientConfiguration: configuration,
            rawResponse: rawResponse,
            responseType: PipelineUser.self
        )

        #expect(user.id == 1)
        #expect(user.name == "opfic")
    }

    @Test("응답 디코딩 실패는 NXError.decoding으로 매핑한다")
    func decodeMapsDecodingFailure() {
        let configuration = makeConfiguration()
        let rawResponse = makeRawResponse(statusCode: 200, body: "{\"unexpected\":true}")

        do {
            _ = try NXResponsePipeline.decode(
                clientConfiguration: configuration,
                rawResponse: rawResponse,
                responseType: PipelineUser.self
            )
            Issue.record("Expected decoding error")
        } catch let error as NXError {
            guard case .decoding = error else {
                Issue.record("Unexpected NXError: \(error)")
                return
            }
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    @Test("에러 매핑은 URLError와 NXError를 적절한 케이스로 변환한다")
    func mapConvertsKnownErrors() {
        let timeoutError = NXResponsePipeline.map(error: URLError(.timedOut))
        guard case .timeout = timeoutError else {
            Issue.record("Expected timeout mapping")
            return
        }

        let nxError = NXResponsePipeline.map(error: NXError.authenticationRequired)
        guard case .authenticationRequired = nxError else {
            Issue.record("Expected passthrough NXError")
            return
        }
    }

    private func makeConfiguration(
        serverErrorDecoder: any NXServerErrorDecoder = NXDefaultServerErrorDecoder()
    ) -> NXClientConfiguration {
        NXClientConfiguration(
            baseURL: URL(string: "https://example.com")!,
            serverErrorDecoder: serverErrorDecoder
        )
    }
}

private struct PipelineUser: Decodable {
    let id: Int
    let name: String
}

private struct MockAPIError: Error {
    let message: String
}

private struct MockServerErrorDecoder: NXServerErrorDecoder {
    func decodeServerError(data: Data, response: HTTPURLResponse, decoder: JSONDecoder) -> (any Error)? {
        let object = try? decoder.decode(ServerErrorEnvelope.self, from: data)
        guard let message = object?.message else {
            return nil
        }
        return MockAPIError(message: message)
    }
}

private struct ServerErrorEnvelope: Decodable {
    let message: String
}

private func makeRawResponse(statusCode: Int, body: String) -> NXRawResponse {
    let response = HTTPURLResponse(
        url: URL(string: "https://example.com")!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: nil
    )!
    return NXRawResponse(data: Data(body.utf8), response: response)
}
