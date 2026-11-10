# The CLAUDE.md block

The plugin's instructions live in one block of the instructions file (the file holding `## Agent skills`, `CLAUDE.md` or `AGENTS.md`). The plugin owns the block; the human may still edit its values, and an edited value holds.

## The block

```markdown
## charlouze-skills

Language of produced documents: <language>

Grids: declared in `docs/agents/grids.md`, applied by `grid-review`.

Code review: whenever you run `code-review`, whoever asked for it (the human, `/implement`, `/implement-spec`), also call the Skill tool with `grid-review` on the same fixed point, and report its `## Grids` section beside `## Standards` and `## Spec`.

Change spec: whenever you run `/to-spec`, also follow `docs/agents/change-spec.md`.

Git history: tidy your commits freely until a branch's first push; after it, rewrite nothing (no `rebase`, `commit --amend` or `push --force`) until the whole stack is approved, and correct with `fixup!` or `amend!` commits, propagated by merge. Follow `docs/agents/git-history.md`.

Run: reserved zones declared in `docs/agents/run.md`, applied by ``Stacked delivery with `implement-spec` ``.

Models: the model and effort of two subagent roles, declared in `docs/agents/models.md`, one line per role, `- <role>: <value>`; launch each subagent of a role with that role's model and effort. The roles, a closed list: `Grid review`, each grid subagent that `grid-review` launches, at every hook point; `Run exploration`, the optional exploration subagent of `/implement-spec`, launched with a subagent type that can write files, since it saves its notes. A role is added when a skill reads it, not before. A value is `session`, or one of the model aliases a subagent launch accepts, `sonnet`, `opus`, `haiku` or `fable`, optionally followed by a comma and an effort (`low`, `medium`, `high`, `xhigh` or `max`): `sonnet, low`. An alias follows its model's latest version. A missing file, a missing role or `session` leave the subagent the session's model and effort; a model without an effort keeps the session's effort. An unreadable line, with an unknown role or a value outside these lists, counts as missing, and whoever reads the file says so in one line of its final report, quoting each unreadable line: `grid-review` at the end of its report, `/implement-spec` in its end-of-run report. Every other subagent, implementers, `code-review`'s axes and `/rework-stack`'s included, keeps the session's model and effort.

### Slicing with `to-tickets`

When you run `/to-tickets` on a change spec, keep its issue template and add the following.

- **Blocks.** The change spec's `Spec delta` holds the blocks (`D1`, `D2`…): the exact text to write in a context's functional spec, its glossary or the context map. Each ticket names, in *What to build*, the blocks it transcribes ("Transcribes D2 and D5", in the documents language). Each block goes to exactly one ticket. The template's rule against file paths spares block numbers: name them. Show each ticket's blocks in the breakdown you present.
- **Slicing rule.** Each ticket, merged alone after its blockers, leaves no user facing a half-delivered behaviour, and every user story of the change spec is delivered by at least one ticket. When the change spec cannot be sliced so without a flag it does not declare, say so and stop, publishing nothing: the change spec must be revised first.
- **A context without a functional spec**, new or existing: the ticket that transcribes the blocks opening its `SPEC.md` comes first in that context, as a blocker of every other ticket that touches it.
- **Each flag the change spec declares**: its gated tickets are those that deliver a part it gates. The first gated ticket, a blocker of every other gated ticket, transcribes the block that adds the gating sentence. The lift ticket removes the flag from the code, keeping the gated behaviour on, transcribes the block that removes the gating sentence, and is blocked by every gated ticket. When the flag outlives the change spec, lifted on a condition, the lift ticket states that condition too and stays open until it holds.
- **Publishing.** Create the label `context:<context>` for each context the change spec touches, when it is missing. For each context the change spec marks as existing, not adopted, also open an issue titled "Adopt <context>" in the documents language, labelled with the `needs-triage` role's label and `context:<context>`, saying that its functional spec describes only what this change touches, and to run `/adopt-context` to describe the rest.

### Stacked delivery with `implement-spec`

When you run `/implement-spec`, deliver the change spec as one stack of pull requests, one layer per ticket, instead of its integration branch. This replaces its steps 3, 4, 5, 7 and 8. The rest holds: the task graph, the frontier, implementer subagents in parallel in their own worktrees, `tdd`.

- **Launch.** One change spec per run. Its tickets are its open tickets labelled with the `ready-for-agent` role's label, or those the human names. Do not assign a ticket when it starts.
- **One stack.** One native stack per change spec: no integration branch, no merger subagent, no pull request for the whole change spec. Of `gh stack`, use `link` only, never `submit`, `sync`, `rebase` or `merge`. Create branches and push with `git`.
- **Reserved tickets.** A ticket is reserved when it touches a reserved zone, a path that only the main repository touches, the checkout the worktrees hang from. `docs/agents/run.md` declares the zones as globs. At launch, classify each ticket by matching against them the paths where the modules the change spec assigns it live in the code. A reserved ticket's implementer leaves the main repository with no changes when it hands back, pushed or stopped: its work is committed on its branch. A reserved ticket's draft layer is finished in the main repository too.
- **Main repository at launch.** When `docs/agents/run.md` declares a reserved zone, note the main repository's branch. If it has changes, show its changed files and ask the human what to do with them: discard them (offer this first), set them aside in a stash named after the change spec, or keep them and take no reserved ticket. Then, when it has no changes, bring its branch up to date: fast-forward it to its upstream (`git merge --ff-only`), and leave it as it is when it cannot be.
- **Start.** A ticket starts once all its blockers are pushed, in its own worktree, on a branch from the top of the stack (for the first layer, `origin/main`, fetched at launch). A reserved ticket starts in the main repository instead, one at a time, and only when the main repository has no changes: during the run, never touch a main repository with changes, and the reserved tickets are then not taken, nor their descendants.
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
  - When your instructions have you act on GitHub under an identity of your own, distinct from the human's, post them under it: one review with the `COMMENT` event, one comment per point on its line, each opening with the mark `🤖` and its rank (`🤖 1/4`), the mark by which the agent's skills tell its messages from those of the humans. The pull request's author is then you, which tells your comments from those of its reviewers.
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

### Stacked delivery with `implement`

When you run `/implement` with two or more ticket references, deliver those tickets as one stack of pull requests, one layer per ticket, as ``Stacked delivery with `implement-spec` `` says, instead of working them in the session and committing them to the current branch. This replaces `/implement`'s last step and its single agent; the rest of `/implement` holds: each ticket's title stated before starting, `tdd`, `code-review`. With a single ticket, a spec or a description, this section does not apply, and `/implement` runs as it is.

- **One implementer per ticket.** Each ticket is built by its own implementer subagent, which runs the whole layer cycle in its own worktree; you implement nothing in the session. A reserved ticket, one that touches a zone `docs/agents/run.md` declares, runs in the main repository instead, as ``Stacked delivery with `implement-spec` `` says. A stash set aside at launch is named after the run's ticket numbers, since there is no change spec to name it after.
- **Launch.** The run's tickets are those the human names, whatever their label. Do not assign a ticket when it starts. Not taken, each with its reason, given in the documents language:
  - a closed ticket;
  - a ticket whose parent is a change spec: reason "`/implement-spec`";
  - a ticket that needs a change spec, because its fix would change a rule of a functional spec, a glossary or the context map, which only the blocks of a change spec change: reason "needs a change spec". A violation, whose fix brings the code back to its functional spec, is taken;
  - a ticket natively blocked by an open ticket outside the run, and the descendants of every ticket not taken.
- **Exploration.** At launch, an exploration subagent, the optional step of `/implement-spec`, mandatory here, reads each ticket and the code it targets, and gives for each one the modules it will touch, what its fix needs, and whether it needs a change spec.
- **Task graph.** Build the run's task graph so:
  - the native blockers between the run's tickets hold;
  - a "needs" blocker, inferred: A blocks B when B's fix builds on A's, without which B does not build or its tests fail;
  - a "same code" blocker, inferred: of two tickets that touch the same module, the one the human named first blocks the other, which lies on top of it instead of rebasing in conflict;
  - an inferred blocker that would contradict a native one, or close a cycle, is dropped.

  Do not write the graph on GitHub: the stack's order keeps its result, and a stopped ticket's comment what waits on it.
- **Show it, without waiting.** At launch, show the graph, each inferred blocker with its kind and its reason, and the tickets not taken, then start the frontier, the tickets with no blocker left, without waiting for an answer. A human who wants another order interrupts you, or declares native blockers and relaunches.
- **Read otherwise.** These clauses of ``Stacked delivery with `implement-spec` `` read otherwise, each named by its title; every other clause holds as it stands:
  - **`Launch`**: replaced by this section's `Launch` and `Task graph`;
  - **`One stack`**: one native stack per run;
  - **`Reserved tickets`**: the modules the exploration gives a ticket stand for those the change spec assigns it;
  - **`Stopping a ticket`**: case 1, the change spec's, reads: the ticket cannot be done as it is written, the code or a functional spec shows it wrong, or it turns out to need a change spec; case 2, the ADR's, reads: an ADR cannot be held. The stopped ticket's comment also lists each descendant waiting on it, with its blocker's kind and reason;
  - **`Departing from the design`**: depart from the ticket's text, as a point of attention; there is no design to correct;
  - **`Draft layer`**: its body names its ticket without a closing keyword, and once it is open, comment its link on the stopped ticket: that is how the relaunch finds it;
  - **`Relaunch`**: when a ticket the human names has an open draft layer, finish that layer first, as the clause says, then stack the other tickets on top; otherwise, start a new stack from `main`;
  - **`Report`**: your final message in the session, since no change spec can carry it, with the inferred blockers and their reasons besides. The decisions to settle and the manual checks stay in the pull requests too, and a stopped ticket's question in its comment.

### Autonomous triage with `triage`

When you run `/triage`, however the request is worded, triage on your own, without waiting for the human. This replaces what `/triage` leaves to the human: picking from the buckets, deciding after your recommendation, settling a conflict or an unusual transition of states, and being grilled on a request that needs fleshing out. Its quick state override ("move #42 to ready-for-agent") still applies as it stands. The states and categories below are triage roles, whose labels `docs/agents/triage-labels.md` gives.

- **Which tickets.** The tickets the human names. Without any, every ticket in the three buckets `/triage` shows as needing attention: the unlabelled tickets, those in `needs-triage`, and those in `needs-info` with a reply since the last triage notes.
- **What holds.** For each ticket, `/triage`'s checks: gather its context, search for an existing implementation by domain concept, read `.out-of-scope/`, and verify the claim (reproduce the bug, run the relevant tests). Then apply the outcome as `/triage` does, within the rules below.
- **Decide on what is written.** A state rests only on written sources: the ticket and its comments, the code, a functional spec, a glossary, an ADR, `.out-of-scope/`. When deciding would take a preference of the human's written in none of them, the ticket goes to `needs-info`. These cases go there in any event:
  - a bug you cannot reproduce, or whose report lacks the details to try;
  - a gap, a behaviour of the code that no functional spec describes: ask whether it is wanted, and leave it without a category, as the `Drift` section of `docs/agents/triage-labels.md` says;
  - written sources that contradict each other;
  - a conflict of state roles, or a transition `/triage` would flag as unusual: ask what `/triage` would have asked.

  A ticket that would have needed grilling goes to `needs-info` too, and the questions of the grilling become those of its notes.
- **`needs-info` notes.** `/triage`'s template, its questions specific and addressed to the human, without mentioning anyone: the author of a drift issue is often the agent itself, and triaging every bucket would otherwise send a notification per ticket.
- **`wontfix`** only for a ticket already implemented, pointing at where, or one that matches an existing entry of `.out-of-scope/`. A new rejection is a product decision: `needs-info`, asking whether to reject it.
- **Beyond a ticket.** A ticket that needs a change spec, as the `Launch` clause of ``Stacked delivery with `implement` `` defines it, goes to `ready-for-human`. Its comment says why, and points at the flow: `/grill-with-docs`, or `/wayfinder` when the change does not fit in one session, then `/to-spec`; say which of the two seems to fit. A violation stays a ticket for the agent.
- **Every ticket leaves decided**: with one category and a decided state, or in `needs-info`; none stays in `needs-triage`.
- **Your writes** are labels, comments and closed issues, on the issue tracker only: the repository stays as it is, with no block, functional spec, glossary, context map, ADR or `.out-of-scope/` entry.
- **Report.** Each triaged ticket gets its comment, opening with `/triage`'s disclaimer. End the session with one table: ticket, category, state, and the reason in one line, the `needs-info` tickets first.
```

The block holds two forms: **lines**, then **sections**.

- **A line** is known by its label, the text before its colon, which stays in English in every project.
- **A section** is a `###` heading and everything under it, up to the next heading of level 3 or less outside a code fence. It is known by its heading, which stays in English in every project. Sections follow the last line of the block.

What each one is for:

- **`Language of produced documents`** is the language of the documents the agents produce in this project, for this plugin's skills and Matt's alike. `<language>` is the human's answer, which may come with the command; offer English as the default.
- **`Grids`** points at the project's declaration of its grids, which [grids-file.md](grids-file.md) plans.
- **`Code review`** joins the Grids axis to every review: Matt's `code-review` is completed, never replaced, so that `/implement` and `/implement-spec` get the axis as they are.
- **`Change spec`** points `/to-spec` at the instructions that complete it, which [change-spec-file.md](change-spec-file.md) plans.
- **`Git history`** states the policy in short, so that no session rewrites a pushed branch, and points at the whole policy, which [git-history-file.md](git-history-file.md) plans.
- **`Run`** points at the project's reserved zones, which [run-file.md](run-file.md) plans.
- **`Models`** gives the model and effort of the grid and exploration subagents, from the project's declaration, which [models-file.md](models-file.md) plans. It is the only source of the reading rule, so that the plugin keeps it up to date in every project, and it completes `/implement-spec`'s exploration step without replacing it.
- **``Slicing with `to-tickets` ``** completes `/to-tickets` for a change spec written by the `Change spec` instructions.
- **``Stacked delivery with `implement-spec` ``** has `/implement-spec` deliver the tickets of a change spec as one native stack, one layer per ticket, in place of its integration branch. It runs a ticket that touches a reserved zone in the main repository, and links the stack through the `gh stack` extension, which step 2 checks.
- **``Stacked delivery with `implement` ``** has `/implement`, given two or more tickets, deliver them as one native stack in an order it infers from the tickets and the code, by reference to ``Stacked delivery with `implement-spec` ``, whose clauses it rereads by their titles. That section stays as it is, under its heading: a renamed or rewritten section would never reach a project already set up, since a present section keeps its content.
- **``Autonomous triage with `triage` ``** has `/triage` triage on its own, the tickets of its buckets or those named, without waiting for the human or grilling them: it decides a state only on what is written, sends to `needs-info` whatever needs a preference of the human's, and writes nothing but labels, comments and closed issues.

## Planning the change

- **No `## charlouze-skills` heading in the file**: plan the whole block, placed right after the `## Agent skills` section: after its last line, before the next `#` or `##` heading, or at the end of the file. One blank line separates it from its neighbours.
- **The heading exists**: keep the block where it is, and plan only what it lacks. One blank line goes before each addition.
  - **A missing line** goes after the block's last line, before its first section.
  - **A missing section** goes at the block's end, in the order the block above gives.
- **What is present is the human's.** A present line keeps its value, whatever it is: when `Language of produced documents` is present, do not ask its question. A present section keeps its content as it stands. When that content differs from the plugin's, list the section by its heading under **Kept**, with "the plugin's section" as the value this setup would have written, never its content.
