---
name: grid-review
description: Review a diff since a fixed point by the grids the project declares (evaluation skills such as clean-code or domain-driven-design): the Grids axis beside code-review's Standards and Spec. Use with every code-review, or when asked to judge changes by the project's grids.
argument-hint: "[hook point: review] <fixed point, or the diff>"
---

# Grid review

A **grid** is an evaluation skill a project declares at one or more **hook points** (spec, design, review), over a **zone** of its code. This skill applies the grids declared at one hook point to the object judged there. Every failed line of a grid is a remark, to be fixed or justified; a grid's score informs, and no score passes or fails anything.

It takes the hook point and the object judged. This version judges the review hook point, the default, whose object is a diff since a fixed point. Asked to judge a spec or a design, say that only review is supported yet, and stop.

## The declaration

The project declares its grids in `docs/agents/grids.md`. When that file is missing, the declaration is [default-grids.md](default-grids.md). Each `##` section declares one grid, named by its heading:

- **Skill**: the skill that judges, by its short name. `clean-code` names the skill however it is installed: as `clean-code`, or as `<plugin>:clean-code`.
- **Hook points**: those where the grid judges, among `spec`, `design` and `review`.
- **Zone**: `all code`, or paths (globs such as `src/combat/**`) and modules (a package, namespace or assembly, as the code names it), optionally followed by `except` and more of them.
- **Excluded lines**, optional: one item per exclusion, giving the numbers of rows of the grid's diagnostic (the checklist it scores by, numbered from 1), optionally `at <hook point>` when the exclusion holds there only, then its reason. An excluded line is never judged.
- **Focus**, optional: items the grid's subagent applies on top of the grid, each one at every hook point, or only at the one its `At <hook point>:` prefix names.

## Steps

### 1. Pin the diff

Take the fixed point (commit, branch, tag or merge-base) the caller names, and the diff `git diff <fixed-point>...HEAD` with its changed files (`--name-only`). When the caller already holds the diff, such as the diff command `code-review` captured or a patch file, take it as given. With neither, ask for the fixed point.

Done when you hold the diff and the list of its changed files.

### 2. Sort the grids

Read the declaration and keep each grid whose hook points include `review`. Sort every grid kept into exactly one of:

- **Out of zone**: no changed file falls in its zone.
- **Missing**: its skill is absent from your available skills, under its short name and under any `<plugin>:` prefix.
- **Active**: otherwise. Note its skill name as listed, and the changed files in its zone.

Done when every grid kept has its sort.

### 3. Launch the grids

Launch one subagent per active grid, every call in one message so that they run in parallel. Each prompt holds:

- the diff: its command or the patch file, and the changed files in the grid's zone, the only ones to judge;
- "Invoke the Skill tool with `<skill as listed>`, then judge these changes by its diagnostic.";
- the grid's lines excluded at review, by number: "Leave lines <numbers> out: judge, mention and score the other lines only.";
- the grid's focus items that hold at review, word for word;
- the brief: "Report in about 250 words: first the score the grid gives, on its own scale; then each failed line, by its number and question, with where the diff fails it (file and line) and either its fix or the reason to keep the code as it is. Leave passing lines out."

Done when every subagent has returned.

### 4. Report

Under `## Grids`, one `### <grid>` part per grid kept at step 2, in the declaration's order:

- **Active**: `### <grid> (<skill>): <score>`, then its failed lines, each with its fix or its reason, as the subagent returned them, lightly cleaned. The part speaks of judged lines only, with no note on how the score was reached: the declaration already records each excluded line and its reason, so the report never names one, not even to say it was left out.
- **Out of zone**: "not launched: its zone touches no changed file."
- **Missing**: "grid `<skill>` missing: install it, or drop it from the project's declaration."

End with one line: the count of failed lines per grid. Each grid stands on its own: rank nothing across grids.

Next to `code-review`, this report is the Grids axis: its own section beside `## Standards` and `## Spec`.
