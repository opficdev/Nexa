//
//  NXURLSessionTransportMetricsTests.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

@testable import Nexa
import Foundation
import Testing

@Suite("URLSession transport metrics 테스트")
struct NXURLSessionTransportMetricsTests {
    @Test("URLSession transport는 metrics callback을 observer에 전달한다")
    func transportForwardsMetricsToObserver() async throws {
        let observer = MetricsObserverSpy()
        let session = makeSession(protocolClass: SuccessfulURLProtocol.self)
        let transport = NXURLSessionTransport(urlSession: session, metricsObserver: observer)
        let request = URLRequest(url: URL(string: "https://example.com/metrics")!)

        defer { session.invalidateAndCancel() }

        let response = try await transport.send(request)
        let metrics = await observer.nextMetrics()

        #expect(response.response.statusCode == 200)
        #expect(response.data == Data("{}".utf8))
        #expect(0 <= metrics.transactionCount)
        #expect(await observer.recordedCount() == 1)
    }

    @Test("observer 유무가 URLSession transport 오류를 바꾸지 않는다")
    func observerDoesNotChangeTransportFailure() async {
        let observer = MetricsObserverSpy()
        let session = makeSession(protocolClass: FailingURLProtocol.self)
        let transport = NXURLSessionTransport(urlSession: session, metricsObserver: observer)
        let request = URLRequest(url: URL(string: "https://example.com/failure")!)

        defer { session.invalidateAndCancel() }

        await #expect {
            _ = try await transport.send(request)
        } throws: { error in
            (error as? URLError)?.code == .cannotConnectToHost
        }
    }

    @Test("느린 observer가 요청 완료를 지연하지 않는다")
    func slowObserverDoesNotDelayResponse() async throws {
        let observer = BlockingMetricsObserver()
        let session = makeSession(protocolClass: SuccessfulURLProtocol.self)
        let transport = NXURLSessionTransport(urlSession: session, metricsObserver: observer)
        let request = URLRequest(url: URL(string: "https://example.com/slow-observer")!)

        defer {
            session.invalidateAndCancel()
            Task { await observer.release() }
        }

        let response = try await responseBeforeTimeout(from: transport, request: request)

        #expect(response.response.statusCode == 200)
        await observer.waitUntilRecording()
    }

    private func makeSession(protocolClass: URLProtocol.Type) -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [protocolClass]
        return URLSession(configuration: configuration)
    }

    private func responseBeforeTimeout(
        from transport: NXURLSessionTransport,
        request: URLRequest
    ) async throws -> NXRawResponse {
        try await withThrowingTaskGroup(of: NXRawResponse.self) { group in
            group.addTask {
                try await transport.send(request)
            }
            group.addTask {
                try await Task.sleep(nanoseconds: 1_000_000_000)
                throw MetricsTimeoutError.elapsed
            }

            guard let response = try await group.next() else {
                throw MetricsTimeoutError.elapsed
            }

            group.cancelAll()
            return response
        }
    }
}

private actor MetricsObserverSpy: NXNetworkMetricsObserver {
    private var metrics: [NXNetworkMetrics] = []
    private var continuation: CheckedContinuation<NXNetworkMetrics, Never>?
    private var count = 0

    func record(_ metrics: NXNetworkMetrics) async {
        count += 1

        if let continuation {
            self.continuation = nil
            continuation.resume(returning: metrics)
            return
        }

        self.metrics.append(metrics)
    }

    func nextMetrics() async -> NXNetworkMetrics {
        if let metrics = metrics.first {
            self.metrics.removeFirst()
            return metrics
        }

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }

    func recordedCount() -> Int {
        count
    }
}

private actor BlockingMetricsObserver: NXNetworkMetricsObserver {
    private var isRecording = false
    private var isReleased = false
    private var startContinuation: CheckedContinuation<Void, Never>?
    private var releaseContinuation: CheckedContinuation<Void, Never>?

    func record(_ metrics: NXNetworkMetrics) async {
        isRecording = true
        startContinuation?.resume()
        startContinuation = nil

        if isReleased == false {
            await withCheckedContinuation { continuation in
                releaseContinuation = continuation
            }
        }
    }

    func waitUntilRecording() async {
        if isRecording {
            return
        }

        await withCheckedContinuation { continuation in
            startContinuation = continuation
        }
    }

    func release() {
        isReleased = true
        releaseContinuation?.resume()
        releaseContinuation = nil
    }
}

private enum MetricsTimeoutError: Error {
    case elapsed
}

private class SuccessfulURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let client,
              let url = request.url,
              let response = HTTPURLResponse(
                  url: url,
                  statusCode: 200,
                  httpVersion: nil,
                  headerFields: nil
              ) else {
            return
        }

        client.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client.urlProtocol(self, didLoad: Data("{}".utf8))
        client.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

private class FailingURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        client?.urlProtocol(self, didFailWithError: URLError(.cannotConnectToHost))
    }

    override func stopLoading() {}
}
