# The models file

`docs/agents/models.md` declares the model and effort of the project's subagents that do a framed work: applying a declared grid, exploring the code and documentation for the tickets. The block's `Models` line names the roles, the values and what a missing line means, and every reader follows it. The file holds the settings only, so that the rule stays in the block, which the plugin keeps up to date: a copied list of roles or values would age in a file this setup keeps as it is.

## The file

```markdown
# Models

The model and effort of the project's subagents, one line per role. The roles, the values and what a missing line means are in the `Models` line of the `## charlouze-skills` block of `CLAUDE.md` or `AGENTS.md`.

- Grid review: <grid review value>
- Run exploration: <run exploration value>
```

## The proposed values

| Role | Proposed value | Why |
|---|---|---|
| `Grid review` | `session` | in [the spike of #106](https://github.com/charlouze/charlouze-skills/issues/106#issuecomment-6714849067), `sonnet` missed a defect that `opus` had found, a term made ambiguous; lower it only when a new spike shows a lower setting finding the same defects |
| `Run exploration` | `sonnet` | reading the code and the documentation for the tickets does not need the session's model |

## Planning the change

- **No `docs/agents/models.md`**: plan it with the file above and the proposed values, so the human can amend them before the yes.
- **The file exists**: it is the human's, whatever it holds. Plan nothing for it.
  - When one of its values differs from the proposed one, a missing line counting as `session`, list its path under **Kept**, with the proposed values as the value this setup would have written.
  - List under **Left to you** each of its lines that the `Models` line makes unreadable, quoted, with what makes it so: an unknown role, or a value outside its lists.
