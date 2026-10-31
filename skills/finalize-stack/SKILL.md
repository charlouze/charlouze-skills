---
name: finalize-stack
description: Finalize an approved stack of PRs before the human merges it: fold each fixup into the commit it targets without changing any layer's diff, rebase on the current trunk, retitle the top PR and check the closing links.
argument-hint: "[a PR of the stack]"
disable-model-invocation: true
---

# Finalize stack

A **stack** is a sequence of PRs, each based on the one below, reviewed one by one and merged together; each PR is a **layer**. During review nothing was rewritten: corrections went in as `fixup!` or `amend!` commits and spread up by merges, as the project's git history policy says (`docs/agents/git-history.md`, which the `Git history` line of `CLAUDE.md` points at). **Finalization**, once every layer is approved, folds each correction into the commit it targets and never changes a layer's diff: GitHub keeps an approval when the diff is unchanged. It stops at the hand-back: the human merges.

Run `git`, `gh` and the script as the project's instructions say, through its identity wrapper when it declares one. Write titles and bodies in the project's documents language.

## Steps

### 1. Read the stack

Start from the PR the human names, else the PR of the current branch. Walk down through each PR's base branch to the trunk, the base of the bottom layer, then up through the open PRs based on each head branch (`gh pr list --base <branch> --state open`). For each layer, read `gh pr view <n> --json number,title,body,isDraft,baseRefName,headRefName,reviewDecision,latestReviews,closingIssuesReferences`.

Two open PRs on one base mean the stack forks: stop and ask the human which one belongs to it.

Done when you hold every layer, bottom to top, and the trunk.

### 2. Check the approvals

A draft layer on top, left by a stopped ticket, is neither approved nor finalized: set it aside. Finalization covers the layers below it, and the **top** is the highest of them. The human merges up to that top; the draft layer is picked up again later.

Every other layer is approved: its `reviewDecision` is `APPROVED`, or, when the repo requires no review and `reviewDecision` is empty, its `latestReviews` hold an approval and no change request. A draft anywhere but on top fails too.

When a layer fails, stop before anything else, and name each one that fails: PR number, branch, and what it lacks.

Done when every layer below the draft one, if any, is approved.

### 3. Run the script

From the repo, on any branch:

```
bash <this skill's directory>/scripts/finalize-stack.sh <trunk> <bottom branch> … <top branch>
```

It reads the stack on `origin` and leaves the working tree and the local branches as they were. It pushes every layer at once, rebased on the current trunk, only when no layer's diff has changed; otherwise it pushes nothing. Its last line, in French, is `poussé` or `abandonné : <layer> : <reason>`, one of the forms its header lists. On an abandon, stop, and give the human the line with the remedy its reason calls for. Each remedy is a review step under the git history policy: commits added to the stack, never a rewrite.

- **`conflit au rebase (<files>)`**: the trunk, or the layer below, conflicts with this layer. Merge the trunk into the bottom layer, then each layer into the one above it up to this one, resolving each conflict in the merge where it arises; have the merges reviewed like the rest. The script replays those resolutions. Then finalize again.
- **`diff changé`**: dropping a merge, or folding a correction, changes this layer's diff. Either a merge carries a change of its own, or a correction to the layer below was never merged into this one and touches the same lines. Move the change by visible commits, or merge the layer below into this one, have it reviewed, then finalize again.
- **`correction hors de sa couche : « <subject> »`**: a `fixup!` or `amend!` aims at a commit of another layer. Turn it into an ordinary commit or move it to its layer, by visible commits, then finalize again.
- **`push refusé`**: a branch moved since the script read it, or the remote refused the push. Finalize again once the stack is still.
- **Any other reason**: a fault of the stack or of the machine. Give the line as it is.

Done when the script says `poussé`.

### 4. Check the closing links

Each finalized layer closes its ticket: its `closingIssuesReferences` holds it. A layer whose body names its ticket (`Closes #<ticket>`) without the link was written before the stack was linked, when GitHub ignored the keyword: edit its body to remove that line, then edit it again to put the line back, and read the links again. A layer whose body names no ticket: ask the human which one it closes, then write the line. The draft layer closes nothing.

The **change spec** is the parent of the layers' tickets (the `parent` of an issue in the GraphQL API, or the ticket's `## Parent` section); its tickets are its sub-issues (`gh api repos/{owner}/{repo}/issues/<change spec>/sub_issues`). When every one of them is closed already or closed by a finalized layer, add `Closes #<change spec>` to the top PR's body. Otherwise the change spec stays open: note the tickets it still waits for.

Done when every finalized layer's `closingIssuesReferences` holds its ticket, and the top's holds the change spec whenever the stack completes it.

### 5. Retitle the top

When the finalized stack has two layers or more, retitle the top PR with a title that sums up the whole stack, in the style of the repo's commit subjects: merged as a merge commit titled by the top PR, the stack becomes one line of the trunk's `--first-parent` history. A single PR keeps its title. The title is the only trace: the stack gets no closing PR, nor any empty commit.

Done when the top PR bears its title.

### 6. Hand back

Report to the human:

- each finalized layer: PR, ticket, number of commits, and the script's verdict;
- the top's new title, the PRs whose body you edited, and whether the change spec closes with the stack or which tickets it waits for;
- the draft layer set aside, if any;
- the local branches of the stack still point at their old commits: `git fetch`, then reset or delete them;
- the merge command, for the human to run: `gh stack merge <top PR> --merge`.
