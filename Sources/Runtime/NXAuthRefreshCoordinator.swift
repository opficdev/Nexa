//
//  NXAuthRefreshCoordinator.swift
//  Nexa
//
//  Created by opfic on 8/23/26.
//

import Foundation

actor NXAuthRefreshCoordinator {
    private var inFlightRefresh: InFlightRefresh?

    func refreshAccessToken(
        using provider: any NXAuthTokenProvider,
        logger: any NXLogger,
        requestIdentifier: UUID
    ) async throws -> String? {
        if let inFlightRefresh {
            return try await value(for: inFlightRefresh)
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
        return try await value(for: inFlightRefresh)
    }

    private func value(for inFlightRefresh: InFlightRefresh) async throws -> String? {
        do {
            let accessToken = try await inFlightRefresh.task.value
            clear(inFlightRefresh)
            return accessToken
        } catch {
            clear(inFlightRefresh)
            throw error
        }
    }

    private func clear(_ inFlightRefresh: InFlightRefresh) {
        guard self.inFlightRefresh?.identifier == inFlightRefresh.identifier else {
            return
        }

        self.inFlightRefresh = nil
    }

    private struct InFlightRefresh {
        let identifier: UUID
        let task: Task<String?, any Error>
    }
}
