//
//  NexaIntegrationPreview.swift
//  NexaClient
//
//  Created by opfic on 6/13/26.
//

import Foundation
import Nexa

struct NexaIntegrationPreview {
    private let client = NXAPIClient(
        configuration: NXClientConfiguration(
            baseURL: URL(string: "https://api.example.com")!
        )
    )

    var clientDescription: String {
        "Client: \(String(describing: type(of: client)))"
    }

    var typedRequestDescription: String {
        let request = client
            .get("/users/me", as: ExampleUser.self)
            .query("include", "profile")
            .accept("application/json")

        return "Typed request: \(String(describing: type(of: request)))"
    }

    var rawRequestDescription: String {
        let request = client
            .post("/users")
            .header("X-Trace-Id", "preview")
            .contentType("application/json")

        return "Raw request: \(String(describing: type(of: request)))"
    }
}

private struct ExampleUser: Decodable {
    let id: Int
    let name: String
}
