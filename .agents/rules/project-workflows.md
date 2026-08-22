# Nexa Project Workflows

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
