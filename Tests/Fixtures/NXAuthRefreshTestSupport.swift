//
//  NXAuthRefreshTestSupport.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation
@testable import Nexa

actor RefreshTestProvider: NXAuthTokenProvider {
    private let currentToken: String?
    private let refreshResult: Result<String?, URLError>
    private let refreshStartProbe: RefreshStartProbe?
    private let refreshCompletionGate: RefreshCompletionGate?
    private var refreshInvocationCount = 0

    init(
        currentToken: String?,
        refreshResult: Result<String?, URLError>,
        refreshStartProbe: RefreshStartProbe? = nil,
        refreshCompletionGate: RefreshCompletionGate? = nil
    ) {
        self.currentToken = currentToken
        self.refreshResult = refreshResult
        self.refreshStartProbe = refreshStartProbe
        self.refreshCompletionGate = refreshCompletionGate
    }

    func currentAccessToken() async throws -> String? {
        currentToken
    }

    func refreshAccessToken() async throws -> String? {
        refreshInvocationCount += 1
        await refreshStartProbe?.recordStart()
        await refreshCompletionGate?.wait()
        return try refreshResult.get()
    }

    func refreshCount() -> Int {
        refreshInvocationCount
    }
}

actor GatedTokenProvider: NXAuthTokenProvider {
    let refreshedToken: String?
    private var refreshInvocationCount = 0
    private var didStartRefresh = false
    private var startContinuation: CheckedContinuation<Void, Never>?
    private var refreshContinuation: CheckedContinuation<Void, Never>?
    private var isRefreshReleased = false

    init(refreshedToken: String?) {
        self.refreshedToken = refreshedToken
    }

    func currentAccessToken() async throws -> String? {
        nil
    }

    func refreshAccessToken() async throws -> String? {
        refreshInvocationCount += 1
        didStartRefresh = true
        startContinuation?.resume()
        startContinuation = nil

        if !isRefreshReleased {
            await withCheckedContinuation { continuation in
                refreshContinuation = continuation
            }
        }

        return refreshedToken
    }

    func waitForRefreshStart() async {
        guard !didStartRefresh else {
            return
        }

        await withCheckedContinuation { continuation in
            startContinuation = continuation
        }
    }

    func releaseRefresh() {
        isRefreshReleased = true
        refreshContinuation?.resume()
        refreshContinuation = nil
    }

    func refreshCount() -> Int {
        refreshInvocationCount
    }
}

actor RefreshWaiterProbe {
    private let expectedCount: Int
    private var waiterCount = 0
    private var continuation: CheckedContinuation<Void, Never>?

    init(expectedCount: Int) {
        self.expectedCount = expectedCount
    }

    func recordWaiter() {
        waiterCount += 1

        guard expectedCount <= waiterCount else {
            return
        }

        continuation?.resume()
        continuation = nil
    }

    func waitForWaiters() async {
        guard waiterCount < expectedCount else {
            return
        }

        await withCheckedContinuation { continuation in
            self.continuation = continuation
        }
    }
}

actor RefreshCompletionGate {
    private var isReleased = false
    private var continuations: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        guard !isReleased else {
            return
        }

        await withCheckedContinuation { continuation in
            continuations.append(continuation)
        }
    }

    func release() {
        isReleased = true
        continuations.forEach { continuation in
            continuation.resume()
        }
        continuations.removeAll()
    }
}

actor RefreshCompletionProbe {
    private var didComplete = false
    private var continuations: [CheckedContinuation<Void, Never>] = []

    func recordCompletion() {
        didComplete = true
        continuations.forEach { continuation in
            continuation.resume()
        }
        continuations.removeAll()
    }

    func waitForCompletion() async {
        guard !didComplete else {
            return
        }

        await withCheckedContinuation { continuation in
            continuations.append(continuation)
        }
    }
}

actor RefreshStartProbe {
    private var didStart = false
    private var continuations: [CheckedContinuation<Void, Never>] = []

    func recordStart() {
        didStart = true
        continuations.forEach { continuation in
            continuation.resume()
        }
        continuations.removeAll()
    }

    func waitForStart() async {
        guard !didStart else {
            return
        }

        await withCheckedContinuation { continuation in
            continuations.append(continuation)
        }
    }
}
