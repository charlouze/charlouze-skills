---
name: setup-charlouze-skills
description: Prepare this repo for the charlouze-skills plugin, on top of Matt's setup: the CLAUDE.md block, the project's plugin settings, the GitHub settings of the git history policy, and a report of what is left to do. Safe to rerun.
argument-hint: "[documents language]"
disable-model-invocation: true
---

# Setup charlouze-skills

Prepare the repo for the plugin on top of what `/setup-matt-pocock-skills` left. Work in the working tree, and on GitHub only for the repository settings the human accepts.

## Rules

These hold at every step.

- **Matt's setup comes first.** This setup completes it and never stands in for it: when a prerequisite fails, stop with every file as it was.
- **Idempotent.** Add only what is missing. A value already present in a file is the human's, even when it differs from what this setup would write: keep it, and list it under **Kept** in the report. Compare values, never bytes: formatting, key order and indentation are not changes.
- **Show before writing.** Every change is shown to the human, then written only after its yes (step 4).
- **Scope.** The working tree ends with the changes step 3 planned and the human confirmed, uncommitted, and nothing more. On GitHub, only the repository settings the human confirmed change. Contexts (`GLOSSARY-MAP.md`, `docs/contexts/`) and their labels are created by the change that needs them, and other skills are the human's to run.

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
- **`gh stack`.** Run `gh extension list`. When no line names `github/gh-stack`, or no shell is available to run it, the report asks for the extension: the block's ``Stacked delivery with `implement-spec` `` section links the stack through it. The rest of the plugin works without it.
- **Competing flow plugins.** Find each enabled plugin of a competing flow, by the "Competing flow plugins" section of [competing-flows.md](competing-flows.md).
- **Missing grids.** Read the grids declaration that `grid-review` reads: `docs/agents/grids.md`, or [the default declaration](../grid-review/default-grids.md) when that file is missing. A declared grid is missing when none of your available skills bears its skill's short name, bare or after a `<plugin>:` prefix: `clean-code` is found as `clean-code` or as `code-craftsmanship:clean-code`. Note each missing grid's skill, and whether the default declaration names that skill too.

Done when every signal is known.

### 3. Plan the changes

Read each file below and plan its change by it, in this order.

- [claude-md-block.md](claude-md-block.md): the plugin's block in the instructions file, its lines and its sections.
- [matt-files.md](matt-files.md): the plugin's tagged sections in Matt's `docs/agents/domain.md` and `triage-labels.md`, and the multi-context layout in `domain.md` and the instructions file.
- [grids-file.md](grids-file.md): the project's declaration of its grids, `docs/agents/grids.md`.
- [change-spec-file.md](change-spec-file.md): the instructions that complete `/to-spec`, `docs/agents/change-spec.md`.
- [git-history-file.md](git-history-file.md): the project's git history policy, `docs/agents/git-history.md`.
- [run-file.md](run-file.md): the project's reserved zones, `docs/agents/run.md`.
- [project-settings.md](project-settings.md): the project's plugin settings, `.claude/settings.json`.
- [github-settings.md](github-settings.md): the repository settings the git history policy needs, on GitHub.
- [competing-flows.md](competing-flows.md): a removal or a rewording for each instruction of the instructions file that contradicts the flow.

Done when each file has its planned change, or "nothing to add".

### 4. Show and confirm

When step 3 planned no change, say the repo is already set up and go to step 6.

Otherwise show every planned change, then ask for a yes on each part below, separately. An answer the human already gave stands; ask only what is still open.

- **The plugin's changes**: the block, Matt's files, the grids file, the change spec file, the git history file, the run file and the settings, grouped by file: a unified diff for an existing file, the whole content for a new one. One yes covers them all, including a yes the human gave with the command; the human may drop or amend any of them.
- **The GitHub settings**: the commands [github-settings.md](github-settings.md) planned, each with the settings it changes and what it changes beyond them. They change the repository for everyone, so only a yes given to them after they were shown applies them; the human may drop any of them.
- **Each contrary-instruction proposal**, on its own, shown as [competing-flows.md](competing-flows.md) says. It is the human's own text, so only a yes given to this proposal after it was shown applies it. A yes given earlier, with the command or to the plugin's changes, leaves the instruction as it is.

A part without its yes stays unwritten: carry on to step 5 with the rest, and the report lists it as proposed.

### 5. Write

Apply the changes that have their yes exactly as shown, with targeted edits that leave every other line of the file as it was. A write the session refuses stays unwritten: list it under **Left to you** with the content to write.

Apply the GitHub settings that have their yes as [github-settings.md](github-settings.md) says.

A contrary-instruction proposal that gets its yes after the report is applied the same way, then reported in one line.

### 6. Report

End on this report. Write each heading, and under it one line per item; write "nothing" under an empty heading.

- **Written**: each file created or changed, with what was added, and each GitHub setting applied.
- **Kept**: each value left as the human set it, and the value this setup would have written.
- **Left to you**:
  - Install the plugins for this project, since the project settings alone do not install `mattpocock-skills` (it lives outside its marketplace): in a terminal at the repo root, `claude plugin marketplace add charlouze/charlouze-skills` if that marketplace is unknown, then `claude plugin install charlouze-skills@charlouze-skills --scope project`, which pulls `mattpocock-skills` as a dependency; or the same through `/plugin` in a session. Then `/reload-plugins`. Each collaborator runs the install once.
  - `gh auth login`, when step 2 found `gh` disconnected or could not check it.
  - `gh extension install github/gh-stack`, when step 2 found the extension missing or could not check it: until then, `/implement-spec` cannot link its stack.
  - When the human answered in this run that the agent has no GitHub identity of its own, offer it one, as an option:
    - what to create: a GitHub App for the agent, and a wrapper that runs a `git` or `gh` command with the App's token and as its author, which the human's instructions make the agent use for every such command;
    - what it brings: the human can approve the pull requests the agent opens, whereas GitHub lets no one approve their own; the points of attention land on their lines; the history tells the agent's commits from the human's;
    - once it exists, set the `Agent identity` line by hand.
  - Each GitHub setting still missing, declined, unapplied for want of rights, or unread: its command written out in full, from [github-settings.md](github-settings.md).
  - Each missing grid step 2 found, by its skill. When the default declaration names it, its skill is one of wondelai's: add the command that installs that skill alone, `npx skills add https://github.com/wondelai/skills --skill <skill>`, written out in full for each missing one. Never point to wondelai's plugins, which bring many skills that are not grids. Any other missing grid is the human's to install, or to drop from `docs/agents/grids.md`. This setup installs nothing.
  - For each competing flow plugin step 2 found: the file that enables it, `/plugin disable <plugin>@<marketplace>`, then `/reload-plugins`.
  - Each contrary instruction still in the instructions file, kept by the human or awaiting its yes: quote it, with its proposal written out again (the removal, or the reworded text), never a pointer to where step 4 showed it.
  - Review, then commit the changed files. This setup never commits.
- **Cloud sessions**: they do not install the plugins a repo declares; there, the flow is complete only through organisation (server-managed) settings.
- **Next**: work as usual with Matt's flow. A context, its functional spec and its `context:<name>` label are created by the change that needs them, never by this setup. Rerun this setup after the plugin changes or after a rerun of `/setup-matt-pocock-skills`.
