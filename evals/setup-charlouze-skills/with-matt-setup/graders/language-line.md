---
type: regex
target: { source: file, path: CLAUDE.md }
pattern: '(?:^|\n)## charlouze-skills[ \t]*\r?\n(?:(?!#{1,2}[ \t])[^\r\n]*\r?\n)*Language of produced documents ?: ?(?:French|Français|français)[ \t]*\r?\n'
---
The block carries the line `Language of produced documents: <language>` with the language the human gave (French).
