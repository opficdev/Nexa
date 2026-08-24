//
//  NXInterceptorChain.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

enum NXInterceptorChain {
    // interceptor와 transport를 실행하는 메서드
    static func execute(
        context: NXRequestExecutionContext,
        interceptors: [any NXHTTPInterceptor],
        transport: any NXHTTPTransport
    ) async throws -> NXRawResponse {
        // 다음 실행 단계에 요청 정보를 전달하는 중첩 메서드
        @Sendable func proceed(index: Int, context: NXRequestExecutionContext) async throws -> NXRawResponse {
            guard context.request.httpMethod == context.specification.method.rawValue else {
                throw NXError.invalidRequest("Interceptor request method must match the request specification method.")
            }

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
