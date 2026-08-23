# ``Nexa``

Declarative networking built around value-semantic request builders, typed decoding, and protocol-based extension points.

## Overview

Start with ``NXClientConfiguration`` to define your shared transport, auth, logging, and serialization behavior.

Use ``NXAPIClient`` to create an ``NXRequestBuilder`` from a relative path. Call ``NXRequestBuilder/send()`` for an ``NXRawResponse``, or ``NXRequestBuilder/send(as:)`` to decode a response in the same request path.

Adopt ``NXEndpoint`` when a request shape should be reusable and carry its response type with it. Its existing ``NXTypedRequestBuilder`` configuration contract remains available for endpoint compatibility.

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
	.get("/users/me")
	.query("include", "profile")
	.accept("application/json")
	.send(as: User.self)
```

## Raw Response

```swift
import Foundation
import Nexa

let response = try await client
	.get("/users")
	.accept("application/json")
	.send()
```

## Retry Policy

``NXRequestBuilder/retry(maxAttempts:backoff:retryableStatusCodes:allowing:maximumServerDelay:jitter:)`` retries `GET`, `HEAD`, `PUT`, `DELETE`, and `OPTIONS` by default when a configured status code or a retryable transport error occurs. It uses three attempts when `maxAttempts` is omitted. Add `POST` or `PATCH` through `allowing` only when the server can safely receive the same request more than once.

For `429` and `503`, a valid `Retry-After` response header takes precedence over local backoff. Nexa accepts delay seconds and HTTP-date values, limits the result with `maximumServerDelay`, and records the selected delay through ``NXRetryLog``. Local ``NXRetryJitter`` does not change a server-provided delay.

```swift
let user = try await client
	.post("/users")
	.retry(
		maxAttempts: 3,
		allowing: [.post],
		maximumServerDelay: 30
	)
	.send(as: User.self)
```

## Migration

Nexa 1.3 removes `NXRequestBuilder.raw()`, `NXTypedRequestBuilder.raw()`, the public `NXRetryPolicy` constructor, `NXRetryPolicy.Backoff`, `NXRetryPolicy.Jitter`, and `.retry(_:)`. `NXRetryPolicy` remains an internal implementation detail. Use `NXRequestBuilder.send()` for a raw response and `.retry(maxAttempts:backoff:retryableStatusCodes:allowing:maximumServerDelay:jitter:)` for retry behavior; `maxAttempts` defaults to `3`.

An ``NXHTTPInterceptor`` can change a request URL, headers, and body through ``NXRequestExecutionContext/replacingRequest(_:)``, but must preserve the configured HTTP method. A different method ends with ``NXError/invalidRequest(_:)`` before later interceptors, logging, caching, or transport.

`NXEndpoint` retains its typed configuration and decoded `client.send(_:)` path. It does not provide a raw-response execution API; construct the required request directly with `NXRequestBuilder` when raw response handling is required.

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
- ``NXEndpoint``

### Request Execution

- ``NXHTTPMethod``
- ``NXRawResponse``
- ``NXError``
- ``NXValidationPolicy``
- ``NXRetryBackoff``
- ``NXRetryJitter``
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
