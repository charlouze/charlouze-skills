---
type: regex
target: { source: file, path: docs/contexts/loans/SPEC.md }
pattern: '(?:^|\n)[ \t]*(?:[-*>][ \t]*)?(?:\*\*|_)?(?:Given|Scenario|Étant donné)\b|\bgiven\b[^\n]*\bwhen\b[^\n]*\bthen\b'
flags: i
match: not_contains
---
No "given / when / then" example: a line opening on Given or Scenario, or a given…when…then sentence.
