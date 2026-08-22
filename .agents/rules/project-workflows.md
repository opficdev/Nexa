# Nexa Project Workflows

## Verification

| Change | Required checks |
| --- | --- |
| Swift source or test | `swift build`, `swift test`, changed-file SwiftLint when available |
| Public API or DocC | `swift build`, `swift test`, `README.md` and `README.ko.md` review |
| Package manifest | `swift build`, `swift test`, package dependency diff review |
| AI workflow documents or agent TOML | `git diff --check -- AGENTS.md .agents .codex/agents`, role-model-fallback checks |
| CI workflow | YAML review and affected workflow check when available |

- `swift build` exit status `0` as build success evidence.
- `swift test` exit status `0` as test success evidence.
- Missing SwiftLint binary as unrun check report, not lint success claim.
- App, Simulator, launch, installation, boot, and build-and-run commands without current-turn user authority prohibited.

## Git and delivery

- Commit as smallest independently reviewable change.
- Existing unrelated working-tree changes as user-owned changes.
- Commit, push, PR creation, review reply, review-thread resolution, release, or tag creation only with explicit user authority.
- Live issue, PR, review thread, CI run, or release state as GitHub source-of-truth requirement.

## Commit guidance

- Commit message starts with a short prefix used by recent local commits: `feat`, `fix`, `refactor`, `chore`, `test`, `docs`, `ui`, or `rollback`.
- Commit message prose in Korean.
- Implementation names, file paths, commands, branch names, and commit hashes in original form.
- Commit message body prohibition.
- Commit message proposal requires actual diff and recent non-merge `git log` inspection.
- GitHub merge subject such as `[#123] ... (#456)` as no commit-message-style source. Merge commit requires individual commit message inspection.
- Current repository Korean style and prefix pattern as matching requirement.
- User-specified prefix or noun-phrase ending as exact requirement.
- Broad refactor commit split by independent layer or responsibility when user requests staged commits.

## Documentation

- README changes as English and Korean document parity review.
- PR body uses `.github/pull_request_template.md`.
- Documentation-only work report includes unrun build, test, app, and Simulator checks.
- AI workflow documents stay under `.agents/` and `.codex/agents/`.
