---
description: On a repo whose CLAUDE.md carries another flow's instructions, the setup proposes a removal or a rewording of each contrary instruction, and with no answer from the human applies none.
runs: 3
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
plugins: ["../../.."]
---
/charlouze-skills:setup-charlouze-skills Documents language: English.
