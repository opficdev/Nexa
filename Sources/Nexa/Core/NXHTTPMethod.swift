//
//  NXHTTPMethod.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// HTTP methods supported by Nexa request builders.
public enum NXHTTPMethod: String, Sendable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case head = "HEAD"
    case options = "OPTIONS"
}
