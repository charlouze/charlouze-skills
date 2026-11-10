---
name: grid-review
description: Judge by the grids the project declares (evaluation skills such as clean-code or domain-driven-design) a draft change spec, whole at the spec hook point and by its Implementation Decisions at the design one, an adoption draft, whole at the spec hook point only, or a diff since a fixed point, where it is the Grids axis beside code-review's Standards and Spec. Use with every code-review, or when asked to judge a draft or changes by the project's grids.
argument-hint: "[hook point: spec | design | review] <draft change spec, adoption draft, fixed point, or the diff>"
---

# Grid review

A **grid** is an evaluation skill a project declares at one or more **hook points** (spec, design, review), over a **zone** of its code. This skill applies the grids declared at one hook point to the object judged there. Every failed line of a grid is a remark, to be fixed or justified; a grid's score informs, and no score passes or fails anything.

It takes the hook point and the **object** judged there:

- **spec**: a draft change spec, or an **adoption draft**, judged whole;
- **design**: a draft change spec, judged on its `Implementation Decisions`, where its design lives; the rest of the draft is context;
- **review**: a diff since a fixed point.

An **adoption draft** is what adopting one or more contexts writes before its pull request: each adopted context's functional spec, its glossary, and its lines of the context map, judged together as one object. A **draft** is either kind: a draft change spec or an adoption draft. An adoption draft is judged at spec only: it has no `Implementation Decisions` for design, and review's grids judge code. When the caller names design or review for an adoption draft, say so and judge nothing.

When the caller names no hook point, a diff is judged at review, an adoption draft at spec, and a draft change spec at spec, then at design, each with its own report.

## The declaration

The project declares its grids in `docs/agents/grids.md`. When that file is missing, the declaration is [default-grids.md](default-grids.md). Each `##` section declares one grid, named by its heading:

- **Skill**: the skill that judges, by its short name. `clean-code` names the skill however it is installed: as `clean-code`, or as `<plugin>:clean-code`.
- **Hook points**: those where the grid judges, among `spec`, `design` and `review`.
- **Zone**: `all code`, or paths (globs such as `src/combat/**`) and modules (a package, namespace or assembly, as the code names it), optionally followed by `except` and more of them.
- **Excluded lines**, optional: one item per exclusion, giving the numbers of rows of the grid's diagnostic (the checklist it scores by, numbered from 1), optionally `at <hook point>` when the exclusion holds there only, then its reason. An excluded line is never judged.
- **Condition**, optional: items each saying what the object must do for the grid to be launched.
- **Focus**, optional: items the grid's subagent applies on top of the grid.

A Condition or Focus item holds at every hook point, or only at the one its `At <hook point>:` prefix names.

## Steps

### 1. Pin the object

- **A draft change spec**, at spec or design: take the file the caller names, or the text it hands over. The code the draft touches is the code it names: files, paths and modules.
- **An adoption draft**, at spec: take the files the caller names, or the text it hands over. Of the context map, judge the adopted contexts' lines; the rest of the map is context. The code the draft touches is the code of the contexts it adopts: the paths and modules the caller or the draft names.
- **A diff**, at review: take the fixed point (commit, branch, tag or merge-base) the caller names, and the diff `git diff <fixed-point>...HEAD` with its changed files (`--name-only`). When the caller already holds the diff, such as the diff command `code-review` captured or a patch file, take it as given. With neither, ask for the fixed point. The code the diff touches is its changed files.

Done when you hold the object and the code it touches.

### 2. Sort the grids

Read the declaration and keep each grid whose hook points include this one. Sort every grid kept into the first of these that fits:

- **Out of zone**: no code the object touches falls in its zone. A draft that names no code falls in every zone.
- **Condition unmet**: one of its conditions that hold at this hook point is not met by the object. An adoption draft counts as creating each context it adopts, and as touching its glossary and the context map: hold each condition against that.
- **Missing**: its skill is absent from your available skills, under its short name and under any `<plugin>:` prefix.
- **Active**: otherwise. Note its skill name as listed, and the code the object touches in its zone.

Done when every grid kept has its sort.

### 3. Launch the grids

Launch one subagent per active grid, every call in one message so that they run in parallel, each with the model and effort that the `Models` line of the project's `## charlouze-skills` block gives the `Grid review` role. Each prompt holds:

- the object:
  - a diff: its command or patch file, and the changed files in the grid's zone, the only ones to judge;
  - a draft change spec: its path, or its text, with at design "Judge its `Implementation Decisions` only: the rest of the draft is context.";
  - an adoption draft: its files' paths, or its text, with "Judge these files together, as one draft: each adopted context's functional spec, its glossary, and its lines of the context map, the rest of the map being context.";
- "Invoke the Skill tool with `<skill as listed>`, then judge this <object> by its diagnostic.";
- the grid's lines excluded at this hook point, by number: "Leave lines <numbers> out: judge, mention and score the other lines only.";
- the grid's focus items that hold at this hook point, word for word;
- the brief: "Report in about 250 words: first the score the grid gives, on its own scale; then each failed line, by its number and question, and each focus check that fails, with where the object fails it (the diff's file and line, or the draft's section or block) and either its fix or the reason to keep it as it is. Leave passing lines out."

Done when every subagent has returned.

### 4. Report

Under `## Grids` (`## Grids at <hook point>` for a draft), one `### <grid>` part per grid kept at step 2, in the declaration's order:

- **Active**: `### <grid> (<skill>): <score>`, then its failed lines and focus checks, each with its fix or its reason, as the subagent returned them, lightly cleaned. The part speaks of judged lines only, with no note on how the score was reached: the declaration already records each excluded line and its reason, so the report never names one, not even to say it was left out.
- **Out of zone**: "not launched: its zone touches no code of the <object>."
- **Condition unmet**: "not launched: the <object> does not meet its condition, <the condition>."
- **Missing**: "grid `<skill>` missing: install it, or drop it from the project's declaration."

End with one line: the count of failed lines per grid. Each grid stands on its own: rank nothing across grids. Then add the line the `Models` line asks for when the models file has unreadable lines.

Next to `code-review`, this report is the Grids axis: its own section beside `## Standards` and `## Spec`.
