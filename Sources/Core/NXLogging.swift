//
//  NXLogging.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Nexa 로거가 내보내는 요청 라이프사이클 이벤트입니다.
public enum NXLogEvent: Sendable {
    case requestStart(NXRequestStartLog)
    case requestEnd(NXRequestEndLog)
    case requestFailure(NXRequestFailureLog)
    case retry(NXRetryLog)
    case authRefresh(NXAuthRefreshLog)
}

/// 요청 시도 시작 시점에 출력되는 구조화된 페이로드입니다.
public struct NXRequestStartLog: Sendable {
    /// 동일한 논리 요청의 모든 시도에서 공유되는 안정적 식별자입니다.
    public let requestIdentifier: UUID
    /// 현재 시도 번호(`1`부터 시작)입니다.
    public let attemptNumber: Int
    /// 전송할 요청의 HTTP 메서드 문자열입니다.
    public let method: String
    /// 완전히 해석된 요청 URL 문자열입니다.
    public let url: String
    /// 요청에 포함된 최종 헤더입니다.
    public let headers: [String: String]

    /// 요청 시작 로그 페이로드를 생성합니다.
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

/// 요청 시도가 성공적으로 끝났을 때 출력되는 구조화된 페이로드입니다.
public struct NXRequestEndLog: Sendable {
    /// 동일한 논리 요청의 모든 시도에서 공유되는 안정적인 식별자입니다.
    public let requestIdentifier: UUID
    /// 현재 시도 번호(`1`부터 시작)입니다.
    public let attemptNumber: Int
    /// 서버가 반환한 HTTP 상태 코드입니다.
    public let statusCode: Int
    /// 시도의 실제 경과 시간입니다.
    public let elapsedTime: TimeInterval
    /// 응답 페이로드 크기(바이트)입니다.
    public let payloadSize: Int

    /// 요청 완료 로그 페이로드를 생성합니다.
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

/// 요청 시도가 실패했을 때 출력되는 구조화된 페이로드입니다.
public struct NXRequestFailureLog: Sendable {
    /// 동일한 논리 요청의 모든 시도에서 공유되는 안정적인 식별자입니다.
    public let requestIdentifier: UUID
    /// 현재 시도 번호(`1`부터 시작)입니다.
    public let attemptNumber: Int
    /// 시도의 실제 경과 시간입니다.
    public let elapsedTime: TimeInterval
    /// 사람이 읽기 쉬운 실패 설명입니다.
    public let errorDescription: String

    /// 요청 실패 로그 페이로드를 생성합니다.
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

/// Nexa가 다음 재시도를 예약할 때 출력되는 구조화된 페이로드입니다.
public struct NXRetryLog: Sendable {
    /// 동일한 논리 요청의 모든 시도에서 공유되는 안정적인 식별자입니다.
    public let requestIdentifier: UUID
    /// 다음에 실행될 시도 번호입니다.
    public let nextAttemptNumber: Int
    /// 다음 시도 시작 전 대기 시간입니다.
    public let delay: TimeInterval

    /// 재시도 로그 페이로드를 생성합니다.
    public init(requestIdentifier: UUID, nextAttemptNumber: Int, delay: TimeInterval) {
        self.requestIdentifier = requestIdentifier
        self.nextAttemptNumber = nextAttemptNumber
        self.delay = delay
    }
}

/// 인증 토큰 갱신 시도 종료 후 출력되는 구조화된 페이로드입니다.
public struct NXAuthRefreshLog: Sendable {
    /// 갱신을 시작한 요청의 식별자입니다.
    public let requestIdentifier: UUID
    /// 갱신 시도 성공 여부입니다.
    public let succeeded: Bool

    /// 인증 갱신 로그 페이로드를 생성합니다.
    public init(requestIdentifier: UUID, succeeded: Bool) {
        self.requestIdentifier = requestIdentifier
        self.succeeded = succeeded
    }
}

/// Nexa의 구조화된 요청 라이프사이클 이벤트를 수신합니다.
///
/// ## 개요
///
/// 요청 라이프사이클 이벤트를 자체 로깅 또는 분석 파이프라인으로 전달하려면 `NXLogger`를 채택하세요.
public protocol NXLogger: Sendable {
    /// Nexa가 발행한 로그 이벤트 한 건을 처리합니다.
    func log(_ event: NXLogEvent) async
}

/// 발생한 모든 이벤트를 무시하는 로거입니다.
public struct NXNoopLogger: NXLogger {
    /// 아무 작업도 수행하지 않는 로거를 생성합니다.
    public init() {}

    /// 전달된 로그 이벤트를 무시합니다.
    public func log(_ event: NXLogEvent) async {}
}
