# Grids

The grids `grid-review` applies in this project, one per `##` section. Change any of them to fit the project. A grid whose skill is not installed is reported missing, and the others still run.

## DDD strategic

- **Skill**: `domain-driven-design`
- **Hook points**: spec, design, review
- **Zone**: all code
- **Excluded lines**:
  - 3 (aggregates), 4 (behaviour), 5 (events): the DDD tactical grid judges them.
  - 6 (translation), 7 (core subdomain) at review: the context map settles them, at spec and design.
- **Condition**:
  - At spec: the draft creates or moves a context, or touches a glossary or the context map.
- **Focus**:
  - At spec: on the context map and the glossaries as the draft leaves them, check that every borrowed term has its relationship on the map and every relationship a borrowed term behind it, and that one or two contexts at most are `core`.
  - At review: hold every name the diff introduces or renames against the `_Code_:` lines of its context's glossary, found by the layout of `docs/agents/domain.md`.

## DDD tactical

- **Skill**: `domain-driven-design`
- **Hook points**: design
- **Zone**: all code
- **Excluded lines**:
  - 1 (language), 2 (boundaries), 6 (translation), 7 (core subdomain): the DDD strategic grid judges them.

## Clean architecture

- **Skill**: `clean-architecture`
- **Hook points**: design, review
- **Zone**: all code

## Software design philosophy

- **Skill**: `software-design-philosophy`
- **Hook points**: design, review
- **Zone**: all code
- **Focus**:
  - Word every remark in the vocabulary of `codebase-design`: module, interface, implementation, depth, seam, adapter, leverage, locality.

## Clean code

- **Skill**: `clean-code`
- **Hook points**: review
- **Zone**: all code
