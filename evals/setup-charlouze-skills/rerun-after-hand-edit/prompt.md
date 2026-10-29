---
description: Rerun after the human changed values the setup wrote (the documents language, the marketplace's autoUpdate) keeps both values and changes nothing.
runs: 3
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
plugins: ["../../.."]
---
/charlouze-skills:setup-charlouze-skills Yes to every proposed change.
