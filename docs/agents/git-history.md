# Git history

How the agent shapes the git history of its pull requests, so that `main` tells the change, not its development. A **stack** is a sequence of pull requests, each one a **layer** based on the one below it, reviewed one by one and merged together; a single pull request is a stack of one layer, under the same rules.

## Before the first push

Tidy the commits of the layer freely: reorder, split, squash, reword, fold a fix into the commit it fixes. A layer keeps one commit per distinct change, each with its own message, and no commit fixes another commit of the same layer.

The first push of a layer freezes its history: from then on, it is under review.

## During the review

- **Never rewrite a pushed layer**: no `rebase`, no `commit --amend`, no `push --force`. The reviewer then reviews only the commits added since their last pass.
- **A correction** of what a commit of the stack already does becomes a `fixup! <subject of that commit>`, or an `amend! <subject of that commit>` that also corrects its message. **A new change** becomes an ordinary commit. In your answer, to the review comment or to the human, say which of the two you chose.
- **A `fixup!` or `amend!` targets a commit of its own layer only**: the finalization folds the corrections layer by layer.
- **Propagate a correction up the stack** by a **propagation merge**, `git merge <parent branch>` and an ordinary push, but only in a layer that pushes anyway, because it has corrections of its own. An approved layer with nothing to change is only checked locally, by merging its parent without pushing: since the repository dismisses stale approvals, pushing the merge would cost the layer its approval.
- **Merge `main` into the stack only on a conflict**, by a merge into the bottom layer, reviewed like any other commit. Otherwise the finalization's rebase absorbs whatever `main` gained.
- **A misplaced fix moves during the review**, through visible commits (revert it in one layer, redo it in the right one), never during the finalization.

## Finalization

Only once the whole stack is approved, and only when the human asks for it, the **finalization** folds each correction into the commit it targets, drops the stack's merges while replaying the conflict resolutions they carry, and rebases onto the current `main`, without changing the diff of any layer: at the slightest difference, or at a conflict that no merge of the stack resolves, it gives up and pushes nothing. The human then merges the stack as a merge commit, titled by its top pull request: on `main`, `git log --first-parent` shows one line per stack.
