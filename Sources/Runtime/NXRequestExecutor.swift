//
//  NXRequestExecutor.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

enum NXRequestExecutor {
    // 요청 조립과 `NXRawResponse` validation 실행 경계
    static func executeRaw(
        clientConfiguration: NXClientConfiguration,
        responseCacheStore: NXResponseCacheStore?,
        authRefreshCoordinator: NXAuthRefreshCoordinator,
        requestSpec: RequestSpec,
        retryExecutionDependencies: NXRetryExecutionDependencies = .live
    ) async throws -> NXRawResponse {
        do {
            let request = try NXRequestAssembler.assemble(
                clientConfiguration: clientConfiguration,
                requestSpec: requestSpec
            )
            let context = NXRequestExecutionContext(
                request: request,
                requestIdentifier: requestSpec.requestIdentifier,
                attemptNumber: 1,
                userInfo: requestSpec.userInfo,
                specification: requestSpec,
                clientConfiguration: clientConfiguration,
                authRefreshCoordinator: authRefreshCoordinator
            )
            let rawResponse = try await NXInterceptorChain.execute(
                context: context,
                interceptors: runtimeInterceptors(
                    clientConfiguration: clientConfiguration,
                    responseCacheStore: responseCacheStore,
                    requestSpec: requestSpec,
                    retryExecutionDependencies: retryExecutionDependencies
                ),
                transport: clientConfiguration.transport
            )

            try NXResponsePipeline.validate(
                clientConfiguration: clientConfiguration,
                requestSpec: requestSpec,
                rawResponse: rawResponse
            )

            return rawResponse
        } catch {
            throw NXResponsePipeline.map(error: error)
        }
    }

    // `NXRawResponse`의 지정 type decoding 실행 경계
    static func executeDecode<T: Decodable>(
        clientConfiguration: NXClientConfiguration,
        responseCacheStore: NXResponseCacheStore?,
        authRefreshCoordinator: NXAuthRefreshCoordinator,
        requestSpec: RequestSpec,
        responseType: T.Type
    ) async throws -> T {
        let rawResponse = try await executeRaw(
            clientConfiguration: clientConfiguration,
            responseCacheStore: responseCacheStore,
            authRefreshCoordinator: authRefreshCoordinator,
            requestSpec: requestSpec
        )

        do {
            return try NXResponsePipeline.decode(
                clientConfiguration: clientConfiguration,
                rawResponse: rawResponse,
                responseType: responseType
            )
        } catch {
            throw NXResponsePipeline.map(error: error)
        }
    }

    // 실행 interceptor를 구성하는 메서드
    private static func runtimeInterceptors(
        clientConfiguration: NXClientConfiguration,
        responseCacheStore: NXResponseCacheStore?,
        requestSpec: RequestSpec,
        retryExecutionDependencies: NXRetryExecutionDependencies
    ) -> [any NXHTTPInterceptor] {
        var interceptors: [any NXHTTPInterceptor] = [
            NXRetryInterceptor(dependencies: retryExecutionDependencies),
            NXAuthInterceptor()
        ]
        interceptors.append(contentsOf: clientConfiguration.interceptors)
        interceptors.append(contentsOf: requestSpec.requestInterceptors)
        interceptors.append(NXLoggerInterceptor())

        if let responseCacheStore {
            interceptors.append(
                NXResponseCacheInterceptor(
                    cache: clientConfiguration.cache,
                    store: responseCacheStore
                )
            )
        }

        return interceptors
    }
}
