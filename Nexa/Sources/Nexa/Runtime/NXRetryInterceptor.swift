//
//  NXRetryInterceptor.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

struct NXRetryInterceptor: NXHTTPInterceptor {
    func intercept(
        context: NXRequestExecutionContext,
        next: @escaping @Sendable (NXRequestExecutionContext) async throws -> NXRawResponse
    ) async throws -> NXRawResponse {
        guard let retryPolicy = context.specification.retryPolicy else {
            return try await next(context)
        }

        for attemptNumber in 1..<retryPolicy.maxAttempts {
            let attemptContext = context.withAttemptNumber(attemptNumber)

            do {
                let response = try await next(attemptContext)

                if response.response.statusCode == 401 {
                    return response
                }

                if attemptNumber < retryPolicy.maxAttempts,
                   retryPolicy.retryableStatusCodes.contains(response.response.statusCode) {
                    let delay = retryPolicy.backoff.delay(forAttempt: attemptNumber)
                    await context.clientConfiguration.logger.log(
                        .retry(
                            NXRetryLog(
                                requestIdentifier: context.requestIdentifier,
                                nextAttemptNumber: attemptNumber + 1,
                                delay: delay
                            )
                        )
                    )
                    try await sleep(delay: delay)
                    continue
                }

                return response
            } catch {
                if attemptNumber < retryPolicy.maxAttempts,
                   isRetryable(error: error) {
                    let delay = retryPolicy.backoff.delay(forAttempt: attemptNumber)
                    await context.clientConfiguration.logger.log(
                        .retry(
                            NXRetryLog(
                                requestIdentifier: context.requestIdentifier,
                                nextAttemptNumber: attemptNumber + 1,
                                delay: delay
                            )
                        )
                    )
                    try await sleep(delay: delay)
                    continue
                }

                throw error
            }
        }

        return try await next(context.withAttemptNumber(retryPolicy.maxAttempts))
    }

    private func isRetryable(error: any Error) -> Bool {
        guard let urlError = error as? URLError else {
            return false
        }

        switch urlError.code {
        case .timedOut,
             .cannotFindHost,
             .cannotConnectToHost,
             .dnsLookupFailed,
             .notConnectedToInternet,
             .networkConnectionLost,
             .resourceUnavailable:
            return true
        default:
            return false
        }
    }

    private func sleep(delay: TimeInterval) async throws {
        guard 0 < delay else {
            return
        }

        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
    }
}
