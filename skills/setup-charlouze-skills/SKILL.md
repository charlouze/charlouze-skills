---
name: setup-charlouze-skills
description: Prepare this repo for the charlouze-skills plugin, on top of Matt's setup: the CLAUDE.md block, the project's plugin settings, and a report of what is left to do. Safe to rerun.
argument-hint: "[documents language] [yes]"
disable-model-invocation: true
---

# Setup charlouze-skills

Prepare the repo for the plugin on top of what `/setup-matt-pocock-skills` left. Work in the working tree only.

## Rules

These hold at every step.

- **Matt's setup comes first.** This setup completes it and never stands in for it: when a prerequisite fails, stop with every file as it was.
- **Idempotent.** Add only what is missing. A value already present is the human's, even when it differs from what this setup would write: keep it, and list it under **Kept** in the report. Compare values, never bytes: formatting, key order and indentation are not changes.
- **Show before writing.** Every change is shown to the human, then written only after a yes (step 4).
- **Scope.** The changes are the ones step 3 plans, and nothing else: no context (`GLOSSARY-MAP.md`, `docs/contexts/`), no label, no commit, no other skill run.
- **Arguments.** Words after the command pre-answer this setup's questions: a documents language, a yes to the proposed changes. Take them as the human's answers; every change is still shown.

## Steps

### 1. Check the prerequisites

Check each one, then stop if any fails, listing every failure and what to do about it.

- **Matt's setup.** The agent instructions file (`CLAUDE.md`, else `AGENTS.md`, at the repo root) holds an `## Agent skills` block, and `docs/agents/` holds `issue-tracker.md`, `domain.md` and `triage-labels.md`. What to do: run `/setup-matt-pocock-skills` (its triage section adds `triage-labels.md`), then rerun this setup.
- **GitHub tracker.** `docs/agents/issue-tracker.md` sends issues to GitHub. What to do: rerun `/setup-matt-pocock-skills` and pick GitHub; the plugin has no other tracker.
- **GitHub remote.** A remote of the repo points at `github.com`. Read the `[remote …]` sections of `.git/config`; when `.git` is a file, follow its `gitdir:` line, then that directory's `commondir`, to the config. What to do: create the GitHub repo if needed, add it as a remote (`git remote add origin https://github.com/<owner>/<repo>.git`), then rerun.

Done when every prerequisite holds. The file holding `## Agent skills` is **the instructions file** for the next steps.

### 2. Gather the signals

Signals inform the report; they stop nothing and change no file.

- **`gh`.** Run `gh auth status`. When it fails, or no shell is available to run it, the report asks for `gh auth login`: the plugin's skills write to GitHub through `gh`.

Done when every signal is known.

### 3. Plan the changes

Read each file below and plan its change by it, in this order.

- [claude-md-block.md](claude-md-block.md): the plugin's block in the instructions file.
- [project-settings.md](project-settings.md): the project's plugin settings, `.claude/settings.json`.

Done when each file has its planned change, or "nothing to add".

### 4. Show and confirm

When step 3 planned no change, say the repo is already set up and go to step 6.

Otherwise show every planned change, grouped by file: a unified diff for an existing file, the whole content for a new one. Then ask one question: apply them all? The human may drop or amend any change. Without a yes, write nothing and go to step 6, listing the changes as proposed, not written.

### 5. Write

Apply the confirmed changes exactly as shown, with targeted edits that leave every other line of the file as it was. A write the session refuses stays unwritten: list it under **Left to you** with the content to write.

### 6. Report

End on this report. Write each heading, and under it one line per item; write "nothing" under an empty heading.

- **Written**: each file created or changed, with what was added.
- **Kept**: each value left as the human set it, and the value this setup would have written.
- **Left to you**:
  - Install the plugins for this project, since the project settings alone do not install `mattpocock-skills` (it lives outside its marketplace): in a terminal at the repo root, `claude plugin marketplace add charlouze/charlouze-skills` if that marketplace is unknown, then `claude plugin install charlouze-skills@charlouze-skills --scope project`, which pulls `mattpocock-skills` as a dependency; or the same through `/plugin` in a session. Then `/reload-plugins`. Each collaborator runs the install once.
  - `gh auth login`, when step 2 found `gh` disconnected or could not check it.
  - Review, then commit the changed files. This setup never commits.
- **Cloud sessions**: they do not install the plugins a repo declares; there, the flow is complete only through organisation (server-managed) settings.
- **Next**: work as usual with Matt's flow. A context, its functional spec and its `context:<name>` label are created by the change that needs them, never by this setup. Rerun this setup after the plugin changes or after a rerun of `/setup-matt-pocock-skills`.
