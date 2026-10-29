---
type: regex
target: { source: file, path: CLAUDE.md }
pattern: '^# Tool library\n\nA neighbourhood tool-lending app: members borrow tools, volunteers run the counter\.\n\n## Agent skills\n\n### Issue tracker\n\nIssues are tracked in this repo''s GitHub Issues, via the `gh` CLI\. See `docs\/agents\/issue-tracker\.md`\.\n\n### Triage labels\n\nDefault vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`\. See `docs\/agents\/triage-labels\.md`\.\n\n### Domain docs\n\nMulti-context: `GLOSSARY-MAP\.md` at the repo root from the first context, each context''s `SPEC\.md` and `GLOSSARY\.md` in `docs\/contexts\/<context>\/`, one `docs\/adr\/` at the repo root\. See `docs\/agents\/domain\.md`\.\n\n## charlouze-skills\n\nLanguage of produced documents: English\n\n## Conventions\n\n- Run the test suite with `npm test` before every commit\.\n- Dates are shown in the member''s local time zone\.\n$'
---
CLAUDE.md is byte for byte `_fixtures/charlouze-setup/CLAUDE.md`: the multi-context `### Domain docs` line is back, and the rest is as the fixture left it (regenerate the pattern if that file changes).
