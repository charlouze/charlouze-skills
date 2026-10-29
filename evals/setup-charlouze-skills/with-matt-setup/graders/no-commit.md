---
type: regex
target: { source: file, path: .git/logs/HEAD }
pattern: '\tcommit'
match: "count:1"
---
The only commit in the reflog is the fixture's: the setup leaves its changes uncommitted.
