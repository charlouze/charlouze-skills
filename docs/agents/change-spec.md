# Change spec

These instructions complete `/to-spec`. Its steps and its template hold; this file adds three sections, `Contexts`, `Spec delta` and `Risks`, a flag by exception, the grids, and the human's review of the blocks before publishing. Section headings stay in English, like the template's.

## Contexts

A section added to the template, right before `Spec delta`. While you explore, name every context the change touches, with its boundary (what it covers and what it leaves to whom) and its state:

- **with a functional spec**: `docs/contexts/<context>/SPEC.md` exists;
- **new**: no functional spec, and no code within its boundary yet;
- **existing, not adopted**: no functional spec, and code within its boundary.

Search the code within each boundary to check its state, and put every contradiction to the human before writing the draft: code within a context said new, none within one said existing.

The section lists each context with its boundary and its state, and says whether the change creates it, moves its boundary, or adds a term it borrows from another context. A change that touches no context says `none`, and why.

## Spec delta

A section added to the template, right after `User Stories`. It holds the **delta**: the exact text the change writes into the functional specs, the glossaries and the context map, as **blocks**. A block, from a game project:

````md
### D6 — `docs/contexts/expedition/SPEC.md`, `Combat > Melee`

```diff
 L'ouverture de l'arc de frappe, la portée, le sens du balayage et les dégâts
 sont propres au coup.
+
+Un combattant qui a un pouvoir de mêlée porte une arme, que voient tous les
+joueurs. Quand aucun coup ne l'occupe, il tient son arme au repos.
```
````

- **One block, one paragraph.** A block `D<n>`, numbered from `D1` through the change spec, changes one paragraph. Its heading names the file and the section; its `diff` fence gives the exact text: unchanged lines, prefixed with a space, place it; `+` lines add, `-` lines remove.
- **Its file** is a context's `SPEC.md` or `GLOSSARY.md`, in `docs/contexts/<context>/`, or `GLOSSARY-MAP.md` at the repo root. Glossary and map blocks follow the formats of `docs/agents/domain.md`.
- **A block lives here only.** The rest of the change spec, and later its tickets, name it by its number: `D2`. Blocks carry paths: the template's rule against file paths holds for `Implementation Decisions`, not for this section.
- **Write the blocks** after calling the Skill tool with `writing-functional-specs`: every line of a `SPEC.md` block is a line of a functional spec, and its rules apply.
- **The context map.** Creating a context, moving a boundary or adding a borrowed term each gives a block on `GLOSSARY-MAP.md`.
- **A context without a functional spec**, new or existing: its blocks open its `SPEC.md`, with its `Boundary` and only the rules the change touches, its `GLOSSARY.md`, and its line on `GLOSSARY-MAP.md`, creating the map when it is missing.
- **No block**: the section says `none`, and why the change leaves every functional spec, glossary and the map as they are.

## Risks

A section added to the template, right after `Out of Scope`: what could go wrong with the change, while it is delivered or once it ships. One item per risk, saying what would reveal it and the fallback when there is one.

## Flag

A **flag** keeps a delivered but incomplete behaviour out of the users' reach until its lift ticket. The change spec gives it no section of its own: the `Implementation Decisions` declare it, the `Spec delta` gates the behaviour in the functional spec, the `Testing Decisions` cover it. It is the exception, for a change whose user stories cannot be delivered by tickets that each, merged alone after their blockers, leave no user facing a half-delivered behaviour.

- **Propose it** to the human before writing the draft: name the parts it would gate and why no slicing delivers them without it. Write the draft with the flag once the human agrees.
- **Declare it** in the `Implementation Decisions`: its name, its default, the parts it gates, and its lift. One flag per change spec; several only when gated parts lift at different times. How the flag is built is a decision of the `Implementation Decisions`, or of a project ADR.
- **Its gating sentence** is the rule that puts the gated behaviour behind the flag, with its default, in that behaviour's functional spec. One block of the `Spec delta` adds it; another, transcribed by the lift ticket, removes it.
- **A flag that outlives its change spec**, lifted on a condition rather than by the change's last ticket: its declared lift is that condition, and its gating sentence states it too.
- **Test both values.** The `Testing Decisions` cover each gated part with the flag on and with it off, so that `main` works either way.

## Before publishing

`/to-spec` writes the spec, then publishes it. Write it as a draft, with the additions above, and take these steps before publishing.

1. **Grids.** Call the Skill tool with `grid-review` on the draft, at the spec hook point, then at the design hook point. Fix in the draft each remark you accept. For each other remark, write the justification that keeps the draft as it is. Done when every remark is fixed or justified.
2. **Review.** Show the human every block of the `Spec delta` together, in full (or its `none` and the reason), then each flag's declaration, then each grid remark left unfixed with its justification. A justification the human accepts becomes a constraint of the `Implementation Decisions`, stated with its reason, so that no later review raises the remark again; a remark the human upholds is fixed in the draft. Show again what any answer changed. Done when the human has validated the blocks and every flag, and ruled on every remark.
3. **Publish**, as `/to-spec` says.
