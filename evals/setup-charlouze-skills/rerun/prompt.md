---
description: Rerun on a repo the setup already prepared, with its settings reformatted by `claude plugin install`, changes nothing.
runs: 3
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
plugins: ["../../.."]
---
/charlouze-skills:setup-charlouze-skills Yes to every proposed change.
