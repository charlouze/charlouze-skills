---
name: adopt-context
description: Adopt one or more existing contexts of a project that already has code: write each one's functional spec, glossary and context map lines from its documents or the human, never from the code, audit the code against them, and open an adoption PR without code, with its drift issues.
argument-hint: "[contexts] [documents] [issues to close]"
disable-model-invocation: true
---

# Adopt context

The human runs the **adoption** on one or more contexts of a project that already has code. It describes, in each context's functional spec, everything the context already does, from its documents or from the human. The spec is never born from the code: the code serves the audit, the behaviours put to the human, and the names of the glossary's `_Code_` lines, never the wording of an intention. Only the human decides an intention: the boundary, the subdomain, every behaviour no document states, each document's fate and each ADR go through them before the PR opens.

- **A document** is any source of intention: a file of the repo outside the code, an issue of the project (a change spec, a ticket, a grilling resolution), the root glossary, a context's partial functional spec, or what the human names. A document is authoritative only on the intentions it states, never on mechanisms.
- **A lead** is a violation a document asserts: a clue for the audit, never a fact.
- **The adoption draft** is what the adoption writes before its PR: each adopted context's functional spec and glossary, and their lines of the context map.
- **The adoption PR** carries the draft, without code, to `main`: a stack of one layer.
- **The ledger** is your working record, in a file outside the repo, kept from step 2 to the end: each document with its date and kind; each rule of the draft with its source document and its audit finding; each lead; each question put to the human and their answer; each issue to open; each **decision to settle**, as the ``Stacked delivery with `implement-spec` `` section of the instructions file defines one.

The arguments name, all optional, the contexts to adopt, the documents that matter, and the issues the PR closes. With none, propose the contexts at step 3.

Read before starting, and hold to them throughout:

- `writing-functional-specs`, by the Skill tool: every line of the draft obeys it;
- `docs/agents/domain.md`: the glossary format, the context map and the subdomain;
- `docs/agents/triage-labels.md`: the triage roles' labels and the `Drift` section;
- `docs/agents/issue-tracker.md`: how to create an issue;
- `docs/agents/git-history.md`: the git history policy, which the adoption PR follows up to its finalization.

Run `git` and `gh` as your instructions say, through the identity wrapper they give, if any. Write the draft, the issues and the PR in the project's documents language (the `Language of produced documents` line of the instructions file).

## Steps

### 1. Check the prerequisites

The instructions file (`CLAUDE.md`, else `AGENTS.md`, at the repo root) holds a `## charlouze-skills` block, and the `## File structure` section of `docs/agents/domain.md` carries the tag `<!-- charlouze-skills -->`, the multi-context layout. Otherwise, tell the human to run `/setup-charlouze-skills`, and stop, having written nothing.

Done when both hold.

### 2. Gather the documents

List, without submitting anything to the human:

- the repo's files outside the code: specs, notes, registers (`*.gaps.md`), batches, READMEs, ADRs;
- the project's issues, open and closed;
- the root `GLOSSARY.md`, when there is one;
- each context's partial functional spec, when it has one;
- the documents the human named.

Date each one by its last commit (`git log -1 --format=%cs -- <path>`), or an issue by its last update. Set apart the documents that describe the code (a library README, a generated API doc): they serve the audit only. A project's existing ADRs stay as they are: they are no source of rules.

Done when every document is in the ledger with its date and kind.

### 3. Delimit

Propose to the human, for each context, leaning on `domain-driven-design` when available and on the documents:

- **its boundary**: what it covers, what it leaves to which neighbours, the external systems it talks to, the terms it borrows;
- **its subdomain**, with the three tests of `domain.md`;
- **its relationships**, each with its mode (conformist or translation) and what crosses.

Say whether you adopt several contexts in one PR, and why: closely linked contexts are read together.

The context map's rules of `domain.md` hold: a lone context is `core` without asking, two `core` contexts at most, and a neighbour without a functional spec stays off `## Contexts`, while a boundary and a relationship may name it.

Write nothing before the human has settled.

Done when the human has settled each context's boundary, subdomain and relationships, and which contexts go in this PR.

### 4. Draft from the documents

Fetch, then create the branch `adopt/<context>` (`adopt/<context>+<context>` for several) from `origin/main`. When the working tree has changes, show them and ask the human what to do with them before switching.

Write each context's `docs/contexts/<context>/SPEC.md` and `GLOSSARY.md`, in the formats of `writing-functional-specs` and `domain.md`, and its lines of `## Contexts` and `## Relationships` in `GLOSSARY-MAP.md`, created when missing. Only the adopted contexts enter `## Contexts`.

- **Intentions come from the documents.** When two documents contradict each other, the most recent wins, and the choice is a decision to settle.
- **The root glossary feeds the contexts' glossaries.** A term's `_Code_` line waits for the audit, at step 5.
- **A partial functional spec is the starting point.** Change none of its rules yourself. A document that contradicts one of its rules, even a more recent one, leaves the rule intact, and is put to the human at step 6.
- **A lead** goes in the ledger, aimed at the section of the rule it concerns.
- **A technical decision of a document** that meets the three ADR criteria of `domain-modeling` becomes an ADR proposal, put to the human at step 6.

With no document at all, the spec has no section yet: step 5 audits the context's code at its boundary, and its observable behaviours, grouped into candidate sections, make up all the series of step 6. With documents covering only part of the context, both ways combine.

Done when every intention the documents state for the context is a rule of the draft or an entry of the ledger, each rule with its source document.

### 5. Audit

Launch one fresh subagent per section of the draft, every call in one message so that they run in parallel, with [audit.md](audit.md) as its brief. Give each one the section's text and its rules with their sources, the leads aimed at it, the glossary terms it uses, the context's boundary, and the code paths and modules within it. With no section, give each subagent one part of the code at the boundary instead.

Sort what they return by this table, and record it in the ledger:

| Case | In the spec | Issue |
|---|---|---|
| Documented rule, held by the code | yes | none |
| Documented rule, done otherwise by the code | yes | violation |
| Documented rule, behaviour absent | no | gap of intention, citing its document |
| Documented rule, doubtful | no | gap of intention, and a decision to settle |
| Undocumented behaviour, **wanted** | yes | none |
| Undocumented behaviour, **not wanted** | the rule the human states | violation |
| Undocumented behaviour, **later** | no | gap without category |
| Lead from a document, confirmed | as its rule says | violation |
| Lead from a document, not reproduced | as its rule says | none; a decision to settle, "fixed since?" |
| Lead in a part not audited | — | cited by the audit issue of its part |
| Document contradicting a rule of a partial spec | the existing rule, intact | gap of intention, citing its document |

An issue's labels and category come from the `Drift` section of `triage-labels.md`, never from this table. A section a subagent could not cover is not audited: it gets one **audit issue**, titled "Audit <part> against the functional spec" in the documents language, which cites the leads aimed at it.

Write in each term's `_Code_` line the name the audit found, when that name says the term; a term with no name in the code, or whose name does not say it, goes to step 6.

Done when every section has its subagent's report, every rule, lead and behaviour has its row in the ledger, and every term has its `_Code_` line or its question for step 6.

### 6. Put the series to the human

One series per section, in the grilling format: numbered questions, each with your recommendation. A series holds, for its section:

- each behaviour no document describes, stated as the rule it would serve;
- each term with no faithful name in the code: the human keeps the code's name, or gives the one that holds, and the code then becomes a violation;
- each contradiction between a document and a rule of a partial spec: the human keeps the rule, and its gap issue carries the document's intention to triage, or corrects the rule themselves;
- each ADR proposal;
- the fate of each document it used: delete a document the draft fully absorbs and that competes with the spec; keep one that is still a source. A document covering several contexts is offered for deletion only at the adoption of the last of them.

A mechanism is never put to the human. For each behaviour, the human answers **wanted**, **not wanted** (with the rule that holds) or **later**; the table of step 5 says what follows.

Done when every series is answered, and the draft and the ledger carry the answers.

### 7. Review the draft

1. Launch one fresh subagent per functional spec, with [spec-review.md](spec-review.md) as its brief and the paths of the spec and its glossary: it reads them outside the context that wrote them.
2. Then call the Skill tool with `grid-review` at the spec hook point, on the adoption draft: each adopted context's `SPEC.md` and `GLOSSARY.md`, and `GLOSSARY-MAP.md`. It returns `## Grids at spec`.

Fix each remark you accept; a fix that would change an intention goes to the human first. Each remark you keep as it is becomes a decision to settle, with its justification.

Done when every remark of both reviews is fixed or a decision to settle.

### 8. Open the adoption PR

The PR carries, without code: each context's functional spec and glossary, their lines of the context map, the ADRs the human accepted, numbered after the project's last one, and the deletions of the documents the human let go.

1. **Commit**, tidying as the git history policy says before the first push.
2. **Labels.** Create `context:<context>` for each adopted context that lacks it.
3. **Push**, then check that `git ls-remote origin refs/heads/<branch>` gives your local tip.
4. **The PR**, ready for review, based on `main`, with a provisional body, opened as your instructions say.
5. **The drift issues and the audit issues**, one per row of the ledger that calls for one, labelled as the `Drift` section says. Each body cites the PR by its **full URL**. A drift issue names the section of the functional spec it targets, written out as `<context>` › `<section>`, and cites its source document, when there is one; an audit issue names the part it leaves to audit, and targets no section. The rework of the PR finds its drift issues by that URL in their bodies, and follows each one by the section it names.
6. **The full body**, its headings in the documents language:
   - *Boundary*: per context, what it covers, what it leaves to whom, its subdomain and its relationships, as the human settled them;
   - *Documents used*: each document, its date and its settled fate, kept or deleted in this PR; or that no document existed;
   - *To settle*: each decision to settle of the ledger;
   - *Audit coverage*: the sections audited, those not audited, and the audit issues. It stands in for *Manual checks*, which the adoption PR does not have;
   - *Drifts*: the issues created, by kind (violation, gap of intention, gap without category), with the reminder that closing the PR without merging it means closing these issues too, since nothing runs when a PR closes;
   - `Closes #<n>` for each open "Adopt <context>" issue of an adopted context, and each issue the human named at launch.
7. **The points of attention**, as the ``Stacked delivery with `implement-spec` `` section of the instructions file defines and posts them.

Done when the PR's body holds every section, every issue of the ledger is open and listed under *Drifts* or *Audit coverage*, and the points of attention are posted.

### 9. Report

End on one message: the PR's link; the number of issues created by kind (violation, gap of intention, gap without category, audit); and what is left to the human: review the PR, then `/rework-stack` on their comments, `/finalize-stack` once it is approved, and the merge.
