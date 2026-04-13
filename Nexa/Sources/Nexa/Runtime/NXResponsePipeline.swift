//
//  NXResponsePipeline.swift
//  Nexa
//
//  Created by 최윤진 on 4/13/26.
//

import Foundation

enum NXResponsePipeline {
    static func validate(
        clientConfiguration: NXClientConfiguration,
        requestSpec: RequestSpec,
        rawResponse: NXRawResponse
    ) throws {
        let statusCode = rawResponse.response.statusCode

        guard requestSpec.validationPolicy.allows(statusCode: statusCode) else {
            if let serverError = clientConfiguration.serverErrorDecoder.decodeServerError(
                data: rawResponse.data,
                response: rawResponse.response,
                decoder: clientConfiguration.decoder
            ) {
                throw NXError.server(statusCode: statusCode, data: rawResponse.data, underlying: serverError)
            }

            throw NXError.invalidStatus(statusCode: statusCode, data: rawResponse.data)
        }
    }

    static func decode<T: Decodable>(
        clientConfiguration: NXClientConfiguration,
        rawResponse: NXRawResponse,
        responseType: T.Type
    ) throws -> T {
        do {
            return try clientConfiguration.decoder.decode(responseType, from: rawResponse.data)
        } catch {
            throw NXError.decoding(error, data: rawResponse.data)
        }
    }
}
