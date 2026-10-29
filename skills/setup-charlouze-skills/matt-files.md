# Matt's files

`/setup-matt-pocock-skills` writes `docs/agents/domain.md`, `docs/agents/triage-labels.md` and the `### Domain docs` line of the `## Agent skills` block. This setup completes them so that Matt's `domain-modeling` and `triage` follow the plugin's rules: it appends tagged sections, and rewrites Matt's layout into the plugin's multi-context one, its only rewrite of Matt's text. A rerun of Matt's setup restores his templates and drops all of it; a rerun of this setup plans it again.

A **tagged section** is a `##` section whose first non-blank line after the heading is `<!-- charlouze-skills -->`. It runs to the next `#` or `##` heading outside a code fence, or to the end of the file.

## Planning the change

Plan each row on its own, with the content of the matching section below, copied exactly as it stands between the outer fences.

| File | Change | Done when |
|---|---|---|
| `docs/agents/domain.md` | Replace the `## File structure` section, heading included, with [File structure](#file-structure) | its `## File structure` section is tagged |
| `docs/agents/domain.md` | Append [Glossary format](#glossary-format) at the end of the file | it has a tagged `## Glossary format` section |
| `docs/agents/domain.md` | Append [Context map](#context-map) at the end of the file, after the glossary format | it has a tagged `## Context map` section |
| `docs/agents/triage-labels.md` | Append [Drift](#drift) at the end of the file | it has a tagged `## Drift` section |
| The instructions file | Replace the line under `### Domain docs` with [Domain docs line](#domain-docs-line) | that line names `docs/contexts/` |

- **A done row plans nothing**, whatever its content: a tagged section the human edited holds as it stands.
- **The layout is the one rewrite.** Matt's `## File structure` section and `### Domain docs` line are his template, not a value the human set: rewrite them whenever their row is not done.
- **A missing anchor.** `domain.md` without a `## File structure` section: append it before the tagged sections. A block without `### Domain docs`: add the heading and the line at the end of the `## Agent skills` block.
- **Spacing.** One blank line before each heading, one between a heading and its content; the file ends with one newline.

## File structure

````markdown
## File structure

<!-- charlouze-skills -->

The repo is laid out for several contexts from its first one. `GLOSSARY-MAP.md` at the repo root lists the contexts, and appears with the first. Each context keeps its functional spec and its glossary in `docs/contexts/<context>/`, whatever the shape of the code. Every ADR, system-wide or context-specific, lives in the single `docs/adr/` at the repo root.

```
/
├── GLOSSARY-MAP.md
├── docs/
│   ├── adr/
│   │   ├── 0001-event-sourced-orders.md
│   │   └── 0002-postgres-for-write-model.md
│   └── contexts/
│       ├── ordering/
│       │   ├── SPEC.md
│       │   └── GLOSSARY.md
│       └── billing/
│           ├── SPEC.md
│           └── GLOSSARY.md
└── src/
```
````

## Glossary format

````markdown
## Glossary format

<!-- charlouze-skills -->

A context's `GLOSSARY.md` follows the format of `domain-modeling`, with two additions.

- **`_Code_:`** closes every term's entry and gives the term's name in the code, and in the interface when it shows there. That name belongs to the language, not to the implementation: code and interface use it as written.
- **`## Borrowed`** follows `## Language` and holds the terms this context takes from another one. Each borrowed term is redefined to what this context uses of it, and names its owning context, the only one that defines it in full.

```md
## Language

**Invoice**:
A request for payment sent to a customer after delivery.
_Avoid_: Bill, payment request
_Code_: `Invoice`

## Borrowed

**Order** (owned by [Ordering](../ordering/GLOSSARY.md)):
A confirmed purchase; this context uses only its lines and its total.
_Code_: `Order`
```
````

## Context map

````markdown
## Context map

<!-- charlouze-skills -->

`GLOSSARY-MAP.md` follows the format of `domain-modeling`, with this shape.

```md
# Glossary Map

## Contexts

- [Ordering](./docs/contexts/ordering/GLOSSARY.md) (core): receives and tracks customer orders
- [Billing](./docs/contexts/billing/GLOSSARY.md) (supporting): generates invoices and collects payments

## Relationships

- **Ordering → Billing**: conformist, Billing invoices the orders that Ordering confirms
```

- **`## Contexts`** has one line per context that has a functional spec, with its subdomain in parentheses after the link: `core`, `supporting` or `generic`, in the documents language (in French: `cœur`, `support`, `générique`). A neighbour without a spec stays off this list until its adoption; a relationship may still name it.
- **`## Relationships`** has one line per relationship: `**upstream → downstream**: <mode>, <what crosses, in one sentence>`. The mode is `conformist` when the downstream context takes the upstream terms with their meaning, `translation` when it names them its own way and converts them at the boundary (in French: `conformiste`, `traduction`). The borrowed terms live in the downstream glossary alone.
- **Every borrowing implies a relationship, and every relationship is carried by at least one borrowing.** A term under `## Borrowed` has its relationship on the map; a relationship on the map has a borrowed term behind it.
- **Contexts only.** The map holds no shared kernel and no external system: an external system is named in the `Boundary` of the functional spec of the context that talks to it.
- **The map changes only through blocks**: those of a ticket's delta, or of an adoption.
- **The subdomain is the human's decision.** Propose one from three tests, then ask:
  - differentiation: would a competitor with the same implementation erase what sets the project apart? Yes: core; it would inconvenience: supporting; it could be swapped: generic;
  - outsourcing: could a contractor or an off-the-shelf product take it over? No: core; with customisation: supporting; easily: generic;
  - competence: does it take deep knowledge of the project's domain? Deep: core; some: supporting; none: generic.

  A project has one or two `core` contexts at most. A lone context is `core` without asking, and the map has no relationship.
````

## Drift

````markdown
## Drift

<!-- charlouze-skills -->

A **drift** is code on `main` that contradicts its context's functional spec (a **violation**), or what no functional spec describes (a **gap**): a behaviour of the code, or an intention, wanted or still to decide. Every drift is corrective work, recorded as an issue.

- **One issue per violation and per gap**, labelled with the `needs-triage` role's label from the table above and with `context:<context>`, the context it concerns.
- **The issue names the section of the functional spec it targets**, and cites its source document when there is one (a brief, a change spec, a ticket).
- **Category.** A violation is a `bug`; an intention no functional spec describes is an `enhancement`. A behaviour of the code that no functional spec describes stays without a category until triage: the human decides whether it is wanted.
- **A part not yet audited against its functional spec** gets one issue, titled "Audit <part> against the functional spec" in the documents language.
- **The issue is the whole record**, kept in no other file. Its labels are ones the project already has, such as the triage role, `bug` or `enhancement`, plus `context:<context>`.
- **`context:<context>` exists from the context's birth**: the change that creates a context creates its label.
````

## Domain docs line

```markdown
Multi-context: `GLOSSARY-MAP.md` at the repo root from the first context, each context's `SPEC.md` and `GLOSSARY.md` in `docs/contexts/<context>/`, one `docs/adr/` at the repo root. See `docs/agents/domain.md`.
```
