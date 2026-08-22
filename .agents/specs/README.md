# Nexa Spec Format

`Designer Result` 사용자 승인 뒤 Planner가 비단순 설계 또는 구현 작업마다 이 디렉터리에 Spec 작성.

- 이슈 기반 작업 파일명: `<issue-number>-<short-topic>.md`
- 이슈 없는 사용자 요청 파일명: `user-<YYYYMMDD>-<short-topic>.md`

## Responsibility

- `Design Brief`: Planner의 요청, 현재 상태, 범위, 제외 범위, 제약 전달물.
- `Designer Result`: Designer의 제약, 대안, 변경 경계, 수용 기준, 검증, 최소 커밋 단위 분석물.
- Spec: 사용자 승인 `Designer Result`의 영속화 및 구현·검토·검증 공통 기준.
- `Task Packet`: 승인 Spec 경로, 수용 기준, 역할 배정, 실행 권한 전달물.

## Required format

```md
# <Spec title>

- Source:
- Approved Designer Result:
- User approval:

## Constraints

-

## Alternatives and decision

-

## Changed boundaries

-

## Acceptance criteria

- [ ]

## Verification

- Command:
- Evidence:

## Minimum commit units

1.

## Execution constraints

- App or Simulator execution:
- External writes:
- CI or PR actions:
```

## Change control

- Requirement or scope changes requiring Spec update and renewed user approval before Task Packet or implementation update.
- Spec as behavior, acceptance criteria, and prohibited execution record.
- Task Packet as role-specific execution authority and actual verification command record.
