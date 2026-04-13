# ``Nexa``

Declarative networking built around value-semantic request builders, typed decoding, and protocol-based extension points.

## Overview

Start with ``NXClientConfiguration`` to define your shared transport, auth, logging, and serialization behavior.

Use ``NXAPIClient`` to create requests from relative paths, then choose between ``NXRequestBuilder`` for raw execution and ``NXTypedRequestBuilder`` for decoded responses.

Adopt ``NXEndpoint`` when a request shape should be reusable and carry its response type with it.

Lower-level customization points such as ``NXHTTPTransport``, ``NXHTTPInterceptor``, ``NXAuthTokenProvider``, ``NXServerErrorDecoder``, and ``NXLogger`` let you replace or extend the default behavior without changing the higher-level request flow.

## Quick Start

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

## Raw Response

```swift
import Foundation
import Nexa

let response = try await client
    .get("/users")
    .accept("application/json")
    .raw()
```

## Reusable Endpoints

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

let user = try await client.send(UserEndpoint(identifier: 42))
```

## Topics

### Essentials

- ``NXAPIClient``
- ``NXClientConfiguration``
- ``NXRequestBuilder``
- ``NXTypedRequestBuilder``
- ``NXEndpoint``

### Request Execution

- ``NXHTTPMethod``
- ``NXRawResponse``
- ``NXError``
- ``NXValidationPolicy``
- ``NXRetryPolicy``
- ``NXURLSessionTransport``

### Extension Points

- ``NXHTTPTransport``
- ``NXHTTPInterceptor``
- ``NXRequestExecutionContext``
- ``NXAuthTokenProvider``
- ``NXServerErrorDecoder``
- ``NXDefaultServerErrorDecoder``
- ``NXLogger``
- ``NXNoopLogger``

### Logging

- ``NXLogEvent``
- ``NXRequestStartLog``
- ``NXRequestEndLog``
- ``NXRequestFailureLog``
- ``NXRetryLog``
- ``NXAuthRefreshLog``
