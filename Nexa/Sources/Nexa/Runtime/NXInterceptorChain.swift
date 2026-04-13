//
//  NXInterceptorChain.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

enum NXInterceptorChain {
    static func execute(
        context: NXRequestExecutionContext,
        interceptors: [any NXHTTPInterceptor],
        transport: any NXHTTPTransport
    ) async throws -> NXRawResponse {
        @Sendable func proceed(index: Int, context: NXRequestExecutionContext) async throws -> NXRawResponse {
            if index < interceptors.count {
                return try await interceptors[index].intercept(context: context) { nextContext in
                    try await proceed(index: index + 1, context: nextContext)
                }
            }

            return try await transport.send(context.request)
        }

        return try await proceed(index: 0, context: context)
    }
}
