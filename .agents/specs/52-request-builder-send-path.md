# NXRequestBuilder의 단일 send 경로 구성

- Source: https://github.com/opficdev/Nexa/issues/52
- Approved Designer Result: `NXRequestBuilder` 단일 요청 흐름과 raw 응답 API 제거 설계
- User approval: 2026-08-22 `raw 제거`

## Constraints

- Nexa 1.3에서 `NXRequestBuilder.raw()`와 `NXTypedRequestBuilder.raw()` 공개 API 제거
- `NXRequestExecutor`의 요청 조립, interceptor, transport, validation, decoding, cancellation, cache 흐름 보존
- `NXEndpoint.configure(_:)` 시그니처와 `client.send(_:)` 동작 보존
- `NXTypedRequestBuilder<Response>` 타입의 사용 중단 표시 금지
- App 또는 Simulator 실행 금지
- 빈 응답 본문 처리와 `204 No Content` 지원 제외

## Alternatives and decision

- 새 `NXRequest` 타입 추가 제외. 기존 `NXRequestBuilder`와 신규 흐름의 병존 발생
- typed HTTP method overload와 `NXTypedRequestBuilder` 즉시 제거 제외. 1.3 호환성 훼손
- `NXEndpoint.configure(_:)`의 builder 타입 변경 제외. 기존 endpoint 구현체 호환성 훼손
- `NXRequestBuilder`에 raw `send()`, 문맥 기반 generic `send()`, 명시적 `send(as:)` 추가 선택
- `raw()` 사용 중단 API 유지 제외. 단일 raw 응답 경로 요구와 공개 API 축소 요구에 어긋남

## Changed boundaries

- `NXRequestBuilder`를 문자열 path 기반 요청의 정식 구성·실행 경계로 설정
- `NXRequestBuilder.raw()`와 `NXTypedRequestBuilder.raw()` 공개 선언 제거
- `as(_:)`와 typed HTTP method overload는 대체 경로 안내가 있는 사용 중단 API로 유지
- `NXTypedRequestBuilder<Response>`는 endpoint 호환성 경계로 유지하고 새 `NXRequestBuilder` 전송 경로로 위임
- `NXEndpoint`의 공개 계약 변경 없음

## Acceptance criteria

- [x] `client.get(path).send()`가 타입 문맥 없이 `NXRawResponse` 반환
- [x] `let value: Response = try await client.get(path).send()`가 `Response` 디코딩
- [x] `client.get(path).send(as: Response.self)`가 `Response` 디코딩
- [ ] `Sources/Nexa/Public`에 `public func raw()` 선언 없음
- [ ] `Tests/NexaTests`에 `.raw()` 실행 호출 없음
- [x] `as(_:)`, typed HTTP method overload에 사용 중단 표시와 대체 경로 안내
- [x] `NXTypedRequestBuilder<Response>` 타입의 사용 중단 표시 없음
- [x] `NXEndpoint.configure(_:)`, `client.request(_:)`, `client.send(_:)` 호환 동작 보존
- [x] transport 대체, retry, 인증, cache, validation, interceptor, 오류 매핑, cancellation 동작 보존
- [x] `README.md`, `README.ko.md`, DocC의 정식 경로와 migration 안내 갱신
- [ ] 공개 문서에 `raw()` 제거와 Endpoint 원시 응답 제한 명시

## Verification

- Command: `swift build`
- Evidence: 2026-08-22 exit status `0`
- Command: `swift test`
- Evidence: 2026-08-22 43개 테스트 통과
- Command: 변경 Swift 파일 SwiftLint
- Evidence: 2026-08-22 변경 Swift 파일 3개에서 위반 0건
- Command: `git diff --check`
- Evidence: 2026-08-22 공백 오류 없음

## Minimum commit units

1. `feat: NXRequestBuilder 전송 경로 추가`
2. `refactor: 호환 요청 경로를 정식 흐름으로 연결`
3. `docs: 요청 전송 경로 안내 추가`
4. `docs: raw 응답 API 제거 요구사항 갱신`
5. `refactor: raw 응답 API 제거`
6. `docs: raw 응답 전환 안내 갱신`

## Execution constraints

- App or Simulator execution: 금지
- External writes: commit만 승인, push·PR 생성 미승인
- CI or PR actions: 미승인
