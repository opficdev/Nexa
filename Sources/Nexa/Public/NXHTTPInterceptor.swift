//
//  NXHTTPInterceptor.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

public protocol NXHTTPInterceptor: Sendable {
    func intercept(
        context: NXRequestExecutionContext,
        next: @escaping @Sendable (NXRequestExecutionContext) async throws -> NXRawResponse
    ) async throws -> NXRawResponse
}

public struct NXRequestExecutionContext: Sendable {
    public let request: URLRequest
    public let requestIdentifier: UUID
    public let attemptNumber: Int
    public let userInfo: [String: String]

    let specification: RequestSpec
    let clientConfiguration: NXClientConfiguration

    init(
        request: URLRequest,
        requestIdentifier: UUID,
        attemptNumber: Int,
        userInfo: [String: String],
        specification: RequestSpec,
        clientConfiguration: NXClientConfiguration
    ) {
        self.request = request
        self.requestIdentifier = requestIdentifier
        self.attemptNumber = attemptNumber
        self.userInfo = userInfo
        self.specification = specification
        self.clientConfiguration = clientConfiguration
    }

    public func replacingRequest(_ request: URLRequest) -> Self {
        Self(
            request: request,
            requestIdentifier: requestIdentifier,
            attemptNumber: attemptNumber,
            userInfo: userInfo,
            specification: specification,
            clientConfiguration: clientConfiguration
        )
    }

    func withAttemptNumber(_ attemptNumber: Int) -> Self {
        Self(
            request: request,
            requestIdentifier: requestIdentifier,
            attemptNumber: attemptNumber,
            userInfo: userInfo,
            specification: specification,
            clientConfiguration: clientConfiguration
        )
    }
}
