# Layer work

You rework one layer of a stack of PRs: you carry out its tasks, each answering one review element, and report back. A **stack** is a sequence of PRs, each based on the one below; each PR is a **layer**. The layer is pushed and under review: you add commits on top of its pushed head, and its pushed history stays as it is. You push nothing and post nothing on GitHub: the session that launched you does both, once the layers below are settled.

Read the project's git history policy, `docs/agents/git-history.md`, before your first commit. Run `git` and `gh` as your instructions say, through the identity wrapper they give, if any. Write commit messages and the texts you report in the project's documents language.

## Input

- The layer: its PR number and URL, its head and base branches, and whether it is approved.
- Its tasks, one line each from the plan: the element's id and link, the commented layer, the target layer (this one), the faulty commit if any, and the task.
- The path of `rework-stack.sh pending`'s output, where each element's messages are found by its id.
- The reserved globs: paths that only the main repository touches.
- Whether the agent has a GitHub identity of its own.
- Your working place: a worktree, or the main repository, on the local branch `rework/<head>`, made from `origin/<head>`.

## For each task, one response

- **Correction**: what a commit of this layer already does is wrong. A `fixup! <subject of that commit>`, or an `amend! <subject of that commit>` that also corrects its message, aimed at a commit of this layer only.
- **New change**: an ordinary commit.
- **Answer only**: the element was a question; answer it, touching no code.
- **Disagreement**: you hold your own view. When the element does not convince you, explain why and touch nothing; the human settles it.
- **Question**: the element is ambiguous; ask what it means before touching any code.

A correction the layer already holds, pushed by an earlier rework that never answered, gets its answer with that commit.

**Intent.** When an element contradicts the text of a functional spec, a glossary or a context map that this layer transcribes, change that text in this layer, along with the code. When it contradicts what another layer transcribes, the change spec (the parent issue of the ticket this layer's PR closes), or an ADR, the response is a question that names what would be touched.

A correction that changes a behaviour goes through `tdd`; any other change is covered by the project's tests.

**Reserved zone.** In a worktree, when a task needs to touch a path that matches a reserved glob, commit your work and hand back before touching it, saying which path: the layer resumes in the main repository.

Done when every task has its response, and its commit when it has one.

## Check the added commits

Tidy the commits you added among themselves as you like: none of them is pushed yet. Then run the project's tests, then `code-review` with the layer's pushed head (`origin/<head>`) as its fixed point, then `grid-review` on the same fixed point: both judge your added commits alone. Correct or justify each remark.

When the tests are still red after three attempts at fixing them, stop: commit what you have on `rework/<head>`, and report the failure and its reason.

Merge into the layer nothing but what the session asks: its parent, once pushed. When the session resumes you after that merge, resolve the conflict or the red test, rerun the tests, and, after a conflict, `code-review` and `grid-review` on the commits added since the pushed head; then report again.

Done when the tests are green and every remark of both reviews is corrected or justified, or the failure is reported.

## Report

- **Each task**: the element's id, its response, its commit's sha if any, and the **answer** to post, which says:
  - which of the five responses it is;
  - for a commit, its link within this layer's PR, `<PR URL>/commits/<sha>`, naming the PR when the element sits on another layer;
  - for a correction, that it is a `fixup!` or an `amend!`, folded into its commit at the finalization; for a new change, that it is an ordinary commit, kept in the history;
  - when this layer was approved and gets a commit, that it loses its approval.
- **Each back-reference**: for each task whose element sits on another layer, a short text for this layer's PR that links the element and the commit.
- **The points of attention** of your added commits. A point of attention is a place in the diff where the reviewer, reading it alone, could miss something or disagree: a non-obvious choice, a fragile spot, a departure from the change spec's design, an assumption made for want of information. A routine decision, or what the tests prove, is none. Give each its file and its line at your tip, ranked from the most to the least important, without a cap.
- **The decisions to settle**: each decision you took without the human, which you submit to them, with its reason and what it costs if it is wrong. Approving the PR settles it. A decision that meets the criteria of an ADR (`domain-modeling`) comes with an ADR proposal. A decision that is neither a point of attention nor to settle goes in its commit message alone.
- **The manual checks**: what the human checks by hand, what neither the tests nor the reviews prove.
- Or **the failure**: its reason, and the last commit on `rework/<head>`.
