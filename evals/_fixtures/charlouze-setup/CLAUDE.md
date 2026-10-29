# Tool library

A neighbourhood tool-lending app: members borrow tools, volunteers run the counter.

## Agent skills

### Issue tracker

Issues are tracked in this repo's GitHub Issues, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Multi-context: `GLOSSARY-MAP.md` at the repo root from the first context, each context's `SPEC.md` and `GLOSSARY.md` in `docs/contexts/<context>/`, one `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## charlouze-skills

Language of produced documents: English

## Conventions

- Run the test suite with `npm test` before every commit.
- Dates are shown in the member's local time zone.
