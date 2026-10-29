---
type: regex
target: { source: file, path: CLAUDE.md }
pattern: '^# Tool library\n\nA neighbourhood tool-lending app: members borrow tools, volunteers run the counter\.\n\n## Agent skills\n\n### Issue tracker\n\nIssues are tracked in this repo''s GitHub Issues, via the `gh` CLI\. See `docs\/agents\/issue-tracker\.md`\.\n\n### Triage labels\n\nDefault vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`\. See `docs\/agents\/triage-labels\.md`\.\n\n### Domain docs\n\n[\s\S]*\n## Conventions\n\n- Run the test suite with `npm test` before every commit\.\n- Dates are shown in the member''s local time zone\.\n$'
---
Everything around the new block is as `_fixtures/matt-setup/CLAUDE.md` left it: the title, Matt's block and the `## Conventions` section. The line under `### Domain docs`, which the setup rewrites, is judged by `layout-domain-docs-line`.
