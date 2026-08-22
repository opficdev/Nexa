# Nexa Agent Instructions

## Scope

- These instructions apply to the repository root.
- Read every route that matches the current task.

## Required routing

| Task | Required document |
| --- | --- |
| Every task | `.agents/rules/general.md` |
| Non-trivial design, planning, implementation, review, or verification | `.agents/roles.md` |
| Repeatable role-based execution | `.agents/workflows.md` |
| Public API, Swift Concurrency, package target, dependency, transport, cache, interceptor, or architecture documentation | `.agents/rules/architecture.md` |
| PR, review thread, commit, CI, release, documentation, or verification | `.agents/rules/project-workflows.md` |

## Routing rules

- `AGENTS.md` as canonical repository rule entrypoint.
- `.agents/rules/general.md` as rule for every task.
- All matched task-specific documents as required reading before planning, editing, reviewing, or verification.
- `README.md` as required reading before public API or architecture documentation edits.
- Non-trivial design or implementation workflow requires `Designer` result and approved Spec before Task Packet.
- Independent read-only review and CI analysis have no approved Spec requirement.
- Nexa public API, Swift Concurrency behavior, package target dependencies, and existing request behavior as explicit scope boundaries.
- Nexa PR and review text in Korean.

## Local planning artifacts

- Non-trivial design or implementation workflow requires `Designer` result, user approval, and an approved local Spec before Task Packet.
- Store Specs under `.agents/specs/` and Plans under `.agents/plans/`; both directories are local debugging artifacts and Git ignores them.
- A Spec records source, approved Designer Result, user approval, constraints, alternatives and decision, changed boundaries, acceptance criteria, verification, minimum commit units, and execution constraints.
- A Plan records the approved Spec path, task units, scope, changed files, acceptance criteria, verification, and commit units.
