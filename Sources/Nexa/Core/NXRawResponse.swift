//
//  NXRawResponse.swift
//  Nexa
//
//  Created by 최윤진 on 4/12/26.
//

import Foundation

/// Raw HTTP response returned by Nexa before decoding.
public struct NXRawResponse: Sendable {
    /// Raw response body data.
    public var data: Data
    /// HTTP response associated with the response body.
    public var response: HTTPURLResponse

    /// Creates a raw response container.
    public init(data: Data, response: HTTPURLResponse) {
        self.data = data
        self.response = response
    }
}
