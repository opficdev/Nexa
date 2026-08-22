//
//  NXNetworkTestSupport.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation
@testable import Nexa

struct UserDTO: Codable, Equatable, Sendable {
    let id: Int
    let name: String
}

struct UserEndpoint: NXEndpoint {
    typealias Response = UserDTO

    let identifier: Int

    var method: NXHTTPMethod { .get }
    var path: String { "/users/\(identifier)" }

    func configure(_ builder: NXTypedRequestBuilder<Response>) -> NXTypedRequestBuilder<Response> {
        builder.query("include", "profile")
    }
}

actor AttemptCounter {
    private var currentValue = 0

    func increment() -> Int {
        currentValue += 1
        return currentValue
    }

    func value() -> Int {
        currentValue
    }
}

struct ClosureTransport: NXHTTPTransport {
    let sendClosure: @Sendable (URLRequest) async throws -> NXRawResponse

    init(sendClosure: @escaping @Sendable (URLRequest) async throws -> NXRawResponse) {
        self.sendClosure = sendClosure
    }

    func send(_ request: URLRequest) async throws -> NXRawResponse {
        try await sendClosure(request)
    }
}

actor TokenProviderStub: NXAuthTokenProvider {
    let currentToken: String?
    let refreshedToken: String?
    private var refreshInvocationCount = 0

    init(currentToken: String?, refreshedToken: String?) {
        self.currentToken = currentToken
        self.refreshedToken = refreshedToken
    }

    func currentAccessToken() async throws -> String? {
        currentToken
    }

    func refreshAccessToken() async throws -> String? {
        refreshInvocationCount += 1
        return refreshedToken
    }

    func refreshCount() -> Int {
        refreshInvocationCount
    }
}

actor MemoryLogger: NXLogger {
    private var events: [NXLogEvent] = []

    func log(_ event: NXLogEvent) async {
        events.append(event)
    }

    func startLogs() -> [NXRequestStartLog] {
        events.compactMap { event in
            guard case let .requestStart(log) = event else {
                return nil
            }
            return log
        }
    }

    func retryLogs() -> [NXRetryLog] {
        events.compactMap { event in
            guard case let .retry(log) = event else {
                return nil
            }
            return log
        }
    }

    func allEvents() -> [NXLogEvent] {
        events
    }

    func authRefreshLogs() -> [NXAuthRefreshLog] {
        events.compactMap { event in
            guard case let .authRefresh(log) = event else {
                return nil
            }
            return log
        }
    }
}

func makeRawResponse(
    statusCode: Int,
    body: String,
    path: String = "/",
    headers: [String: String]? = nil
) -> NXRawResponse {
    let response = HTTPURLResponse(
        url: URL(string: "https://example.com\(path)")!,
        statusCode: statusCode,
        httpVersion: nil,
        headerFields: headers
    )!
    return NXRawResponse(data: Data(body.utf8), response: response)
}
