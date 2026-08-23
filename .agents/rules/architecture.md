# Nexa Architecture Rules

## Purpose

Nexa as Swift Package networking library. Public API stability, request behavior, package boundary, and Swift Concurrency safety as architecture decision boundaries.

## Ownership

| Area | Owner | Responsibility |
| --- | --- | --- |
| `Sources/Public` | Public API | Consumer-facing request builders, client, endpoint, and extension protocols |
| `Sources/Core` | Core model | Request configuration, request model, policy, error, logging, and protocol contracts |
| `Sources/Runtime` | Runtime | Request assembly, execution, transport, interceptor chain, retry, authentication, cache, and response pipeline |
| `Tests` | Test suite | Observable public behavior and runtime boundary verification |
| `Package.swift` | Package manifest | Platform floor, product, target, test target, and package dependency declarations |

## Public API rules

- `public` declaration additions, removals, signature changes, default value changes, error mapping changes, and protocol requirement changes as public API changes.
- Public API change requires consumer-oriented DocC documentation and public-surface test coverage.
- `NXAPIClient`, request builders, `NXEndpoint`, `NXHTTPTransport`, `NXHTTPInterceptor`, `NXAuthTokenProvider`, `NXLogger`, `NXError`, and policy types as compatibility-sensitive interfaces.
- Internal runtime types remain non-public unless a stable consumer extension point is necessary.
- Existing method names, request defaults, response decoding, and error mapping preservation without explicit user authority.

## Request execution and concurrency rules

- Request flow remains assembly, interceptor execution, transport, response validation, response decoding order.
- Interceptor order, retry behavior, authentication refresh, cancellation mapping, cache eligibility, and log event ordering as observable behavior.
- `Sendable` conformance, actor-isolated mutable state, task cancellation, and concurrent identical-request behavior require focused review and tests.
- Mutable shared state uses actor isolation or another explicit concurrency boundary.
- `NXHTTPTransport` and other consumer extension protocols retain test substitution capability.

## Package boundary rules

- `Package.swift` dependency, product, platform, and target changes as architecture-sensitive changes.
- Package target additions or dependency changes require `Architecture Watcher` review before implementation.
- No application target, app lifecycle, Simulator, or external service dependency introduction without explicit user authority.
- Development-only tooling remains outside the distributable `Nexa` product dependency graph.

## Architecture Watcher gate

Architecture Watcher review required before implementation when public API, concurrency boundary, package manifest, dependency direction, request execution ordering, or architecture documentation changes occur.

- `Pass`: implementation continuation.
- `Block`: no implementation continuation.
- `Needs Owner Decision`: explicit user decision before implementation continuation.
