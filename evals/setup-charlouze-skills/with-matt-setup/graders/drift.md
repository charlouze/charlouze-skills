---
type: regex
target: { source: file, path: docs/agents/triage-labels.md }
pattern: '(?:^|\n)## Drift[ \t]*\r?\n\s*<!-- charlouze-skills -->(?=[\s\S]*needs-triage)(?=[\s\S]*context:<context>)(?=[\s\S]*`bug`)(?=[\s\S]*`enhancement`)(?=[\s\S]*Audit <part> against the functional spec)'
match: "count:1"
---
`docs/agents/triage-labels.md` has one tagged `## Drift` section: issues labelled `needs-triage` and `context:<context>`, a violation as `bug`, a gap as `enhancement`, and the audit issue.
