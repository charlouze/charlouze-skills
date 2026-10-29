---
description: On a repo that never ran Matt's setup, the setup stops, asks for /setup-matt-pocock-skills, and writes nothing.
runs: 3
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
plugins: ["../../.."]
---
/charlouze-skills:setup-charlouze-skills Documents language: English. Yes to every proposed change.
