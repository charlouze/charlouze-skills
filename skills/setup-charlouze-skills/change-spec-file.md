# The change spec file

`docs/agents/change-spec.md` holds the instructions that complete `/to-spec`: the `Contexts`, `Spec delta` and `Risks` sections of a change spec, its flag by exception, the grids it goes through and the human's review of its blocks before publishing. The block's `Change spec` line points `/to-spec` at it.

## Planning the change

- **No `docs/agents/change-spec.md`**: plan it with the content of [change-spec.md](change-spec.md), copied exactly.
- **The file exists**: it is the human's, whatever it holds. Plan nothing for it. When its instructions differ from those of [change-spec.md](change-spec.md), list its path under **Kept**, with "the plugin's change spec instructions" as the value this setup would have written, never its content.
