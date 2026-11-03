---
name: finalize-stack
description: Finalize an approved stack of PRs before the human merges it: fold each fixup into the commit it targets without changing any layer's diff, rebase on the current trunk, retitle the top PR and check the closing links.
argument-hint: "[a PR of the stack]"
disable-model-invocation: true
---

# Finalize stack

A **stack** is a sequence of PRs, each based on the one below, reviewed one by one and merged together; each PR is a **layer**. During review nothing was rewritten: corrections went in as `fixup!` or `amend!` commits and spread up by merges, as the project's git history policy says (`docs/agents/git-history.md`, which the `Git history` line of `CLAUDE.md` points at). **Finalization**, once every layer is approved, folds each correction into the commit it targets and never changes a layer's diff: GitHub keeps an approval when the diff is unchanged. It stops at the hand-back: the human merges.

Run `git`, `gh` and the scripts as your instructions say, through the identity wrapper they give, if any: the scripts have no identity of their own, and act under that of whatever runs them. Write titles and bodies in the project's documents language.

## Steps

### 1. Read the stack

Read the stack from the PR the human names, else the PR of the current branch:

```
bash <this skill's directory>/../../scripts/stack.sh <PR>
```

This script, shared with the rework and kept at the plugin's root, alone reads the stack on GitHub: its shape and each layer's approval. Its header gives its output and codes. It asks for bash 4.4 or newer and jq.

- **Code 3**, the stack forks: two open PRs on one base. Name the two PRs, ask the human to close or retarget the one that does not belong to the stack, and stop: the script reads only a stack that does not fork.
- **Any other failure**: give the human its error as it is, and stop.

Done when you hold the trunk and every layer, bottom to top, with its title, head and base branches, `draft` and `approval`.

### 2. Check the approvals

A layer passes when its `approval` is `approved` and it is not a `draft`. A draft layer, such as the one a stopped ticket leaves on top, fails whatever its approval: the human either removes it from the stack, or has it finished and approves it.

When a layer fails, stop before anything else, and name each one that fails: PR number, branch, and what it lacks: it is a draft, changes are requested, or it has no approval.

Done when every layer passes. The **top** is the highest layer.

### 3. Run the script

From the repo, on any branch:

```
bash <this skill's directory>/scripts/finalize-stack.sh <trunk> <bottom branch> … <top branch>
```

It reads the stack on `origin` and leaves the working tree and the local branches as they were. It pushes every layer at once, rebased on the current trunk, only when no layer's diff has changed; otherwise it pushes nothing. Its last line is `pushed` or `aborted: <layer>: <reason>`, one of the forms its header lists. On an abandon, stop, and give the human the line with the remedy its reason calls for. Each remedy is a review step under the git history policy: commits added to the stack, never a rewrite.

- **`rebase conflict (<files>)`**: the trunk, or the layer below, conflicts with this layer. Merge the trunk into the bottom layer, then each layer into the one above it up to this one, resolving each conflict in the merge where it arises; have the merges reviewed like the rest. The script replays those resolutions. Then finalize again.
- **`diff changed`**: dropping a merge, or folding a correction, changes this layer's diff. Either a merge carries a change of its own, or a correction to the layer below was never merged into this one and touches the same lines. Move the change by visible commits, or merge the layer below into this one, have it reviewed, then finalize again.
- **`correction outside its layer: "<subject>"`**: a `fixup!` or `amend!` aims at a commit of another layer. Turn it into an ordinary commit or move it to its layer, by visible commits, then finalize again.
- **`push refused`**: a branch moved since the script read it, or the remote refused the push. Finalize again once the stack is still.
- **Any other reason**: a fault of the stack or of the machine. Give the line as it is.

Done when the script says `pushed`.

### 4. Check the closing links

```
bash <this skill's directory>/scripts/closing-links.sh <bottom PR> … <top PR>
```

Each layer closes the ticket its body names (`Closes #<ticket>`); the script writes again the body of a layer whose keyword GitHub has not read. The **change spec** is the parent of the layers' tickets: when every one of its sub-issues is closed already or closed by a layer, the script adds `Closes #<change spec>` to the top PR's body. It prints one line per PR, one for the change spec, then `linked` or `unlinked: #<PR> …`.

- **`#<PR>: no ticket`**: ask the human which ticket the layer closes, write `Closes #<ticket>` at the end of its body, then run the script again.
- **`#<PR>: unlinked from …`**: GitHub still does not read the keyword. Give the human the line.
- **`change spec #<n>: waits for …`**: the change spec stays open; note the tickets it waits for.

Done when the script says `linked`.

### 5. Retitle the top

When the finalized stack has two layers or more, retitle the top PR (`gh pr edit <top PR> --title`) with a title that sums up the whole stack, drawn from the layers' titles that step 1 gave, in the style of the repo's commit subjects: merged as a merge commit titled by the top PR, the stack becomes one line of the trunk's `--first-parent` history. A single PR keeps its title. The title is the only trace: the stack gets no closing PR, nor any empty commit.

Done when the top PR bears its title.

### 6. Hand back

Report to the human:

- each finalized layer: PR, the ticket that `closing-links.sh` gave for it, number of commits, and the script's verdict;
- the top's new title, the PRs whose body you edited, and whether the change spec closes with the stack or which tickets it waits for;
- the local branches of the stack still point at their old commits: `git fetch`, then reset or delete them;
- the merge command, for the human to run, always as a merge commit: `gh stack merge <top PR> --merge` when the stack has two layers or more, `gh pr merge <PR> --merge` for a single PR, which `gh stack` does not know as a stack.
