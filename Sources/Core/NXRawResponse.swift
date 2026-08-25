//
//  NXRawResponse.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// decoding 전 반환용 HTTP 응답 container
public struct NXRawResponse: Sendable {
    /// 응답 body data
    public var data: Data
    /// body 연계 HTTP 응답
    public var response: HTTPURLResponse

    /// HTTP 응답 container 생성
    public init(data: Data, response: HTTPURLResponse) {
        self.data = data
        self.response = response
    }
}
