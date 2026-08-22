# Nexa General Agent Rules

## Logic preservation and optimization

- Existing program logic reuse as default.
- Logic change only with identical result and strict time or space complexity improvement, or explicit user request.
- No clear complexity improvement as original logic retention.

## Swift style

- Explicit type annotation only when required.
- New Swift file header author as `opfic`.
- Clear expression available case prefers `<` or `<=` over `>` or `>=`.
- Public API change requires DocC documentation, public test coverage, and `README.md` or `README.ko.md` review.
- `Sendable`, actor isolation, cancellation, and error mapping as explicit review points for concurrency changes.

## Documentation and response

- AI workflow and rule documents under `.agents/`.
- Approved workflow Specs under `.agents/specs/`.
- `docs/` as no location for AI workflow documents.
- Code modification response as precise changed location and modified code only unless user requests explanation.
- Nexa PR and review text in Korean.

## Repository-local rules

- Nexa working rules belong in this repository.
- `AGENTS.md` and routed `.agents/` documents as canonical Nexa rules.
- Repository-local rule priority over global memory.
