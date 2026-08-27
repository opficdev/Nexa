//
//  NXLogging.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Nexa 로거가 내보내는 요청 생명주기 이벤트
public enum NXLogEvent: Sendable {
    case requestStart(NXRequestStartLog)
    case requestEnd(NXRequestEndLog)
    case requestFailure(NXRequestFailureLog)
    case retry(NXRetryLog)
    case authRefresh(NXAuthRefreshLog)
}

/// 요청 시도 시작 시점의 구조화된 페이로드
public struct NXRequestStartLog: Sendable {
    /// 요청 빌더 생성 시 부여되며 같은 빌더의 복사본과 반복 `send()`, 재시도, Bearer 토큰 갱신 뒤 재전송에서 유지되는 식별자
    public let requestIdentifier: UUID
    /// 현재 시도 번호(`1`부터 시작)
    public let attemptNumber: Int
    /// 전송 HTTP 메서드 문자열
    public let method: String
    /// 완전 해석된 요청 URL 문자열
    public let url: String
    /// 요청의 최종 헤더
    public let headers: [String: String]

    /// 요청 시작 로그 정보 생성
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

/// 요청 성공 종료 시점의 구조화된 페이로드
public struct NXRequestEndLog: Sendable {
    /// 요청 빌더 생성 시 부여되며 같은 빌더의 복사본과 반복 `send()`, 재시도, Bearer 토큰 갱신 뒤 재전송에서 유지되는 식별자
    public let requestIdentifier: UUID
    /// 현재 시도 번호(`1`부터 시작)
    public let attemptNumber: Int
    /// 서버 반환 HTTP 상태 코드
    public let statusCode: Int
    /// 시도 실제 경과 시간
    public let elapsedTime: TimeInterval
    /// 응답 페이로드 크기(바이트)
    public let payloadSize: Int

    /// 요청 완료 로그 정보 생성
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

/// 요청 실패 시점의 구조화된 페이로드
public struct NXRequestFailureLog: Sendable {
    /// 요청 빌더 생성 시 부여되며 같은 빌더의 복사본과 반복 `send()`, 재시도, Bearer 토큰 갱신 뒤 재전송에서 유지되는 식별자
    public let requestIdentifier: UUID
    /// 현재 시도 번호(`1`부터 시작)
    public let attemptNumber: Int
    /// 시도 실제 경과 시간
    public let elapsedTime: TimeInterval
    /// 사람이 읽기 쉬운 실패 설명
    public let errorDescription: String

    /// 요청 실패 로그 정보 생성
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

/// Nexa가 다음 재시도를 예약할 때 출력하는 구조화된 페이로드
public struct NXRetryLog: Sendable {
    /// 요청 빌더 생성 시 부여되며 같은 빌더의 복사본과 반복 `send()`, 재시도, Bearer 토큰 갱신 뒤 재전송에서 유지되는 식별자
    public let requestIdentifier: UUID
    /// 다음 실행 시도 번호
    public let nextAttemptNumber: Int
    /// 다음 시도 시작 전 대기 시간
    public let delay: TimeInterval

    /// 재시도 로그 정보 생성
    public init(requestIdentifier: UUID, nextAttemptNumber: Int, delay: TimeInterval) {
        self.requestIdentifier = requestIdentifier
        self.nextAttemptNumber = nextAttemptNumber
        self.delay = delay
    }
}

/// 인증 토큰 갱신 시도가 끝난 뒤 출력하는 구조화된 페이로드
public struct NXAuthRefreshLog: Sendable {
    /// 갱신 시작 요청 식별자
    public let requestIdentifier: UUID
    /// 갱신 시도 성공 여부
    public let succeeded: Bool

    /// 인증 갱신 로그 정보 생성
    public init(requestIdentifier: UUID, succeeded: Bool) {
        self.requestIdentifier = requestIdentifier
        self.succeeded = succeeded
    }
}

/// Nexa의 구조화된 요청 생명주기 이벤트 수신
///
/// ## 개요
///
/// 요청 생명주기 이벤트를 직접 기록하거나 분석 파이프라인으로 전달할 때 `NXLogger` 채택
public protocol NXLogger: Sendable {
    /// Nexa가 발행한 로그 이벤트 하나 처리
    func log(_ event: NXLogEvent) async
}

/// 발생한 모든 이벤트를 무시하는 로거
public struct NXNoopLogger: NXLogger {
    /// 아무 동작도 하지 않는 로거 생성
    public init() {}

    /// 전달된 로그 이벤트 무시
    public func log(_ event: NXLogEvent) async {}
}
