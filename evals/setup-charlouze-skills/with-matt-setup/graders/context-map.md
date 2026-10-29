---
type: regex
target: { source: file, path: docs/agents/domain.md }
pattern: '(?:^|\n)## Context map[ \t]*\r?\n\s*<!-- charlouze-skills -->(?=[\s\S]*\n## Contexts)(?=[\s\S]*\n## Relationships)(?=[\s\S]*\(core\))(?=[\s\S]*`supporting`)(?=[\s\S]*`generic`)(?=[\s\S]*`conformist`)(?=[\s\S]*`translation`)(?=[\s\S]*Every borrowing implies a relationship)(?=[\s\S]*differentiation)(?=[\s\S]*outsourcing)(?=[\s\S]*competence)'
match: "count:1"
---
`docs/agents/domain.md` has one tagged `## Context map` section giving the shape of `GLOSSARY-MAP.md`: `## Contexts` with the subdomains, `## Relationships` with the two modes, the borrowing invariant, and the three tests.
