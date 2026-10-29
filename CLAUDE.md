## Agent skills

### Issue tracker

Issues are tracked in this repo's GitHub Issues, via the `gh` CLI. See `docs/agents/issue-tracker.md`.

### Triage labels

Default vocabulary: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` and `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Stacked delivery with `implement-spec`

When running `/implement-spec`, deliver the change spec as a stack of PRs, one layer per ticket, instead of an integration branch. This overrides steps 3, 4, 5, 7 and 8 of the skill. The rest is unchanged: the task graph, the frontier, implementer subagents in parallel in their own worktrees, `tdd`.

- No integration branch, no merger subagent, no PR for the whole spec.
- A ticket starts once all its blockers are pushed, in a worktree branched from the top of the stack (`main` for the first layer).
- Each implementer runs `code-review` on its own layer (its diff against the layer below) and fixes what it raises in that layer, before anything is pushed.
- A layer is not one squashed commit: it keeps one commit per distinct change, each with its own message, and no commit fixes another commit of the same layer. Before the first push, tidy them freely (fold a review fix into the commit it fixes).
- Layers are pushed one at a time, in the order tickets finish: rebase onto the current top of the stack (allowed, since nothing of this layer is pushed yet), rerun the tests (and `code-review` on the layer too if the rebase had conflicts), push, then open a ready-for-review PR whose base is the layer below (`main` for the first).
- From the second layer on, link the stack with `gh stack link <bottom-branch> … <top-branch>`, and only then write `Closes #<ticket>` in the PR body: GitHub ignores closing keywords in a PR that targets another branch than `main` outside a stack. Never use `gh stack submit`, `sync`, `rebase` or `merge`. A single ticket gives an ordinary PR.
- Once a layer is pushed, never rewrite it (no rebase, amend or force-push).
- Report the stack: each layer's ticket and PR link.
