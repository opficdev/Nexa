# Nexa Role Workflows

## Common sequence

Non-trivial work sequence:

1. Planner creates `Design Brief`.
2. Designer returns `Designer Result`.
3. User approves `Designer Result`.
4. Planner persists approved Spec and creates `Task Packet`.
5. Implementer changes assigned scope.
6. Architecture Watcher reviews architecture-sensitive scope.
7. Code Reviewer reviews final diff.
8. Verification Runner records acceptance-criterion evidence and runs allowed checks.

## Issue-driven implementation

### Role order

1. GitHub/CI Analyst when live issue or PR state matters.
2. Planner.
3. Designer.
4. User approval, Spec, and Task Packet.
5. Architecture Watcher when public API, concurrency, package manifest, dependency, or request execution ordering risk.
6. Implementer.
7. Code Reviewer.
8. Verification Runner.

### Completion record

```md
## Workflow Result

- Workflow: Issue-driven implementation
- Approved Spec:
- Changed files:
- Architecture decision:
- Verification:
- Remaining decisions:
```

## Review feedback

### Role order

1. GitHub/CI Analyst.
2. Planner.
3. Designer.
4. User approval, Spec, and Task Packet.
5. Architecture Watcher when architecture-sensitive scope.
6. Implementer.
7. Code Reviewer.
8. Verification Runner.
9. GitHub/CI Analyst when user requested review reply or resolution.

### Execution

- Planner classifies feedback as required, optional, already handled, or rejected.
- Implementer applies accepted feedback only.
- GitHub write actions require explicit user authority.

## CI failure triage

### Role order

1. GitHub/CI Analyst inspects run, job, and failing log excerpts.
2. Planner creates `Design Brief` with workflow, environment, dependency, or source failure classification.
3. Designer.
4. User approval, Spec, and Task Packet.
5. Verification Runner reproduces allowed local checks.
6. Implementer after concrete root cause.
7. Code Reviewer.
8. Verification Runner.

## Documentation-only writing

### Role order

1. Planner and Designer for non-trivial scope.
2. User approval, Spec, and Task Packet when required.
3. Documentation Writer.
4. Code Reviewer when wording must match changed behavior.
5. GitHub/CI Analyst when live GitHub state matters.
6. Verification Runner for Markdown and file checks.

### Execution

- Documentation Writer checks actual diff before PR or release text.
- User text-only request as direct text output without file creation.
- `README.md` and `README.ko.md` parity review for public API documentation.

## AI workflow maintenance

### Role order

1. Planner.
2. Designer.
3. User approval, Spec, and Task Packet.
4. Implementer.
5. Architecture Watcher when public API or package architecture policy changes.
6. Code Reviewer.
7. Verification Runner.

### Verification

```sh
git diff --check -- AGENTS.md .agents .codex/agents
test -f .codex/agents/designer.toml
test ! -e .codex/agents/designer_luna.toml
test ! -e .codex/agents/code_reviewer_luna.toml
rg -qx 'model = "gpt-5.6-sol"' .codex/agents/designer.toml
rg -qx 'model_reasoning_effort = "xhigh"' .codex/agents/designer.toml
rg -qx 'model = "gpt-5.6-sol"' .codex/agents/code_reviewer.toml
rg -qx 'model_reasoning_effort = "xhigh"' .codex/agents/code_reviewer.toml
```
