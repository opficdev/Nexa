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

    private func makeSession(protocolClass: URLProtocol.Type) -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [protocolClass]
        return URLSession(configuration: configuration)
    }
}

private actor MetricsObserverSpy: NXNetworkMetricsObserver {
    private var metrics: [NXNetworkMetrics] = []
    private var continuation: CheckedContinuation<NXNetworkMetrics, Never>?

    func record(_ metrics: NXNetworkMetrics) async {
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
}

private final class SuccessfulURLProtocol: URLProtocol {
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

private final class FailingURLProtocol: URLProtocol {
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
