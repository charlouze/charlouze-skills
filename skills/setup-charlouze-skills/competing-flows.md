# Competing flows

**The flow** is Matt's skills, completed by this plugin. Matt's skills own the steps of the work: grilling, the spec (`/to-spec`), the tickets (`/to-tickets`), the implementation (`/implement`, `/tdd`), the review (`/code-review`), the PR (`/pr`), triage and the domain docs. This plugin's block and the files of `docs/agents/` complete those skills. A **competing flow** owns some of the same steps through its own skills: `superpowers` (brainstorming, plans, subagent-driven development, finishing a branch), `supercharlouze`, which overrides superpowers, or any other workflow plugin. The model follows one flow reliably, never two, and an instruction of the instructions file outweighs the flow skill it opposes, taking the model out of the flow: one flow is the aim of both checks below.

## Contrary instructions

Plan a proposal for each contrary instruction of the instructions file. Read the whole file except the `## Agent skills` and `## charlouze-skills` blocks, which are the flow's own.

An instruction is **contrary** when following it leaves the flow:

- it hands a step of the flow to a competing flow's skill or process: invoke `superpowers:brainstorming` before design, save plans under `docs/plans/`, run `supercharlouze:using-batches`;
- it orders the opposite of a flow skill, of Matt's block, or of this plugin's block: another tracker, specs or glossaries kept elsewhere than the domain docs say, another documents language.

A project convention that no flow skill speaks to (a test command, code style, time zones, naming) stays, however strict. So does an instruction that adds to a flow skill without opposing it: completing a skill is how this plugin works.

Each proposal is one of:

- **Removal**, when the whole instruction serves the competing flow. Another flow plugin's block goes whole: its section, with the markers that delimit it (`<!-- supercharlouze:begin -->` to `<!-- supercharlouze:end -->`).
- **Rewording**, when the instruction also carries an intent of the project: keep the intent and route it to the flow, e.g. "following `superpowers:test-driven-development`" becomes "following `/tdd`".

Show each proposal in step 4 with the instruction quoted, the flow skill or rule it contradicts, and the diff. The human may keep any instruction as it is.

## Competing flow plugins

Read `enabledPlugins` in each settings file the session can read: the project's `.claude/settings.json` and `.claude/settings.local.json`, and the user's `~/.claude/settings.json`. A plugin is enabled when the most specific file naming it (local, then project, then user) sets it to `true`.

Each enabled plugin of a competing flow is a signal: `superpowers`, `supercharlouze`, or another plugin you know to run its own workflow. `mattpocock-skills` and `charlouze-skills` are the flow. Note, for each one, its full name `<plugin>@<marketplace>` and the file that enables it: the report turns them into the command the human types. Disabling a plugin is the human's act: plan no change to `enabledPlugins` for it.
