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

### Slicing with `to-tickets`

When you run `/to-tickets` on a change spec, keep its issue template and add the following.

- **Blocks.** The change spec's `Spec delta` holds the blocks (`D1`, `D2`…): the exact text to write in a context's functional spec, its glossary or the context map. Each ticket names, in *What to build*, the blocks it transcribes ("Transcribes D2 and D5", in the documents language). Each block goes to exactly one ticket. The template's rule against file paths spares block numbers: name them. Show each ticket's blocks in the breakdown you present.
- **Slicing rule.** Each ticket, merged alone after its blockers, leaves no user facing a half-delivered behaviour, and every user story of the change spec is delivered by at least one ticket. When the change spec cannot be sliced so without a flag it does not declare, say so and stop, publishing nothing: the change spec must be revised first.
- **A context without a functional spec**, new or existing: the ticket that transcribes the blocks opening its `SPEC.md` comes first in that context, as a blocker of every other ticket that touches it.
- **Each flag the change spec declares**: its gated tickets are those that deliver a part it gates. The first gated ticket, a blocker of every other gated ticket, transcribes the block that adds the gating sentence. The lift ticket removes the flag from the code, keeping the gated behaviour on, transcribes the block that removes the gating sentence, and is blocked by every gated ticket. When the flag outlives the change spec, lifted on a condition, the lift ticket states that condition too and stays open until it holds.
- **Publishing.** Create the label `context:<context>` for each context the change spec touches, when it is missing. For each context the change spec marks as existing, not adopted, also open an issue titled "Adopt <context>" in the documents language, labelled with the `needs-triage` role's label and `context:<context>`, saying that its functional spec describes only what this change touches.

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
- **Pull request body.** The template of `pr`, plus `Closes #<ticket>`: from the start in the first layer, and in the others only once `gh stack link` has run, since GitHub ignores closing keywords in a pull request based on another branch than `main` outside a stack.
- **Report.** End the run with one comment on the change spec, giving:
  - the stack, by the link of its top pull request, and each layer: its ticket's title and its pull request's link.

  Your final message points at that comment.
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
- **``Slicing with `to-tickets` ``** completes `/to-tickets` for a change spec written by the `Change spec` instructions.
- **``Stacked delivery with `implement-spec` ``** has `/implement-spec` deliver the tickets of a change spec as one native stack, one layer per ticket, in place of its integration branch.

## Planning the change

- **No `## charlouze-skills` heading in the file**: plan the whole block, placed right after the `## Agent skills` section: after its last line, before the next `#` or `##` heading, or at the end of the file. One blank line separates it from its neighbours.
- **The heading exists**: keep the block where it is, and plan only what it lacks. One blank line goes before each addition.
  - **A missing line** goes after the block's last line, before its first section.
  - **A missing section** goes at the block's end, in the order the block above gives.
- **What is present is the human's.** A present line keeps its value, whatever it is: when `Language of produced documents` is present, do not ask for the language. A present section keeps its content as it stands. When that content differs from the plugin's, list the section by its heading under **Kept**, with "the plugin's section" as the value this setup would have written, never its content.
