# Domain Docs

How the engineering skills should consume this repo's domain documentation when exploring the codebase.

## Before exploring, read these

- **`GLOSSARY.md`** at the repo root, or
- **`GLOSSARY-MAP.md`** at the repo root if it exists: it points at one `GLOSSARY.md` per context. Read each one relevant to the topic.
- **`docs/adr/`**: read ADRs that touch the area you're about to work in. In multi-context repos, also check `src/<context>/docs/adr/` for context-scoped decisions.

If any of these files don't exist, **proceed silently**. Don't flag their absence; don't suggest creating them upfront. The `/domain-modeling` skill (reached via `/grill-with-docs` and `/improve-codebase-architecture`) creates them lazily when terms or decisions actually get resolved.

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

## Use the glossary's vocabulary

When your output names a domain concept (in an issue title, a refactor proposal, a hypothesis, a test name), use the term as defined in `GLOSSARY.md`. Don't drift to synonyms the glossary explicitly avoids.

If the concept you need isn't in the glossary yet, that's a signal: either you're inventing language the project doesn't use (reconsider) or there's a real gap (note it for `/domain-modeling`).

## Flag ADR conflicts

If your output contradicts an existing ADR, surface it explicitly rather than silently overriding:

> _Contradicts ADR-0007 (event-sourced orders), but worth reopening because…_

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
