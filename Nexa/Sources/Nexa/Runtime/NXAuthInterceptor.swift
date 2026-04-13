//
//  NXAuthInterceptor.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

struct NXAuthInterceptor: NXHTTPInterceptor {
    func intercept(
        context: NXRequestExecutionContext,
        next: @escaping @Sendable (NXRequestExecutionContext) async throws -> NXRawResponse
    ) async throws -> NXRawResponse {
        guard context.specification.authRequirement == .required else {
            return try await next(context)
        }

        guard let authTokenProvider = context.clientConfiguration.authTokenProvider else {
            throw NXError.authProviderUnavailable
        }

        let accessToken = try await resolveAccessToken(authTokenProvider: authTokenProvider)
        let firstContext = context.replacingRequest(withBearerToken: accessToken)
        let firstResponse = try await next(firstContext)

        if firstResponse.response.statusCode != 401 {
            return firstResponse
        }

        guard let refreshedAccessToken = try await authTokenProvider.refreshAccessToken() else {
            await context.clientConfiguration.logger.log(
                .authRefresh(
                    NXAuthRefreshLog(
                        requestIdentifier: context.requestIdentifier,
                        succeeded: false
                    )
                )
            )
            return firstResponse
        }

        await context.clientConfiguration.logger.log(
            .authRefresh(
                NXAuthRefreshLog(
                    requestIdentifier: context.requestIdentifier,
                    succeeded: true
                )
            )
        )

        return try await next(context.replacingRequest(withBearerToken: refreshedAccessToken))
    }

    private func resolveAccessToken(authTokenProvider: any NXAuthTokenProvider) async throws -> String {
        if let accessToken = try await authTokenProvider.currentAccessToken() {
            return accessToken
        }

        if let refreshedAccessToken = try await authTokenProvider.refreshAccessToken() {
            return refreshedAccessToken
        }

        throw NXError.authenticationRequired
    }
}

private extension NXRequestExecutionContext {
    func replacingRequest(withBearerToken accessToken: String) -> Self {
        var request = request
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        return replacingRequest(request)
    }
}
