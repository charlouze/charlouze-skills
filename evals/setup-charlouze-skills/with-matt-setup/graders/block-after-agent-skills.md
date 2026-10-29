---
type: regex
target: { source: file, path: CLAUDE.md }
pattern: '(?:^|\n)## Agent skills\r?\n(?:(?!#{1,2}[ \t])[^\r\n]*\r?\n)*## charlouze-skills[ \t]*\r?\n(?:(?!#{1,2}[ \t])[^\r\n]*\r?\n)*## Conventions\r?\n'
---
The `## charlouze-skills` block comes right after the `## Agent skills` section, before the section that followed it.
