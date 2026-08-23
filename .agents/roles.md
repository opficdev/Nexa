# Nexa Agent Roles

## Purpose

Runnable AI role workflow for Nexa work. Role assignment, approved Spec handoff, final review, and verification evidence as operational requirements.

`AGENTS.md` as canonical repository rule entrypoint. Conflicting rules resolved by `AGENTS.md`.

## Operating rules

- One active writer per file.
- Overlapping file scopes not assigned to multiple editing roles.
- Read-only roles without file edit, staging, commit, push, review-thread resolution, or GitHub state changes unless user authority and role permission.
- Active main agent as integration owner, final diff inspector, and final user report owner.
- Build-only checks allowed. App, Simulator, installation, boot, and launch without current-turn user authority prohibited.
- AI workflow documents under `.agents/`; approved Specs under `.agents/specs/`; no AI workflow documents under `docs/`.
- Non-trivial work order: `Design Brief → Designer Result → 사용자 승인 → Spec → Task Packet → Implementer → Code Reviewer → Verification Runner`.
- Requirement or scope changes during implementation requiring Spec update and renewed user approval.
- For review feedback, GitHub/CI Analyst collects only live GitHub facts: thread ID, body, author, resolved state, commit SHA, file and line, CI conclusion, and log excerpt. The Analyst does not determine technical validity, priority, scope inclusion, or required code changes.
- For review feedback, Designer compares the Analyst facts with code, diff, approved Spec, and architecture constraints, then owns the `required`, `optional`, `already handled`, or `rejected` classification and its evidence.

## Model assignment

| Tier | Use | Model |
| --- | --- | --- |
| `Primary` | Planning, implementation, public API decisions, final integration, failed-check triage | Active strongest coding model |
| `SDD Gate` | Design analysis and final diff review | `gpt-5.6-sol`, `xhigh` |
| `Lightweight` | Read-only review, checklist validation, CI log summary, documentation draft, architecture preflight | `gpt-5.3-codex-spark`; unavailable state uses matching `gpt-5.6-luna`, `high` |

| Role | Owner or custom agent | Tier |
| --- | --- | --- |
| Planner | Active main agent | `Primary` |
| Designer | `designer` | `SDD Gate` |
| Implementer | Active main agent | `Primary` |
| Architecture Watcher | `architecture_watcher` | `Lightweight` |
| Code Reviewer | `code_reviewer` | `SDD Gate` |
| Verification Runner | `verification_runner` | `Lightweight` |
| GitHub/CI Analyst | `github_ci_analyst` | `Lightweight` |
| Documentation Writer | `documentation_writer` | `Lightweight` |

## Dispatch and fallback policy

- `Designer` and `Code Reviewer` as `gpt-5.6-sol` and `xhigh` only. Luna fallback prohibition.
- Existing Lightweight roles as Spark-first. Spark unavailability allows only the same role's `*_luna` configuration with `gpt-5.6-luna` and `high`.
- `*_luna` role as no substitute for `Designer`, `Code Reviewer`, `Planner`, or `Implementer`.
- Connected side task `task_name` as exact `.codex/agents/<name>.toml` filename without extension.
- Repeated work for an existing role as `followup_task` dispatch.
- `Block`, `Needs Owner Decision`, `Fail`, unclear cause, boundary uncertainty, or missing required verification as escalation to `Primary`.

## Task Packet

```md
## Task Packet

- Source:
- Approved Spec:
- Goal:
- Scope:
- Out of scope:
- Acceptance criteria:
- Expected changed files:
- Current owner:
- Architecture risk: none / possible / confirmed
- Required roles:
- Model assignment:
- Execution authority: app or Simulator / external writes / CI or PR actions
- Verification:
- Stop conditions:
```

## Role outputs

### Planner

```md
## Planner Result

- Goal:
- Scope:
- Out of scope:
- Required roles:
- Design Brief:
- Approved Spec:
- Handoff packet:
- User decision needed:
```

### Designer

```md
## Designer Result

- Design Brief:
- Constraints:
- Alternatives:
- Changed boundaries:
- Acceptance criteria:
- Verification:
- Minimum commit units:
- Spec path:
- User approval needed:
- Review feedback classification:
- Code, Spec, or architecture evidence:
- Scope impact:
```

### Implementer

```md
## Implementer Result

- Changed files:
- Scope notes:
- Architecture-sensitive changes:
- Verification suggested:
```

### Architecture Watcher

```md
## Architecture Watch Result

- Verdict: Pass / Block / Needs Owner Decision
- Public API impact:
- Swift Concurrency impact:
- Package target impact:
- Dependency direction:
- Findings:
- Required user decision:
```

### Code Reviewer

```md
## Code Review Result

- Findings:
- Acceptance criteria coverage:
- Scope drift:
- Verification gaps:
- Verdict: Pass / Needs Owner Decision / Fail
```

### Verification Runner

```md
## Verification Result

- Commands:
- Exit status:
- Acceptance-criterion evidence:
- Unrun checks:
- Verdict: Pass / Fail
```

### GitHub/CI Analyst

```md
## GitHub CI Result

- Source checked:
- Observed facts:
- CI state:
- Missing evidence:
```

### Documentation Writer

```md
## Documentation Result

- Target:
- Source checked:
- Draft or changed files:
- Verification:
```
