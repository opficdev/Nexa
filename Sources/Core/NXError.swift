//
//  NXError.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Nexa가 요청 조립, 전송, 유효성 검사, 디코딩 과정에서 발생시키는 오류입니다.
public enum NXError: Error, Sendable {
    /// 입력으로 유효한 HTTP 요청을 만들 수 없어 요청 조립이 실패했습니다.
    case invalidRequest(String)
    /// 요청에 인증이 필요했지만 사용 가능한 토큰이 없습니다.
    case authenticationRequired
    /// 요청에 인증이 필요했지만 인증 토큰 공급자가 설정되지 않았습니다.
    case authProviderUnavailable
    /// 전송 계층에서 `URLError`가 발생했습니다.
    case transport(URLError)
    /// 요청이 시간 초과되었습니다.
    case timeout
    /// 요청이 취소되었습니다.
    case cancelled
    /// 수신한 상태 코드에 대한 응답 유효성 검사가 실패했습니다.
    case invalidStatus(statusCode: Int, data: Data?)
    /// 서버가 실패 상태 코드를 반환했고 사용자 정의 서버 오류로 디코딩되었습니다.
    case server(statusCode: Int, data: Data?, underlying: any Error)
    /// 성공한 요청의 응답 디코딩이 실패했습니다.
    case decoding(any Error, data: Data?)
    /// 분류되지 않은 오류가 발생했습니다.
    case unknown(any Error)
}
