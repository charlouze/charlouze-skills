---
type: regex
target: { source: file, path: docs/agents/domain.md }
pattern: '(?:^|\n)## File structure[ \t]*\r?\n\s*<!-- charlouze-skills -->(?:(?!\n#{1,2} )[\s\S])*GLOSSARY-MAP\.md(?:(?!\n#{1,2} )[\s\S])*contexts\/(?:(?!\n#{1,2} )[\s\S])*SPEC\.md(?:(?!\n#{1,2} )[\s\S])*GLOSSARY\.md'
match: "count:1"
---
The `## File structure` section of `docs/agents/domain.md` is tagged and lays out the repo for several contexts: `GLOSSARY-MAP.md`, then each context's `SPEC.md` and `GLOSSARY.md` under `docs/contexts/`.
