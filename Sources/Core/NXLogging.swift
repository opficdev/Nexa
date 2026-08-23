//
//  NXLogging.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Request lifecycle events emitted by Nexa loggers.
public enum NXLogEvent: Sendable {
    case requestStart(NXRequestStartLog)
    case requestEnd(NXRequestEndLog)
    case requestFailure(NXRequestFailureLog)
    case retry(NXRetryLog)
    case authRefresh(NXAuthRefreshLog)
}

/// Structured payload emitted when a request attempt starts.
public struct NXRequestStartLog: Sendable {
    /// Stable identifier shared by all attempts of the same logical request.
    public let requestIdentifier: UUID
    /// Current attempt number starting from `1`.
    public let attemptNumber: Int
    /// HTTP method string for the outgoing request.
    public let method: String
    /// Fully resolved request URL string.
    public let url: String
    /// Final headers included in the request.
    public let headers: [String: String]

    /// Creates a request-start log payload.
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

/// Structured payload emitted when a request attempt ends successfully.
public struct NXRequestEndLog: Sendable {
    /// Stable identifier shared by all attempts of the same logical request.
    public let requestIdentifier: UUID
    /// Current attempt number starting from `1`.
    public let attemptNumber: Int
    /// HTTP status code returned by the server.
    public let statusCode: Int
    /// Elapsed wall-clock time for the attempt.
    public let elapsedTime: TimeInterval
    /// Response payload size in bytes.
    public let payloadSize: Int

    /// Creates a request-end log payload.
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

/// Structured payload emitted when a request attempt fails.
public struct NXRequestFailureLog: Sendable {
    /// Stable identifier shared by all attempts of the same logical request.
    public let requestIdentifier: UUID
    /// Current attempt number starting from `1`.
    public let attemptNumber: Int
    /// Elapsed wall-clock time for the attempt.
    public let elapsedTime: TimeInterval
    /// Human-readable description of the failure.
    public let errorDescription: String

    /// Creates a request-failure log payload.
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

/// Structured payload emitted when Nexa schedules another retry attempt.
public struct NXRetryLog: Sendable {
    /// Stable identifier shared by all attempts of the same logical request.
    public let requestIdentifier: UUID
    /// Attempt number that will run next.
    public let nextAttemptNumber: Int
    /// Delay before the next attempt begins.
    public let delay: TimeInterval

    /// Creates a retry log payload.
    public init(requestIdentifier: UUID, nextAttemptNumber: Int, delay: TimeInterval) {
        self.requestIdentifier = requestIdentifier
        self.nextAttemptNumber = nextAttemptNumber
        self.delay = delay
    }
}

/// Structured payload emitted after an auth token refresh attempt finishes.
public struct NXAuthRefreshLog: Sendable {
    /// Identifier of the request that started the refresh.
    public let requestIdentifier: UUID
    /// Whether the refresh attempt succeeded.
    public let succeeded: Bool

    /// Creates an auth-refresh log payload.
    public init(requestIdentifier: UUID, succeeded: Bool) {
        self.requestIdentifier = requestIdentifier
        self.succeeded = succeeded
    }
}

/// Receives structured request lifecycle events from Nexa.
///
/// ## Overview
///
/// Adopt `NXLogger` to forward request lifecycle events into your own logging or analytics pipeline.
public protocol NXLogger: Sendable {
    /// Handles one log event emitted by Nexa.
    func log(_ event: NXLogEvent) async
}

/// Logger that ignores every emitted event.
public struct NXNoopLogger: NXLogger {
    /// Creates a logger that performs no work.
    public init() {}

    /// Ignores the incoming log event.
    public func log(_ event: NXLogEvent) async {}
}
