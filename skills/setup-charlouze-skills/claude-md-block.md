# The CLAUDE.md block

The plugin's instructions live in one block of the instructions file (the file holding `## Agent skills`, `CLAUDE.md` or `AGENTS.md`). The plugin owns the block; the human may still edit its values, and an edited value holds.

## The block

```markdown
## charlouze-skills

Language of produced documents: <language>

Grids: declared in `docs/agents/grids.md`, applied by `grid-review`.

Code review: whenever you run `code-review`, whoever asked for it (the human, `/implement`, `/implement-spec`), also call the Skill tool with `grid-review` on the same fixed point, and report its `## Grids` section beside `## Standards` and `## Spec`.

Change spec: whenever you run `/to-spec`, also follow `docs/agents/change-spec.md`.

### Slicing with `to-tickets`

When you run `/to-tickets` on a change spec, keep its issue template and add the following.

- **Blocks.** The change spec's `Spec delta` holds the blocks (`D1`, `D2`…): the exact text to write in a context's functional spec, its glossary or the context map. Each ticket names, in *What to build*, the blocks it transcribes ("Transcribes D2 and D5", in the documents language). Each block goes to exactly one ticket. The template's rule against file paths spares block numbers: name them. Show each ticket's blocks in the breakdown you present.
- **Slicing rule.** Each ticket, merged alone after its blockers, leaves no user facing a half-delivered behaviour, and every user story of the change spec is delivered by at least one ticket. When the change spec cannot be sliced so without a flag it does not declare, say so and stop, publishing nothing: the change spec must be revised first.
- **A context without a functional spec**, new or existing: the ticket that transcribes the blocks opening its `SPEC.md` comes first in that context, as a blocker of every other ticket that touches it.
- **Each flag the change spec declares**: its gated tickets are those that deliver a part it gates. The first gated ticket, a blocker of every other gated ticket, transcribes the block that adds the gating sentence. The lift ticket removes the flag from the code, keeping the gated behaviour on, transcribes the block that removes the gating sentence, and is blocked by every gated ticket. When the flag outlives the change spec, lifted on a condition, the lift ticket states that condition too and stays open until it holds.
- **Publishing.** Create the label `context:<context>` for each context the change spec touches, when it is missing. For each context the change spec marks as existing, not adopted, also open an issue titled "Adopt <context>" in the documents language, labelled with the `needs-triage` role's label and `context:<context>`, saying that its functional spec describes only what this change touches.
```

The block holds two forms: **lines**, then **sections**.

- **A line** is known by its label, the text before its colon, which stays in English in every project.
- **A section** is a `###` heading and everything under it, up to the next heading of level 3 or less outside a code fence. It is known by its heading, which stays in English in every project. Sections follow the last line of the block.

What each one is for:

- **`Language of produced documents`** is the language of the documents the agents produce in this project, for this plugin's skills and Matt's alike. `<language>` is the human's answer, which may come with the command; offer English as the default.
- **`Grids`** points at the project's declaration of its grids, which [grids-file.md](grids-file.md) plans.
- **`Code review`** joins the Grids axis to every review: Matt's `code-review` is completed, never replaced, so that `/implement` and `/implement-spec` get the axis as they are.
- **`Change spec`** points `/to-spec` at the instructions that complete it, which [change-spec-file.md](change-spec-file.md) plans.
- **``Slicing with `to-tickets` ``** completes `/to-tickets` for a change spec written by the `Change spec` instructions.

## Planning the change

- **No `## charlouze-skills` heading in the file**: plan the whole block, placed right after the `## Agent skills` section: after its last line, before the next `#` or `##` heading, or at the end of the file. One blank line separates it from its neighbours.
- **The heading exists**: keep the block where it is, and plan only what it lacks. One blank line goes before each addition.
  - **A missing line** goes after the block's last line, before its first section.
  - **A missing section** goes at the block's end, in the order the block above gives.
- **What is present is the human's.** A present line keeps its value, whatever it is: when `Language of produced documents` is present, do not ask for the language. A present section keeps its content as it stands. When that content differs from the plugin's, list the section by its heading under **Kept**, with "the plugin's section" as the value this setup would have written, never its content.
