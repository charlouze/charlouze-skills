## Agent skills

### Issue tracker

Issues are tracked in this repo's GitHub Issues, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Multi-context: `GLOSSARY-MAP.md` at the repo root from the first context, each context's `SPEC.md` and `GLOSSARY.md` in `docs/contexts/<context>/`, one `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## charlouze-skills

Language of produced documents: French

Grids: declared in `docs/agents/grids.md`, applied by `grid-review`.

Code review: whenever you run `code-review`, whoever asked for it (the human, `/implement`, `/implement-spec`), also call the Skill tool with `grid-review` on the same fixed point, and report its `## Grids` section beside `## Standards` and `## Spec`.

Git history: tidy your commits freely until a branch's first push; after it, rewrite nothing (no `rebase`, `commit --amend` or `push --force`) until the whole stack is approved, and correct with `fixup!` or `amend!` commits, propagated by merge. Follow `docs/agents/git-history.md`.

### Stacked delivery with `implement-spec`

When you run `/implement-spec`, deliver the change spec as one stack of pull requests, one layer per ticket, instead of its integration branch. This replaces its steps 3, 4, 5, 7 and 8. The rest holds: the task graph, the frontier, implementer subagents in parallel in their own worktrees, `tdd`.

- **Launch.** One change spec per run. Its tickets are its open tickets labelled with the `ready-for-agent` role's label, or those the human names. Do not assign a ticket when it starts.
- **One stack.** One native stack per change spec: no integration branch, no merger subagent, no pull request for the whole change spec. Of `gh stack`, use `link` only, never `submit`, `sync`, `rebase` or `merge`. Create branches and push with `git`.
- **Start.** A ticket starts once all its blockers are pushed, in its own worktree, on a branch from the top of the stack (`main` for the first layer).
- **Layer cycle.** Each implementer subagent runs its layer's whole cycle:
  1. build the ticket with `tdd`;
  2. review the layer alone, its diff against the layer below, with `code-review`, to which the `Code review` line joins `grid-review`;
  3. fix in the layer what the review raises, then tidy its commits as the git history policy says before the first push. Then wait for this layer's turn to push;
  4. rebase onto the current top of the stack: nothing of the layer is pushed yet, so `Git history` allows it. Rerun the tests, and `code-review` too when the rebase had conflicts;
  5. push, check with `git ls-remote` that the remote branch points at your local tip, then open a ready-for-review pull request whose base is the layer below (`main` for the first);
  6. from the second layer on, link the stack with `gh stack link`, giving the pull request numbers from bottom to top so that it pushes nothing.
- **One push at a time.** Layers are pushed one at a time, in the order their tickets reach the end of step 3, which never puts a layer below one of its blockers. A pushed layer is never rewritten (`Git history`).
- **A single ticket** gives an ordinary pull request to `main`: the stack is born with the second layer.
- **Stopping a ticket.** Stop a ticket in four cases only:
  1. a block of the change spec cannot be transcribed as it stands, or the code shows that the change spec is wrong;
  2. an ADR or a constraint of the change spec cannot be held;
  3. the tests still fail after three attempts at fixing them;
  4. a human action is needed: an access, an account, a secret.

  Comment on the stopped ticket with the question and what was tried, and swap its `ready-for-agent` role's label, if it has one, for the `needs-info` role's. Its descendants wait; the other tickets go on.
- **Draft layer.** A stopped ticket's partial work comes last. It waits until every other ticket the run starts is pushed or stopped, tidies its commits, then runs steps 4 to 6 of the layer cycle, opening a draft pull request without `Closes`; its review waits for the relaunch. Several stopped tickets give as many draft layers, one above the other. Only a draft layer stacks above a draft layer, so merging the stack stops below the lowest one.
- **Relaunch.** On a change spec whose stack is still open, first finish each draft layer, from the bottom up, whatever its ticket's label. The layer is pushed, so it changes by added commits only (`Git history`):
  1. when the layers below it have moved, merge its parent into it: `main` once the human has merged them, since the finalization rewrote them, or the lower draft layer once that one has gained commits;
  2. run steps 1 to 3 of the layer cycle, without tidying;
  3. push, check with `git ls-remote` that the remote branch points at your local tip, mark its pull request ready for review, and add `Closes #<ticket>` to its body.

  The following tickets then stack on top. When the whole stack has been merged, start a new stack from `main`.
- **Pull request body.** The template of `pr`, plus `Closes #<ticket>`, except in a draft layer: from the start in the first layer, and in the others only once `gh stack link` has run, since GitHub ignores closing keywords in a pull request based on another branch than `main` outside a stack.
- **Report.** End the run with one comment on the change spec, giving:
  - the stack, by the link `gh stack link` prints (a single ticket's pull request, by its own link), and each layer: its ticket's title and its pull request's link.
  - the stopped tickets: each one's question and its draft layer's link.

  Your final message points at that comment.

## Slicing with `to-tickets`

When running `/to-tickets` on a change spec, keep the skill's issue template and add the following.

- The change spec's `Spec delta` holds the blocks (`D1`, `D2`…): the exact text to write in a context's functional spec, glossary or the context map. Each ticket names, in *What to build*, the blocks it transcribes ("Transcribes D2 and D5"). Each block goes to exactly one ticket. A block number is not a file path: name it. Show each ticket's blocks in the breakdown you present.
- A ticket merged alone after its blockers must not leave any user facing a half-delivered behaviour, and every user story of the change spec is delivered by at least one ticket. If this cannot hold without a flag the change spec does not declare, say so and stop: the change spec must be revised first.
- The ticket that transcribes the blocks creating a context's spec comes first in that context. If the change spec declares a flag, the first gated ticket transcribes the block that adds the gating sentence, and the lift ticket is blocked by every gated ticket.
- When publishing, create the label `context:<context>` for each context the change spec touches, if it is missing. For each context the change spec marks as existing but not adopted, also open an issue `Adopter <context>` with the labels `needs-triage` and `context:<context>`, saying that its functional spec only describes what this change touches. A new context gets none.
