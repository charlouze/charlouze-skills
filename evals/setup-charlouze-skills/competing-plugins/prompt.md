---
description: On a repo that still enables competing flow plugins, when the human says yes to every change before seeing any, the setup writes the block, keeps every contrary instruction (a yes given before its proposal was shown is no yes to it), disables no plugin, and leaves to the human the /plugin commands that disable the competing ones, with the contrary instructions still awaiting a yes.
runs: 3
max_turns: 30
timeout_seconds: 600
allowed_tools: [Read, Glob, Grep, Skill]
plugins: ["../../.."]
---
/charlouze-skills:setup-charlouze-skills Documents language: English. Yes to every proposed change.
