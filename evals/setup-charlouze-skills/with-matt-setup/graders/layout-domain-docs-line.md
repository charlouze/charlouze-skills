---
type: regex
target: { source: file, path: CLAUDE.md }
pattern: '(?:^|\n)### Domain docs[ \t]*\r?\n\r?\n(?=[^\r\n]*GLOSSARY-MAP\.md)(?=[^\r\n]*docs\/contexts\/)(?=[^\r\n]*SPEC\.md)(?=[^\r\n]*docs\/adr\/)(?![^\r\n]*Single-context)[^\r\n]*docs\/agents\/domain\.md[^\r\n]*\r?\n'
---
The line under `### Domain docs` in Matt's block is multi-context: `GLOSSARY-MAP.md`, `docs/contexts/<context>/` with its `SPEC.md`, and `docs/adr/`, still pointing at `docs/agents/domain.md`.
