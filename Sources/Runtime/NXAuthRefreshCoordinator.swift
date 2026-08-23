//
//  NXAuthRefreshCoordinator.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation

actor NXAuthRefreshCoordinator {
    private var inFlightRefresh: InFlightRefresh?
    private var waiters: [UUID: [UUID: CheckedContinuation<String?, any Error>]] = [:]
    private let onWaiterRegistered: (@Sendable () -> Void)?
    private let onRefreshCompleted: (@Sendable () -> Void)?

    init(
        onWaiterRegistered: (@Sendable () -> Void)? = nil,
        onRefreshCompleted: (@Sendable () -> Void)? = nil
    ) {
        self.onWaiterRegistered = onWaiterRegistered
        self.onRefreshCompleted = onRefreshCompleted
    }

    func refreshAccessToken(
        using provider: any NXAuthTokenProvider,
        logger: any NXLogger,
        requestIdentifier: UUID
    ) async throws -> String? {
        if let inFlightRefresh {
            return try await wait(for: inFlightRefresh)
        }

        let inFlightRefresh = InFlightRefresh(
            identifier: UUID(),
            task: Task {
                do {
                    let accessToken = try await provider.refreshAccessToken()
                    await logger.log(
                        .authRefresh(
                            NXAuthRefreshLog(
                                requestIdentifier: requestIdentifier,
                                succeeded: accessToken != nil
                            )
                        )
                    )
                    return accessToken
                } catch {
                    await logger.log(
                        .authRefresh(
                            NXAuthRefreshLog(
                                requestIdentifier: requestIdentifier,
                                succeeded: false
                            )
                        )
                    )
                    throw error
                }
            }
        )
        self.inFlightRefresh = inFlightRefresh
        observeCompletion(of: inFlightRefresh)
        return try await wait(for: inFlightRefresh)
    }

    private func wait(for inFlightRefresh: InFlightRefresh) async throws -> String? {
        let waiterIdentifier = UUID()

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                addWaiter(
                    continuation,
                    identifier: waiterIdentifier,
                    to: inFlightRefresh
                )
            }
        } onCancel: {
            Task {
                await self.cancelWaiter(
                    identifier: waiterIdentifier,
                    in: inFlightRefresh
                )
            }
        }
    }

    private func observeCompletion(of inFlightRefresh: InFlightRefresh) {
        Task {
            do {
                let accessToken = try await inFlightRefresh.task.value
                complete(inFlightRefresh, with: .success(accessToken))
            } catch {
                complete(inFlightRefresh, with: .failure(error))
            }
        }
    }

    private func addWaiter(
        _ continuation: CheckedContinuation<String?, any Error>,
        identifier: UUID,
        to inFlightRefresh: InFlightRefresh
    ) {
        guard !Task.isCancelled,
              self.inFlightRefresh?.identifier == inFlightRefresh.identifier
        else {
            continuation.resume(throwing: CancellationError())
            return
        }

        waiters[inFlightRefresh.identifier, default: [:]][identifier] = continuation
        onWaiterRegistered?()
    }

    private func cancelWaiter(
        identifier: UUID,
        in inFlightRefresh: InFlightRefresh
    ) {
        guard let continuation = waiters[inFlightRefresh.identifier]?[identifier] else {
            return
        }

        waiters[inFlightRefresh.identifier]?[identifier] = nil
        if waiters[inFlightRefresh.identifier]?.isEmpty == true {
            waiters[inFlightRefresh.identifier] = nil
        }
        continuation.resume(throwing: CancellationError())
    }

    private func complete(
        _ inFlightRefresh: InFlightRefresh,
        with result: Result<String?, any Error>
    ) {
        guard self.inFlightRefresh?.identifier == inFlightRefresh.identifier else {
            return
        }

        self.inFlightRefresh = nil
        let continuations = waiters.removeValue(forKey: inFlightRefresh.identifier).map {
            Array($0.values)
        } ?? []
        onRefreshCompleted?()

        continuations.forEach { continuation in
            switch result {
            case let .success(accessToken):
                continuation.resume(returning: accessToken)
            case let .failure(error):
                continuation.resume(throwing: error)
            }
        }
    }

    private struct InFlightRefresh {
        let identifier: UUID
        let task: Task<String?, any Error>
    }
}
