//
//  NXLogging.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Nexa logger가 내보내는 요청 lifecycle event
public enum NXLogEvent: Sendable {
    case requestStart(NXRequestStartLog)
    case requestEnd(NXRequestEndLog)
    case requestFailure(NXRequestFailureLog)
    case retry(NXRetryLog)
    case authRefresh(NXAuthRefreshLog)
}

/// 요청 시도 시작 시점 구조화 payload
public struct NXRequestStartLog: Sendable {
    /// 동일한 논리 요청 시도 간 공유 안정적 식별자
    public let requestIdentifier: UUID
    /// 현재 시도 번호(`1`부터 시작)
    public let attemptNumber: Int
    /// 전송 HTTP 메서드 문자열
    public let method: String
    /// 완전 해석된 요청 URL 문자열
    public let url: String
    /// 요청 최종 header
    public let headers: [String: String]

    /// 요청 시작 log payload 생성
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

/// 요청 성공 종료 시점 구조화 payload
public struct NXRequestEndLog: Sendable {
    /// 동일한 논리 요청 시도 간 공유 안정적 식별자
    public let requestIdentifier: UUID
    /// 현재 시도 번호(`1`부터 시작)
    public let attemptNumber: Int
    /// 서버 반환 HTTP 상태 코드
    public let statusCode: Int
    /// 시도 실제 경과 시간
    public let elapsedTime: TimeInterval
    /// 응답 payload 크기(byte)
    public let payloadSize: Int

    /// 요청 완료 log payload 생성
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

/// 요청 실패 시점 구조화 payload
public struct NXRequestFailureLog: Sendable {
    /// 동일한 논리 요청 시도 간 공유 안정적 식별자
    public let requestIdentifier: UUID
    /// 현재 시도 번호(`1`부터 시작)
    public let attemptNumber: Int
    /// 시도 실제 경과 시간
    public let elapsedTime: TimeInterval
    /// 사람이 읽기 쉬운 실패 설명
    public let errorDescription: String

    /// 요청 실패 log payload 생성
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

/// Nexa 다음 retry 예약 시 출력 구조화 payload
public struct NXRetryLog: Sendable {
    /// 동일한 논리 요청 시도 간 공유 안정적 식별자
    public let requestIdentifier: UUID
    /// 다음 실행 시도 번호
    public let nextAttemptNumber: Int
    /// 다음 시도 시작 전 대기 시간
    public let delay: TimeInterval

    /// retry log payload 생성
    public init(requestIdentifier: UUID, nextAttemptNumber: Int, delay: TimeInterval) {
        self.requestIdentifier = requestIdentifier
        self.nextAttemptNumber = nextAttemptNumber
        self.delay = delay
    }
}

/// 인증 토큰 갱신 시도 종료 후 출력 구조화 payload
public struct NXAuthRefreshLog: Sendable {
    /// 갱신 시작 요청 식별자
    public let requestIdentifier: UUID
    /// 갱신 시도 성공 여부
    public let succeeded: Bool

    /// 인증 갱신 log payload 생성
    public init(requestIdentifier: UUID, succeeded: Bool) {
        self.requestIdentifier = requestIdentifier
        self.succeeded = succeeded
    }
}

/// Nexa의 구조화된 요청 lifecycle event 수신
///
/// ## 개요
///
/// 요청 lifecycle event의 자체 logging 또는 analytics pipeline 전달 대상 `NXLogger` 채택
public protocol NXLogger: Sendable {
    /// Nexa 발행 log event 단건 처리
    func log(_ event: NXLogEvent) async
}

/// 발생 event 전체 무시 logger
public struct NXNoopLogger: NXLogger {
    /// 무동작 logger 생성
    public init() {}

    /// 전달 log event 무시
    public func log(_ event: NXLogEvent) async {}
}
