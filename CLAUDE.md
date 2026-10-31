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

Run: reserved zones declared in `docs/agents/run.md`, applied by ``Stacked delivery with `implement-spec` ``.

Agent identity: the human is `charlouze`; the agent is `charlouze-dev-agent`.

### Stacked delivery with `implement-spec`

When you run `/implement-spec`, deliver the change spec as one stack of pull requests, one layer per ticket, instead of its integration branch. This replaces its steps 3, 4, 5, 7 and 8. The rest holds: the task graph, the frontier, implementer subagents in parallel in their own worktrees, `tdd`.

- **Launch.** One change spec per run. Its tickets are its open tickets labelled with the `ready-for-agent` role's label, or those the human names. Do not assign a ticket when it starts.
- **One stack.** One native stack per change spec: no integration branch, no merger subagent, no pull request for the whole change spec. Of `gh stack`, use `link` only, never `submit`, `sync`, `rebase` or `merge`. Create branches and push with `git`.
- **Reserved tickets.** A ticket is reserved when it touches a reserved zone, a path that only the main repository touches, the checkout the worktrees hang from. `docs/agents/run.md` declares the zones as globs. At launch, classify each ticket by matching against them the paths where the modules the change spec assigns it live in the code. A reserved ticket's implementer leaves the main repository with no changes when it hands back, pushed or stopped: its work is committed on its branch. A reserved ticket's draft layer is finished in the main repository too.
- **Main repository at launch.** When `docs/agents/run.md` declares a reserved zone, note the main repository's branch. If it has changes, show its changed files and ask the human what to do with them: discard them (offer this first), set them aside in a stash named after the change spec, or keep them and take no reserved ticket.
- **Start.** A ticket starts once all its blockers are pushed, in its own worktree, on a branch from the top of the stack (`main` for the first layer). A reserved ticket starts in the main repository instead, one at a time, and only when the main repository has no changes: during the run, never touch a main repository with changes, and the reserved tickets are then not taken, nor their descendants.
- **A reserved zone found late.** An implementer in a worktree that finds it must touch a reserved zone hands back before touching it, with its work committed. Its ticket becomes reserved and resumes in the main repository on the same branch, once its worktree is removed: the ticket goes on, since this is none of the cases of `Stopping a ticket`.
- **Layer cycle.** Each implementer subagent runs its layer's whole cycle:
  1. build the ticket with `tdd`;
  2. review the layer alone, its diff against the layer below, with `code-review`, to which the `Code review` line joins `grid-review`;
  3. fix in the layer what the review raises, then tidy its commits as the git history policy says before the first push. Then wait for this layer's turn to push;
  4. rebase onto the current top of the stack: nothing of the layer is pushed yet, so `Git history` allows it. Rerun the tests, and `code-review` too when the rebase had conflicts;
  5. push, check with `git ls-remote` that the remote branch points at your local tip, then open a ready-for-review pull request whose base is the layer below (`main` for the first), and give it its points of attention;
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
  3. push, check with `git ls-remote` that the remote branch points at your local tip, mark its pull request ready for review, give it the points of attention of the added commits, complete its *To settle* and *Manual checks*, and add `Closes #<ticket>` to its body.

  The following tickets then stack on top. When the whole stack has been merged, start a new stack from `main`.
- **Pull request body.** The template of `pr`, plus a *To settle* section and a *Manual checks* section, each titled in the documents language. *Manual checks* lists what the human checks by hand: what neither the tests nor the review prove. The body ends with `Closes #<ticket>`, except in a draft layer: from the start in the first layer, and in the others only once `gh stack link` has run, since GitHub ignores closing keywords in a pull request based on another branch than `main` outside a stack.
- **Points of attention.** A point of attention is a place in the diff where the reviewer, reading it alone, could miss something or disagree: a non-obvious choice, a fragile spot, a departure from the change spec's design, an assumption made for want of information. A routine decision, or what the tests prove, is none. Rank them from the most to the least important, without a cap.
  - When the `Agent identity` line names the agent and your instructions give you the means to act as it, post them as the agent: one review with the `COMMENT` event, one comment per point on its line, each opening with its rank (`1/4`).
  - Otherwise, they form a *Points of attention* section of the body, titled in the documents language, in rank order, each with a permalink to its line at the layer's tip.
- **To settle.** A decision the implementer took without the human, and submits to them: each with its reason and what it costs if it is wrong. Approving the pull request settles it. A decision that would meet the criteria of an ADR (`domain-modeling`) comes with an ADR proposal. A half-delivered behaviour found during the run is to settle too, as "do not merge without <ticket>", and the ticket carries on. A decision that is neither a point of attention nor to settle is recorded in its commit message alone.
- **Departing from the design.** An implementer may depart from the change spec's design, as a point of attention. When the departure touches what a later ticket depends on, it also corrects the design in the change spec, where later implementers read it.
- **Off the ticket.** A drift spotted outside the ticket becomes at once an issue, as the `Drift` section of `docs/agents/triage-labels.md` says, and the pull request cites it. The layer keeps to its ticket: the issue is worked after the run.
- **Main repository at the end.** When you noted its branch at launch, switch it back to that branch, and apply the stash set aside then, if any, dropping it once applied. When it has changes by then, touch nothing.
- **Report.** End the run with one comment on the change spec, giving:
  - the stack, by the link `gh stack link` prints (a single ticket's pull request, by its own link), and each layer: its ticket's title and its pull request's link;
  - each decision to settle, with its layer, and the manual checks to make;
  - each layer with many points of attention, beyond about five: its ticket was likely too big, or underspecified;
  - the stopped tickets: each one's question and its draft layer's link;
  - each ticket not taken, with its reason, and its branch when it holds work;
  - when the main repository was left with changes at the end: the branch it is on, and the stash that holds the changes set aside at launch, if any.

  Your final message points at that comment.

## Slicing with `to-tickets`

When running `/to-tickets` on a change spec, keep the skill's issue template and add the following.

- The change spec's `Spec delta` holds the blocks (`D1`, `D2`…): the exact text to write in a context's functional spec, glossary or the context map. Each ticket names, in *What to build*, the blocks it transcribes ("Transcribes D2 and D5"). Each block goes to exactly one ticket. A block number is not a file path: name it. Show each ticket's blocks in the breakdown you present.
- A ticket merged alone after its blockers must not leave any user facing a half-delivered behaviour, and every user story of the change spec is delivered by at least one ticket. If this cannot hold without a flag the change spec does not declare, say so and stop: the change spec must be revised first.
- The ticket that transcribes the blocks creating a context's spec comes first in that context. If the change spec declares a flag, the first gated ticket transcribes the block that adds the gating sentence, and the lift ticket is blocked by every gated ticket.
- When publishing, create the label `context:<context>` for each context the change spec touches, if it is missing. For each context the change spec marks as existing but not adopted, also open an issue `Adopter <context>` with the labels `needs-triage` and `context:<context>`, saying that its functional spec only describes what this change touches. A new context gets none.
