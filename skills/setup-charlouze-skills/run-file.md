# The run file

`docs/agents/run.md` declares the project's **reserved zones**: the paths that only the main repository touches, the checkout the worktrees hang from, such as the Unity part of a game, whose editor is open there. The block's `Run` line points at it, and its ``Stacked delivery with `implement-spec` `` section says what a reserved zone changes for a ticket. The file holds the zones only, so that the rule stays in the block, which the plugin keeps up to date.

## The file

```markdown
# Run

## Reserved zones

The paths that only the main repository touches, the checkout the worktrees hang from. One glob per line, from the repo root. What they change is in the `## charlouze-skills` block of `CLAUDE.md` or `AGENTS.md`.

<zones>
```

`<zones>` is one line per reserved pattern, `` - `<glob>` ``, or `None.` when there is none.

## The proposed zones

Propose the zones of each project type detected in the repo, and none when no type is detected.

| Project type | Detected by | Reserved zones |
|---|---|---|
| Unity | a `ProjectSettings/ProjectVersion.txt` file, outside `.git/` | `Assets/**`, `ProjectSettings/**`, `Packages/**` |

A project found in a subdirectory gets its zones under that directory: `game/ProjectSettings/ProjectVersion.txt` gives `game/Assets/**`, `game/ProjectSettings/**` and `game/Packages/**`.

## Planning the change

- **No `docs/agents/run.md`**: plan it with the file above and the proposed zones. When showing it, name each project type detected and the file that revealed it, or say that none was, so the human can amend the zones before the yes.
- **The file exists**: it is the human's, whatever it holds. Plan nothing for it. When its zones differ from the proposed ones, list its path under **Kept**, with the proposed zones as the value this setup would have written.
