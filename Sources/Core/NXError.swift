//
//  NXError.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Nexa 요청 조립, 전송, 유효성 검사, 디코딩 과정에서 발생하는 오류
public enum NXError: Error, Sendable {
    /// 입력으로 유효한 HTTP 요청을 생성하지 못함
    case invalidRequest(String)
    /// 인증이 필요한 요청에서 사용 가능한 토큰이 없음
    case authenticationRequired
    /// 인증이 필요한 요청에 `NXAuthTokenProvider`가 설정되지 않음
    case authProviderUnavailable
    /// 전송 과정에서 `URLError`가 발생함
    case transport(URLError)
    /// 요청 타임아웃
    case timeout
    /// 요청 취소
    case cancelled
    /// 수신한 상태 코드의 유효성 검사 실패
    case invalidStatus(statusCode: Int, data: Data?)
    /// 실패 상태 코드 응답의 사용자 정의 서버 오류 디코딩
    case server(statusCode: Int, data: Data?, underlying: any Error)
    /// 성공 응답 디코딩 실패
    case decoding(any Error, data: Data?)
    /// 분류되지 않은 오류
    case unknown(any Error)
}
