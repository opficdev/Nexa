//
//  NXLoggerInterceptor.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

struct NXLoggerInterceptor: NXHTTPInterceptor {
    func intercept(
        context: NXRequestExecutionContext,
        next: @escaping @Sendable (NXRequestExecutionContext) async throws -> NXRawResponse
    ) async throws -> NXRawResponse {
        let startTime = Date()

        await context.clientConfiguration.logger.log(
            .requestStart(
                NXRequestStartLog(
                    requestIdentifier: context.requestIdentifier,
                    attemptNumber: context.attemptNumber,
                    method: context.request.httpMethod ?? "UNKNOWN",
                    url: context.request.url?.absoluteString ?? "",
                    headers: redactedHeaders(values: context.request.allHTTPHeaderFields ?? [:])
                )
            )
        )

        do {
            let response = try await next(context)
            let elapsedTime = Date().timeIntervalSince(startTime)

            await context.clientConfiguration.logger.log(
                .requestEnd(
                    NXRequestEndLog(
                        requestIdentifier: context.requestIdentifier,
                        attemptNumber: context.attemptNumber,
                        statusCode: response.response.statusCode,
                        elapsedTime: elapsedTime,
                        payloadSize: response.data.count
                    )
                )
            )

            return response
        } catch {
            let elapsedTime = Date().timeIntervalSince(startTime)

            await context.clientConfiguration.logger.log(
                .requestFailure(
                    NXRequestFailureLog(
                        requestIdentifier: context.requestIdentifier,
                        attemptNumber: context.attemptNumber,
                        elapsedTime: elapsedTime,
                        errorDescription: String(describing: error)
                    )
                )
            )

            throw error
        }
    }

    private func redactedHeaders(values: [String: String]) -> [String: String] {
        values.reduce(into: [:]) { partialResult, entry in
            let shouldRedact = entry.key.caseInsensitiveCompare("Authorization") == .orderedSame ||
                entry.key.caseInsensitiveCompare("Cookie") == .orderedSame
            partialResult[entry.key] = shouldRedact ? "<redacted>" : entry.value
        }
    }
}
