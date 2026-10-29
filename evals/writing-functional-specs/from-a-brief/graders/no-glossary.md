---
type: regex
target: { source: file, path: docs/contexts/loans/SPEC.md }
pattern: '(?:^|\n)#{1,6}[ \t]+(?:Glossary|Glossaire|Terms|Terminology|Definitions|Vocabulary|Language)\b'
flags: i
match: not_contains
---
No glossary section: the context's terms live in its glossary, beside the spec.
