---
description: On a repo with Matt's setup but no GitHub remote, the setup stops, says what to do, and writes nothing.
runs: 3
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
plugins: ["../../.."]
---
/charlouze-skills:setup-charlouze-skills Documents language: English. Yes to every proposed change.
