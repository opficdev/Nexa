//
//  NXLogging.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

public enum NXLogEvent: Sendable {
    case requestStart(NXRequestStartLog)
    case requestEnd(NXRequestEndLog)
    case requestFailure(NXRequestFailureLog)
    case retry(NXRetryLog)
    case authRefresh(NXAuthRefreshLog)
}

public struct NXRequestStartLog: Sendable {
    public let requestIdentifier: UUID
    public let attemptNumber: Int
    public let method: String
    public let url: String
    public let headers: [String: String]

    public init(
        requestIdentifier: UUID,
        attemptNumber: Int,
        method: String,
        url: String,
        headers: [String: String]
    ) {
        self.requestIdentifier = requestIdentifier
        self.attemptNumber = attemptNumber
        self.method = method
        self.url = url
        self.headers = headers
    }
}

public struct NXRequestEndLog: Sendable {
    public let requestIdentifier: UUID
    public let attemptNumber: Int
    public let statusCode: Int
    public let elapsedTime: TimeInterval
    public let payloadSize: Int

    public init(
        requestIdentifier: UUID,
        attemptNumber: Int,
        statusCode: Int,
        elapsedTime: TimeInterval,
        payloadSize: Int
    ) {
        self.requestIdentifier = requestIdentifier
        self.attemptNumber = attemptNumber
        self.statusCode = statusCode
        self.elapsedTime = elapsedTime
        self.payloadSize = payloadSize
    }
}

public struct NXRequestFailureLog: Sendable {
    public let requestIdentifier: UUID
    public let attemptNumber: Int
    public let elapsedTime: TimeInterval
    public let errorDescription: String

    public init(
        requestIdentifier: UUID,
        attemptNumber: Int,
        elapsedTime: TimeInterval,
        errorDescription: String
    ) {
        self.requestIdentifier = requestIdentifier
        self.attemptNumber = attemptNumber
        self.elapsedTime = elapsedTime
        self.errorDescription = errorDescription
    }
}

public struct NXRetryLog: Sendable {
    public let requestIdentifier: UUID
    public let nextAttemptNumber: Int
    public let delay: TimeInterval

    public init(requestIdentifier: UUID, nextAttemptNumber: Int, delay: TimeInterval) {
        self.requestIdentifier = requestIdentifier
        self.nextAttemptNumber = nextAttemptNumber
        self.delay = delay
    }
}

public struct NXAuthRefreshLog: Sendable {
    public let requestIdentifier: UUID
    public let succeeded: Bool

    public init(requestIdentifier: UUID, succeeded: Bool) {
        self.requestIdentifier = requestIdentifier
        self.succeeded = succeeded
    }
}

public protocol NXLogger: Sendable {
    func log(_ event: NXLogEvent) async
}

public struct NXNoopLogger: NXLogger {
    public init() {}

    public func log(_ event: NXLogEvent) async {}
}
