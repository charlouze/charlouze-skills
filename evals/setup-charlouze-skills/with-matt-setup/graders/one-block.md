---
type: regex
target: { source: file, path: CLAUDE.md }
pattern: '(?:^|\n)## charlouze-skills\b'
match: "count:1"
---
CLAUDE.md holds exactly one `## charlouze-skills` block.
