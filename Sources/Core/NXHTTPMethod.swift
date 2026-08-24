//
//  NXHTTPMethod.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Nexa 요청 빌더가 지원하는 HTTP 메서드입니다.
public enum NXHTTPMethod: String, Sendable, Hashable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case head = "HEAD"
    case options = "OPTIONS"
}
