//
//  NXRawResponse.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

public struct NXRawResponse: Sendable {
    public var data: Data
    public var response: HTTPURLResponse

    public init(data: Data, response: HTTPURLResponse) {
        self.data = data
        self.response = response
    }
}
