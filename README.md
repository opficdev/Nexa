# Nexa

[![Build](https://github.com/opficdev/Nexa/actions/workflows/build.yml/badge.svg)](https://github.com/opficdev/Nexa/actions/workflows/build.yml)
[![Swift](https://img.shields.io/badge/Swift-6.1-orange?style=flat-square)](https://www.swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-iOS_15%2B_macOS_12%2B-blue?style=flat-square)](https://github.com/opficdev/Nexa)
[![Swift Package Manager](https://img.shields.io/badge/Swift_Package_Manager-compatible-brightgreen?style=flat-square)](https://swift.org/package-manager/)

Nexa is a SwiftUI-inspired declarative networking library built on `URLSession`.

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Public API](#public-api)
- [Quick Start](#quick-start)
- [Endpoint API](#endpoint-api)
- [Configuration](#configuration)
- [Testing](#testing)

## Features

- [x] Declarative request builders for `GET`, `POST`, `PUT`, `PATCH`, and `DELETE`
- [x] Typed response decoding with Swift Concurrency
- [x] Value-semantic request composition
- [x] Query, header, timeout, body, and JSON encoding support
- [x] Endpoint-based API with compile-time response typing
- [x] Request-level and global interceptor chains
- [x] Built-in authentication and token refresh flow through `NXAuthTokenProvider`
- [x] Retry policies with fixed and exponential backoff
- [x] Response validation and server error decoding
- [x] Logger hooks and transport abstraction for testing

## Requirements

| Platform | Swift | Installation |
| --- | --- | --- |
| iOS 15.0+ / macOS 12.0+ | Swift 6.1 | [Swift Package Manager](#swift-package-manager) |

## Installation

### Swift Package Manager

Add Nexa to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/opficdev/Nexa.git", branch: "main")
]
```

Then add `Nexa` to your target dependencies:

```swift
.target(
    name: "AppModule",
    dependencies: [
        .product(name: "Nexa", package: "Nexa")
    ]
)
```

## Public API

Most code starts from `NXAPIClient`, then moves into either `NXRequestBuilder` or `NXTypedRequestBuilder<Response>`. 

The rest of the public surface is made of extension points for auth, logging, testing, retry, validation, and custom error mapping.

| API | When to use it | Example |
| --- | --- | --- |
| `NXAPIClient` | Main entry point for requests that share one `baseURL` and one configuration | `client.get("/users", as: User.self).send()` |
| `NXRequestBuilder` | When you want to inspect the assembled `URLRequest` or receive `NXRawResponse` without decoding | `try await client.get("/users").raw()` |
| `NXTypedRequestBuilder<Response>` | When the response should decode directly into a `Decodable` type | `try await client.get("/users/1", as: User.self).send()` |
| `NXEndpoint` | When an endpoint definition should be reusable and carry its response type with it | `try await client.send(UserEndpoint(identifier: 1))` |
| `NXClientConfiguration` | When shared headers, transport, logger, auth, encoder, decoder, or interceptors should be configured once | `NXClientConfiguration(baseURL: url, authTokenProvider: yourAuthTokenProvider)` |
| `NXRetryPolicy` | When a request should retry on retryable status codes or transport failures | `.retry(.init(maxAttempts: 3))` |
| `NXValidationPolicy` | When the accepted status codes differ from the default `200..<300` | `.validate(.statusCodes([200, 201, 204]))` |
| `NXHTTPTransport` | When you need stubs in tests or want to replace the transport implementation | `NXClientConfiguration(baseURL: url, transport: yourStubTransport)` |
| `NXHTTPInterceptor` | When you need cross-cutting request behavior such as tracing or header injection | `.intercept(yourInterceptor)` |
| `NXAuthTokenProvider` | When `.authorized()` requests need token lookup and refresh support | `authTokenProvider: yourAuthTokenProvider` |
| `NXServerErrorDecoder` | When failed responses should decode into your own domain error | `serverErrorDecoder: yourServerErrorDecoder` |
| `NXLogger` | When you want structured request lifecycle logging | `logger: yourLogger` |
| `NXRawResponse` | When you need both `Data` and `HTTPURLResponse` directly | `let response = try await client.get("/users").raw()` |
| `NXError` | When handling Nexa-specific failures in calling code | `catch let error as NXError` |
| `NXHTTPMethod` | When defining an `NXEndpoint` method | `var method: NXHTTPMethod { .post }` |

### Which one should I start with?

Assume `client` below is an `NXAPIClient` that has already been configured.

Use `NXAPIClient` + `NXTypedRequestBuilder<Response>` for most application code:

```swift
import Foundation
import Nexa

struct User: Decodable {
    let id: Int
    let name: String
}

let user = try await client
    .get("/users/42", as: User.self)
    .send()
```

Use `NXRequestBuilder` when you want to inspect the request or handle the raw response yourself:

```swift
import Foundation
import Nexa

let request = try await client
    .post("/users")
    .header("X-Trace-Id", UUID().uuidString)
    .preparedURLRequest()
```

Use `NXEndpoint` when the same endpoint shape is reused in several places:

```swift
import Foundation
import Nexa

struct User: Decodable {
    let id: Int
    let name: String
}

struct UserEndpoint: NXEndpoint {
    let identifier: Int

    var method: NXHTTPMethod { .get }
    var path: String { "/users/\(identifier)" }

    func configure(_ builder: NXTypedRequestBuilder<User>) -> NXTypedRequestBuilder<User> {
        builder.query("include", "profile")
    }
}
```

Use the lower-level protocols only when the default behavior is not enough:

- `NXHTTPTransport`: stubs, mocks, custom network backends
- `NXHTTPInterceptor`: tracing, request mutation, custom flow control
- `NXAuthTokenProvider`: bearer token injection and refresh
- `NXServerErrorDecoder`: server payload to domain error mapping
- `NXLogger`: request lifecycle logging and observability

## Quick Start

Nexa keeps request code compact while still exposing auth, retry, validation, and decoding in one flow.

```swift
import Foundation
import Nexa

struct User: Decodable {
    let id: Int
    let name: String
}

let client = NXAPIClient(
    configuration: NXClientConfiguration(
        baseURL: URL(string: "https://api.example.com")!
    )
)

let user = try await client
    .get("/users/me", as: User.self)
    .query("include", "profile")
    .accept("application/json")
    .send()
```

Add `.authorized()` only when the client has an `authTokenProvider`.

You can also build requests step by step:

```swift
import Foundation
import Nexa

struct CreateUserPayload: Encodable {
    let name: String
}

struct User: Decodable {
    let id: Int
    let name: String
}

let createdUser = try await client
    .post("/users", as: User.self)
    .header("X-Trace-Id", UUID().uuidString)
    .json(CreateUserPayload(name: "opfic"))
    .send()
```

## Endpoint API

If you prefer a Moya-style endpoint abstraction, define an `NXEndpoint` and let Nexa keep the response type attached to the endpoint itself.

```swift
import Foundation
import Nexa

struct User: Decodable {
    let id: Int
    let name: String
}

struct UserEndpoint: NXEndpoint {
    let identifier: Int

    var method: NXHTTPMethod { .get }
    var path: String { "/users/\(identifier)" }

    func configure(_ builder: NXTypedRequestBuilder<User>) -> NXTypedRequestBuilder<User> {
        builder
            .query("include", "profile")
            .accept("application/json")
    }
}

let user = try await client.send(UserEndpoint(identifier: 42))
```

## Configuration

`NXClientConfiguration` centralizes the pieces that usually spread across a custom API layer.

```swift
import Foundation
import Nexa

let configuration = NXClientConfiguration(
    baseURL: URL(string: "https://api.example.com")!,
    headers: [
        "Accept": "application/json"
    ],
    transport: NXURLSessionTransport(),
    logger: NXNoopLogger(),
    interceptors: [],
    serverErrorDecoder: NXDefaultServerErrorDecoder(),
    authTokenProvider: nil
)

let client = NXAPIClient(configuration: configuration)
```

Replace the defaults with your own conforming types only when you need custom behavior:

- `NXLogger` for structured logging
- `NXHTTPInterceptor` for request tracing or mutation
- `NXServerErrorDecoder` for mapping failed responses to domain errors
- `NXAuthTokenProvider` for bearer token injection and refresh

Nexa currently supports:

- Global headers and per-request headers
- Raw body and JSON body encoding
- Request-level validation policies
- Automatic auth header injection for `authorized()` requests
- Token refresh and retry handling
- Custom transports for stubbing and isolated tests

## Testing

Nexa was designed to keep request execution testable. `NXHTTPTransport` lets you replace live networking with a custom transport and validate the outgoing request and decoded response.

```swift
import Foundation
import Nexa

struct User: Codable, Equatable {
    let id: Int
    let name: String
}

struct StubTransport: NXHTTPTransport {
    func send(_ request: URLRequest) async throws -> NXRawResponse {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: 200,
            httpVersion: nil,
            headerFields: nil
        )!

        return NXRawResponse(
            data: Data(#"{"id":1,"name":"opfic"}"#.utf8),
            response: response
        )
    }
}

let client = NXAPIClient(
    configuration: NXClientConfiguration(
        baseURL: URL(string: "https://example.com")!,
        transport: StubTransport()
    )
)

let user = try await client.get("/users/1", as: User.self).send()
```