//
//  NXRequestExecutor.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

enum NXRequestExecutor {
    static func executeRaw(
        clientConfiguration: NXClientConfiguration,
        responseCacheStore: NXResponseCacheStore?,
        requestSpec: RequestSpec
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
                clientConfiguration: clientConfiguration
            )
            let rawResponse = try await NXInterceptorChain.execute(
                context: context,
                interceptors: runtimeInterceptors(
                    clientConfiguration: clientConfiguration,
                    responseCacheStore: responseCacheStore,
                    requestSpec: requestSpec
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

    static func executeDecode<T: Decodable>(
        clientConfiguration: NXClientConfiguration,
        responseCacheStore: NXResponseCacheStore?,
        requestSpec: RequestSpec,
        responseType: T.Type
    ) async throws -> T {
        let rawResponse = try await executeRaw(
            clientConfiguration: clientConfiguration,
            responseCacheStore: responseCacheStore,
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

    private static func runtimeInterceptors(
        clientConfiguration: NXClientConfiguration,
        responseCacheStore: NXResponseCacheStore?,
        requestSpec: RequestSpec
    ) -> [any NXHTTPInterceptor] {
        var interceptors: [any NXHTTPInterceptor] = [
            NXRetryInterceptor(),
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
