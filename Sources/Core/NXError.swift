//
//  NXError.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Nexa 요청 조립·transport·validation·decoding 과정 오류
public enum NXError: Error, Sendable {
    /// 입력으로 유효한 HTTP 요청 생성 실패
    case invalidRequest(String)
    /// 인증 필요 요청에서 사용 가능한 토큰 미보유
    case authenticationRequired
    /// 인증 필요 요청에서 `NXAuthTokenProvider` 미설정
    case authProviderUnavailable
    /// transport `URLError` 발생
    case transport(URLError)
    /// 요청 타임아웃
    case timeout
    /// 요청 취소
    case cancelled
    /// 수신 상태 코드 응답 validation 실패
    case invalidStatus(statusCode: Int, data: Data?)
    /// 실패 상태 코드 응답의 사용자 정의 서버 오류 decoding
    case server(statusCode: Int, data: Data?, underlying: any Error)
    /// 성공 요청 응답 decoding 실패
    case decoding(any Error, data: Data?)
    /// 분류되지 않은 오류
    case unknown(any Error)
}
