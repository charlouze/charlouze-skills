---
type: tool_used
tool: Edit
input_match: '"file_path"\s*:\s*"[^"]*\.claude[\\/]+settings(?:\.local)?\.json"'
min: 0
max: 0
---
The session never edits the settings: without a yes nothing is written, and a competing plugin is only reported, never disabled by the setup.

Judged on the call, not the file: Claude Code refuses every headless write under `.claude/`, so the file cannot change after a run, whatever the session tries.
