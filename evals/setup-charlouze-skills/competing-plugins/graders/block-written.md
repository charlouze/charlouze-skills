---
type: regex
target: { source: file, path: CLAUDE.md }
pattern: '(?:^|\n)## Agent skills\r?\n(?:(?!#{1,2}[ \t])[^\r\n]*\r?\n)*## charlouze-skills[ \t]*\r?\n(?:(?!#{1,2}[ \t])[^\r\n]*\r?\n)*Language of produced documents ?: ?English[ \t]*\r?\n(?:(?!#{1,2}[ \t])[^\r\n]*\r?\n)*## Conventions\r?\n'
---
The yes the human gave applies to the plugin's own changes: the `## charlouze-skills` block, with `Language of produced documents: English`, sits right after `## Agent skills`.
