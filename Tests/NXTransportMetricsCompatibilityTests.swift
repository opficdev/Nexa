//
//  NXTransportMetricsCompatibilityTests.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation
import Testing
@testable import Nexa

@Suite("전송 metrics 호환성 테스트")
struct NXTransportMetricsCompatibilityTests {
    @Test("custom transport과 cache hit는 기존 응답과 logger 순서를 유지한다")
    func customTransportAndCacheHitPreserveExistingContracts() async throws {
        let counter = AttemptCounter()
        let logger = MemoryLogger()
        let client = NXAPIClient(
            configuration: NXClientConfiguration(
                baseURL: URL(string: "https://example.com")!,
                transport: ClosureTransport { _ in
                    _ = await counter.increment()
                    return makeRawResponse(statusCode: 200, body: "{}", path: "/metrics")
                },
                logger: logger,
                cache: .memory(ttl: 10)
            )
        )

        let firstResponse: NXRawResponse = try await client.get("/metrics").send()
        let secondResponse: NXRawResponse = try await client.get("/metrics").send()

        #expect(firstResponse.response.statusCode == 200)
        #expect(secondResponse.response.statusCode == 200)
        #expect(firstResponse.data == secondResponse.data)
        #expect(await counter.value() == 1)
        #expect(await logEvents(from: logger) == [.requestStart, .requestEnd, .requestStart, .requestEnd])
    }

    private func logEvents(from logger: MemoryLogger) async -> [LogEvent] {
        await logger.allEvents().compactMap { event in
            switch event {
            case .requestStart:
                return .requestStart
            case .requestEnd:
                return .requestEnd
            case .requestFailure:
                return .requestFailure
            case .retry:
                return .retry
            case .authRefresh:
                return .authRefresh
            }
        }
    }
}

private enum LogEvent: Equatable {
    case requestStart
    case requestEnd
    case requestFailure
    case retry
    case authRefresh
}
