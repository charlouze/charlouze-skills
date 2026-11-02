---
name: rework-stack
description: Rework a stack of PRs after a review pass: answer every pending review thread, review body and PR comment, correct each layer by added commits without rewriting history, push the layers one at a time from the bottom up, and request the review again.
argument-hint: "[a PR of the stack]"
disable-model-invocation: true
---

# Rework stack

A **stack** is a sequence of PRs, each based on the one below, reviewed one by one and merged together; each PR is a **layer**, and a single PR is a stack of one layer. The human runs the **rework** once they have finished a review pass. It reads the stack's pending elements on GitHub, triages each one to the layer where its answer belongs, works those layers in parallel, pushes them one at a time from the bottom up, and answers every element. The pushed history stays as it is: the rework adds commits and merges, and pushes without force. The only merge it makes into a layer is its parent's, once this rework has pushed the parent; the trunk stays out of the stack, for the finalization to absorb. The rework leaves every thread unresolved: the human judges the answers and resolves the threads. Feedback given in the terminal is ordinary work, outside the rework.

Read the project's git history policy, `docs/agents/git-history.md`, before starting: every commit of the rework follows its "During the review" rules.

Run `git`, `gh` and the script as your instructions say, through the identity wrapper they give, if any: the script has no identity of its own. Write answers, PR bodies and commit messages in the project's documents language.

## The script

`bash <this skill's directory>/scripts/rework-stack.sh`, whose header gives its commands, outputs and codes. It is the only way the rework reads the stack's exchanges and posts its answers and back-references, since it alone holds the rule of what is pending and the agent's mark.

- `pending <PR>`: the stack, bottom to top, each layer with its past `reviewers` and either the reason it is `skipped` (`approved`, `draft`, `above draft`) or its `pending` elements.
- `reply <element> <body>`: answers an element where it was posted.
- `comment <PR> <body>`: posts a comment of the agent's on a PR.

**The agent's mark.** A message of the agent's is one that starts with `🤖`, whatever identity posts it: the script recognizes the agent's messages by this mark alone, never by their author. It adds the mark to what it posts. Start with it everything else you post on the stack, the points of attention included: an unmarked message of yours reads as the human's, and its thread as pending.

**An element** is what `pending` lists: an unresolved review thread, a review body or a PR comment, whose last message is not the agent's. **A task** is what the triage gives a layer to do for one element. **The main repository** is the checkout the worktrees hang from.

**An answer names its element.** A review body or a PR comment stops being pending only once `reply` has answered it, by a PR comment that opens with its link; any other comment of the agent's, a `comment` included, answers nothing. A rework stopped halfway through its answers thus leaves pending exactly what it had not answered yet.

## Steps

### 1. Prepare the main repository

Read `docs/agents/run.md`: its `## Reserved zones` lists, one glob per line from the repo root, the paths only the main repository touches. When it declares any:

- Note the main repository's branch.
- If it has changes, show its changed files and ask the human: discard them (offer this first), set them aside in a stash named after the stack (`rework-stack #<PR>`), or keep them and take no reserved layer.
- Then, when it has no changes, fast-forward its branch to its upstream (`git merge --ff-only`), and leave it as it is when it cannot be.

Done when `run.md` declares no reserved zone, or the main repository's branch is noted and its changes have the human's answer.

### 2. Read the stack

`git fetch`, then run `pending` from the PR the human names, else the PR of the current branch. Save its output to a file outside the repo; the steps below read it.

- **Code 3**, the stack forks: name the two PRs, ask the human which one belongs to the stack, and stop: `pending` reads only a stack that does not fork.
- **No layer has a pending element**: say so, name the skipped layers, and stop.

Done when you hold `pending`'s output, with at least one element.

### 3. Triage

Launch one fresh subagent, with [triage.md](triage.md) as its brief and the path of `pending`'s output. It returns the **plan**, one line per element: its id, its link, the commented layer, the target layer, the faulty commit if any, and its task in one line. Keep the plan alone: leave the threads and diffs to the subagents.

Check that every element of `pending` appears in the plan exactly once, and that each target layer is the commented layer or one below it.

Then classify each target layer: it is **reserved** when a path of its diff against its base (`git diff --name-only origin/<base>...origin/<head>`), or a path its tasks name, matches a reserved glob.

Done when every element has its line and every target layer its class.

### 4. Work the layers

Track each layer's state from here to the end: **pushed** (with its new head), **failed** (with its reason), **not taken** (with its reason), or **unchanged**.

For each layer with tasks, all at once, launch one fresh subagent with [layer-work.md](layer-work.md) as its brief, and give it: the layer (PR number and URL, head and base branches, whether it is approved), its lines of the plan, the path of `pending`'s output, the reserved globs, whether you have a GitHub identity of your own, and its working place:

- **A layer that is not reserved**: a worktree of its own, outside the main repository's working tree, on a local branch `rework/<head>` made from `origin/<head>`, the layer as it is pushed.
- **A reserved layer**: the main repository, on the same `rework/<head>` branch, one reserved layer at a time, and only while the main repository has no changes. When the human chose to keep its changes, or it has changes by then, the layer is **not taken**.

A subagent that hands back because it must touch a reserved zone has committed its work: remove its worktree, and resume the layer in the main repository on the same branch, as a reserved layer.

Each subagent reports, for each task, its response, its commit if any and the text of its answer; the back-references; the points of attention, decisions to settle and manual checks of its added commits; or its failure and the reason. Keep each subagent at hand: step 5 may resume it, with its context.

Done when every layer with tasks has its subagent's report, or is not taken.

### 5. Push, one layer at a time, bottom up

Settle the layers from the bottom up. A layer's turn comes once the layer below it is settled, and, when it has tasks, once its subagent has reported. Its parent **moved** when it was pushed by this rework.

- **A layer with tasks whose subagent succeeded.** In its working place, when its parent moved, merge it: `git fetch`, then `git merge origin/<parent head>`, a propagation merge. Run the project's tests. On a conflict or a red test, resume the layer's subagent with its context to resolve it, rerun the tests and, after a conflict, the review; these count toward its three attempts. Then `git push origin rework/<head>:<head>`, without force, and check that `git ls-remote origin refs/heads/<head>` gives your local tip. The layer is pushed: remove its worktree (in the main repository, switch back to the branch noted at step 1 instead), then its local branch. A refused push, when the branch moved on GitHub during the rework, makes the layer failed.
- **A layer with tasks whose subagent added no commit**, having only answers to post, is pushed nothing: it settles as a layer without tasks, below.
- **A failed layer.** Its work stays on its local branch `rework/<head>`; remove its worktree, or, in the main repository, switch back to the branch noted at step 1.
- **A layer without tasks whose parent moved**, approved or not: check it locally. In a temporary worktree, on `rework/<head>` made from `origin/<head>`, merge its parent and run the project's tests, pushing nothing. Green: the layer is unchanged; remove the worktree and its branch. Red: the layer gets a task, "make the layer green on its parent", answering no element; work it as in step 4, in that worktree, then take its turn as a layer with tasks.
- **A layer whose parent did not move**, unchanged, failed or not taken, merges nothing; without tasks, it stays unchanged.

A failed layer does not hold back the layers above it.

Done when every layer is pushed, failed, not taken or unchanged.

### 6. Answer

1. Run `pending` again. Each element it gives that the plan lacks arrived during the rework: note it, with its layer and kind.
2. Answer every element of the plan once, by `reply`, from the bottom layer up:
   - a task of a layer whose subagent succeeded, pushed or unchanged: the answer its subagent wrote;
   - a task of a failed layer: "failed, nothing pushed", with the reason and the local branch `rework/<head>`;
   - a task of a layer not taken: "not reworked", with the reason.
3. For each task of a pushed layer whose element sits on another layer, post on the target layer `comment <PR> <back-reference>`: the back-reference its subagent wrote, linking the element and the commit.
4. For each pushed layer, post its **points of attention**: with your own GitHub identity, as one review with the `COMMENT` event at its new head, one comment per point on its line, each opening with the mark and its rank (`🤖 1/4`), most important first; without one, as a section of its PR body, titled in the documents language and naming this rework, in rank order, each point with a permalink to its line at the new head. Add its **decisions to settle** and its **manual checks** to the body's sections that hold them (create them when missing, titled in the documents language), marked as coming from this rework. Keep the rest of the body as it is.
5. For each pushed layer, with your own GitHub identity, request the review again (`gh pr edit <n> --add-reviewer <logins>`) from the authors of the elements its tasks answered and from its past `reviewers`, less the agent and the PR's author. Without one, request nothing: GitHub refuses to request a review from the PR's author, who is then the human.

Done when every element of the plan has its answer's link, every back-reference its link, and every pushed layer its points of attention, body additions and review request.

### 7. Restore the main repository

When step 1 noted its branch, and the main repository has no changes: switch it back to that branch, apply the stash set aside at step 1, if any, and drop the stash once applied. When it has changes, touch nothing.

Done when the main repository is on its noted branch, or left as it is with its changes.

### 8. Recap

End on this recap, in your final message only, with no report comment on GitHub:

- each pushed layer, with its PR;
- the elements by response (correction, new change, answer only, disagreement, question), with their links;
- the questions and disagreements now waiting for the human, with their links;
- the layers that lost their approval;
- the layers checked locally, and those whose check failed;
- each failed layer, with its reason and its local branch; each layer not taken, with its reason;
- the layers skipped as draft or above a draft;
- the elements that arrived during the rework, which wait for the next one;
- when the review was not requested again, why;
- when the main repository was left with changes: its branch, and the stash that holds the changes set aside at step 1, if any.

Done when each item above is given, or "nothing" for an empty one.
