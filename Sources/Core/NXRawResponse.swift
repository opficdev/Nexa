//
//  NXRawResponse.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Nexa에서 디코딩 전 반환하는 원시 HTTP 응답입니다.
public struct NXRawResponse: Sendable {
    /// 원시 응답 본문 데이터입니다.
    public var data: Data
    /// 응답 본문과 연결된 HTTP 응답입니다.
    public var response: HTTPURLResponse

    /// 원시 응답 컨테이너를 생성합니다.
    public init(data: Data, response: HTTPURLResponse) {
        self.data = data
        self.response = response
    }
}
