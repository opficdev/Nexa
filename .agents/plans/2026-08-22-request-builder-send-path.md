# NXRequestBuilder send 경로 구현 계획

> 작업 단위별 검토와 검증 후 다음 단위 진행 구성.

**Goal:** `NXRequestBuilder` 하나에서 raw·문맥 기반·명시적 디코딩 전송을 제공하는 1.3 호환 경로 구성.

**Architecture:** 새 전송 API는 기존 `NXRequestExecutor.executeRaw`와 `executeDecode`만 호출. 기존 typed Builder와 endpoint는 새 API를 내부 위임하여 공개 계약 보존.

**Tech Stack:** Swift 6.1, Swift Testing, Swift Package Manager.

**Spec:** `.agents/specs/52-request-builder-send-path.md`

## Global Constraints

- `NXEndpoint.configure(_:)` 시그니처 유지
- `NXTypedRequestBuilder<Response>` 타입 사용 중단 표시 금지
- Runtime 실행 순서와 `NXHTTPTransport` 대체 경계 유지
- App·Simulator 실행 금지

### Task 1: NXRequestBuilder 전송 경로

**Files:**

- Modify: `Sources/Nexa/Public/NXRequestBuilder.swift`
- Modify: `Tests/NexaTests/NXRequestBodyExecutionAPITests.swift`

**Interfaces:**

- Produces: `send() async throws -> NXRawResponse`
- Produces: `send<Response: Decodable>() async throws -> Response`
- Produces: `send<Response: Decodable>(as: Response.Type) async throws -> Response`

- [x] `send()` 원시 응답과 generic `send()` 문맥 기반 디코딩의 실패 테스트 추가
- [x] `send(as:)` 명시 디코딩 테스트 추가
- [x] 기존 `raw()`와 `decoded(_:)`가 사용하는 executor 경로를 재사용하는 최소 구현 추가
- [x] `swift test --filter NXRequestBodyExecutionAPITests` 실행
- [x] `feat: NXRequestBuilder 전송 경로 추가` commit

### Task 2: 호환 요청 경로 위임

**Files:**

- Modify: `Sources/Nexa/Public/NXTypedRequestBuilder.swift`
- Modify: `Sources/Nexa/Public/NXAPIClient.swift`
- Modify: `Tests/NexaTests/NXInterceptorChainTests.swift`
- Modify: `Tests/NexaTests/NXRequestBodyExecutionAPITests.swift`
- Modify: `Tests/NexaTests/NXResponseCacheInterceptorTests.swift`

**Interfaces:**

- Consumes: Task 1의 세 `send` overload
- Produces: 사용 중단 API의 새 경로 위임과 endpoint 호환 실행

- [x] 기존 typed HTTP method overload와 `.as(_:)`의 컴파일·실행 호환 테스트 추가
- [x] endpoint `client.send(_:)`가 deprecated typed `send()`를 호출하지 않고 `NXRequestBuilder.send(as:)`로 위임하도록 변경
- [x] typed Builder의 `raw()`·`send()` 사용 중단 안내 추가, 타입 자체는 유지
- [x] retry·인증·interceptor·cache·cancellation 회귀 테스트의 정식 경로 전환
- [x] `swift test` 실행
- [x] `refactor: 호환 요청 경로를 정식 흐름으로 연결` commit

### Task 3: 공개 문서 전환

**Files:**

- Modify: `Sources/Nexa/Nexa.docc/Nexa.md`
- Modify: `Sources/Nexa/Public/NXRequestBuilder.swift`
- Modify: `Sources/Nexa/Public/NXAPIClient.swift`
- Modify: `Sources/Nexa/Public/NXTypedRequestBuilder.swift`
- Modify: `README.md`
- Modify: `README.ko.md`
- Modify: `.agents/specs/52-request-builder-send-path.md`
- Modify: `.agents/plans/2026-08-22-request-builder-send-path.md`

**Interfaces:**

- Consumes: Task 1과 Task 2의 정식·호환 요청 경로
- Produces: 신규 사용 경로와 migration 안내

- [x] 빠른 시작과 공개 API 표를 `send()`·`send(as:)` 중심으로 전환
- [x] 기존 `raw()`·`.as(_:)`·typed HTTP method overload의 대응표 추가
- [x] Endpoint 경로와 빈 응답 처리 제외 범위 명시
- [x] `swift build`, `swift test`, 변경 Swift 파일 SwiftLint, `git diff --check` 실행
- [ ] `docs: 요청 전송 경로 안내 추가` commit
