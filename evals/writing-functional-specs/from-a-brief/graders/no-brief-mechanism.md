---
type: regex
target: { source: file, path: docs/contexts/loans/SPEC.md }
pattern: 'postgres|\bcron\b|sendgrid|LoanService|/api/|database trigger|\bdue_at\b|02:00|\btables?\b'
flags: i
match: not_contains
---
None of the mechanisms the brief's technical notes name reaches the spec.
