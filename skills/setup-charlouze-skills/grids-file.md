# The grids file

`docs/agents/grids.md` declares the grids that `grid-review` applies in this project: which skill judges, at which hook points, over which zone of the code, and the lines it leaves out. The setup writes the default declaration there in full, so that the human sees what they can change; the block's `Grids` line points at it.

## Planning the change

- **No `docs/agents/grids.md`**: plan it with the content of [default-grids.md](../grid-review/default-grids.md), copied exactly.
- **The file exists**: it is the human's, whatever it holds. Plan nothing for it. When any value of any grid differs from the default declaration, list its path under **Kept**, with "the default declaration" as the value this setup would have written, never its content.

`CODING_STANDARDS.md` never names a grid: the Standards axis of `code-review` would apply it a second time, as a hard rule. Plan nothing in it.
