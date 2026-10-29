---
description: Rerun after a rerun of Matt's setup redoes the multi-context layout and the tagged sections of docs/agents/, exactly as a first setup writes them, and nothing else.
runs: 3
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
plugins: ["../../.."]
---
/charlouze-skills:setup-charlouze-skills Yes to every proposed change.
