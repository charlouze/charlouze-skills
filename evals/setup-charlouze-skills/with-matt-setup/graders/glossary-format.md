---
type: regex
target: { source: file, path: docs/agents/domain.md }
pattern: '(?:^|\n)## Glossary format[ \t]*\r?\n\s*<!-- charlouze-skills -->(?=[\s\S]*_Code_:)(?=[\s\S]*\n## Borrowed)(?=[\s\S]*owned by)'
match: "count:1"
---
`docs/agents/domain.md` has one tagged `## Glossary format` section, which adds the `_Code_:` line and the `## Borrowed` heading, each borrowed term naming its owning context.
