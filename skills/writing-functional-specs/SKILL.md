---
name: writing-functional-specs
description: Shape and invariants of a context's functional spec. Use when writing, editing or reviewing a functional spec, or when deciding whether a rule belongs in a functional spec, an ADR or the code.
---

# Writing functional specs

A **functional spec** is the living document of one context: it states, in the present tense, the rules its behaviour holds on `main`. What is not shipped is not in it. Every rule below bears on every line of a functional spec, whoever writes it. Apply them to each sentence before it goes in, and hold each line against them when you review one.

## Invariants

1. The functional spec on `main` describes exactly what its code does.
2. Every drift is corrective work: file it as the drift rules of `docs/agents/triage-labels.md` say.
3. A pull request that changes observable behaviour carries the change to its functional spec alongside the code.
4. The functional spec is the authority of every review: code is judged against it, and code that contradicts it is wrong.
5. Only the human decides an intention or corrects a functional spec. When the code and the functional spec disagree, report the drift and leave the functional spec as written.

## Sources

A functional spec is born from documents (a validated brief, a change spec, a ticket's blocks) or from the human, never from the code. An intention is **sourced**, never deduced: an intention paraphrased from the code is the code's behaviour by another road, unverifiable from outside, shaped like the code, and it canonises the drift. What no source states is a gap: ask the human or file it, and leave the functional spec silent.

Four signs betray a sentence reconstructed from code, without knowing the domain:

- the section has the shape of the code: one sentence per branch, one paragraph per technical unit;
- it is vague where the code is precise ("a few minutes" is an erased number);
- it names an internal actor: what watches, what computes, what the context does not count;
- nobody outside the context could tell whether it holds.

The question that settles all four: what does a user or a neighbouring context lose if this sentence is false? "Nothing observable" means it is no rule.

## The other-implementation test

Business rules and intentions go in the functional spec; the mechanism stays in the code. Ask of every sentence:

> Would another developer, having implemented the same intention differently, read this sentence as true of their code?

Yes: it is a rule, it goes in. No: it is this implementation, it stays in the code. The test bears on the context's boundary, never on vocabulary: a context whose domain is infrastructure (a deployment pipeline, a plugin) states branch names and pull requests as rules, because at its boundary they are observable.

- **A rule holds when a mechanism moves.** A sentence a purely technical change would force you to rewrite was describing the technique.
- **Conformance is behaviour.** A clumsy implementation that produces the promised behaviour conforms: the functional spec says what must be true, never by which road nor with what elegance.
- **A mechanism stays out, unreworded.** The test says what leaves the functional spec; the rule behind a mechanism comes only from a source (see Sources).

## Shape

- **`Boundary` first.** The functional spec opens on a `Boundary` section: what the context covers, what it leaves to whom, and the external systems it talks to. The heading stays `Boundary` in every document language.
- **Sections follow the business.** A rule lives where the behaviour it constrains lives. A section that mirrors the code's decomposition ("the ports", "what writes where") or files rules by their nature ("the invariants", "the constraints") betrays its origin even when each sentence passes the test. A section carrying a concept observable at the boundary (a naming convention, an authority rule) follows the business, even when it holds for several behaviours.
- **One rule per paragraph, every rule normative at the same level.** Each one binds as much as the others, and only what can be held against the code goes in: a ranking makes the lower rules bind less.
- **A business choice carries its number.** A duration, a ceiling, a window, a delay is written with its value: "a session lasts four hours". Ask of every number: *a decision, or a reading of the code?* A number nobody decided is a gap, even when any implementation could hold it.
- **Rules are stated as sentences.** Worked examples and given / when / then scenarios belong in the tests.
- **Terms live in the context's glossary,** the `GLOSSARY.md` beside the functional spec. The functional spec uses the glossary's terms. A term's name in the code and the interface is a rule, carried by the glossary.
- **Asides by declared convention.** A project that wants a non-normative aside (an example, a precision tempering a neighbouring rule) declares how an aside is recognised and holds to it. An aside never carries a rule.
- **Language.** A functional spec is written in the language of the `Language of produced documents` line of the project's `CLAUDE.md`, English by default. Section names the plugin fixes, such as `Boundary`, stay in English.

## Concision

- Each sentence says one exact thing, once, and reads on its own.
- A rule states how far it holds; an exception announces itself as one.
- The functional spec states what holds, never how it came to be decided. A reason it needs lives in an ADR.
- No sentence is emphasised over the others.

## One rule, one functional spec

A rule belongs to exactly one functional spec. A rule observable at the boundary of more than one context signals a context breakdown to revisit, and that is the human's decision: put the case to them rather than copying the rule or housing it above the functional specs. The functional specs are the top of the hierarchy: a rule in a `CLAUDE.md` or an architecture note escapes review and drift rules, reading as a norm while binding nothing.

## ADRs

- An observable rule lives only in the functional spec.
- A product ruling that meets all three ADR criteria of `domain-modeling` (hard to reverse, surprising without context, the result of a real trade-off) may have an ADR. The ADR carries the reason and names the section of the functional spec; the rule itself stays in the functional spec alone.
- A technical decision, observable at no context's boundary, is no rule: its home is an ADR, in the single `docs/adr/` at the repository root.
