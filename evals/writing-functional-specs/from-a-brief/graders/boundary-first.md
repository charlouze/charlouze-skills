---
type: regex
target: { source: file, path: docs/contexts/loans/SPEC.md }
pattern: '^(?:#[ \t][^\r\n]*\r?\n)?(?:[^#\r\n][^\r\n]*\r?\n|\r?\n)*#{1,3}[ \t]+Boundary\b'
---
The first section of the spec, after an optional title and the prose under it, is `Boundary`.
