//
//  NXRawResponse.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// 디코딩 전에 반환하는 HTTP 응답 컨테이너
public struct NXRawResponse: Sendable {
    /// 응답 본문 데이터
    public var data: Data
    /// 본문과 연결된 HTTP 응답
    public var response: HTTPURLResponse

    /// HTTP 응답 컨테이너 생성
    public init(data: Data, response: HTTPURLResponse) {
        self.data = data
        self.response = response
    }
}
