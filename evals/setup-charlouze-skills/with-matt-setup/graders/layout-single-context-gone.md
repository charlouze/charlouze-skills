---
type: regex
target: { source: file, path: docs/agents/domain.md }
pattern: 'Single-context repo|\bsrc\/[\s│├└─]*ordering\/'
match: not_contains
---
Matt's layout is gone from `docs/agents/domain.md`: no single-context repo, no glossary under `src/<context>/`. Passes vacuously without the file, which `layout-file-structure` requires.
