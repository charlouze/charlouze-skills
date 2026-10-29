---
type: tool_used
tool: Write
input_match: '"file_path"\s*:\s*"[^"]*\.claude[\\/]+settings\.local\.json"|(?:supercharlouze|superpowers)@[\w.-]+\\"\s*:\s*false|^(?=.*"file_path"\s*:\s*"[^"]*\.claude[\\/]+settings\.json")(?!.*supercharlouze@supercharlouze)'
min: 0
max: 0
---
The session disables no plugin through a Write: it never writes `.claude/settings.local.json`, never sets a competing plugin to `false`, and never writes `.claude/settings.json` without `supercharlouze@supercharlouze`.

Judged on the call, not the file: Claude Code refuses every headless write under `.claude/`, so the file cannot change after a run, whatever the session tries.
