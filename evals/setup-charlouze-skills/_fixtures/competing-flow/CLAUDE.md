# Tool library

A neighbourhood tool-lending app: members borrow tools, volunteers run the counter.

## Agent skills

### Issue tracker

Issues are tracked in this repo's GitHub Issues, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Conventions

- Run the test suite with `npm test` before every commit.
- Write each test before its code, following `superpowers:test-driven-development`.
- Dates are shown in the member's local time zone.

<!-- supercharlouze:begin -->
## Specs and plans

This project overrides how superpowers organizes specs and plans.
Invoke `supercharlouze:using-batches` before any design work, and again before executing any plan.
It relocates specs and plans, replaces steps 6 to 9 of the architectural checklist of superpowers:brainstorming, extends the stop conditions of superpowers:subagent-driven-development, requires subagent-driven-development as the execution mode, and constrains superpowers:finishing-a-development-branch to the pull request option.
It declares each of these overrides explicitly; where it declares none, superpowers applies unchanged.
<!-- supercharlouze:end -->
