---
description: On a GitHub repo with Matt's setup, the setup writes the CLAUDE.md block with the chosen language and declares the plugins in the project settings, and nothing else.
runs: 3
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
plugins: ["../../.."]
---
/charlouze-skills:setup-charlouze-skills Documents language: French. Yes to every proposed change.
