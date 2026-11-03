# Audit of a section

You audit one section of a context's draft functional spec against the code at the context's boundary, for its adoption. The spec states intentions taken from documents; you check what the code does about each one. You read; you run no test, change nothing in the repo and post nothing on GitHub.

## Input

- The section's text, each of its rules with its source document; or, when the context has no document, the part of the code to audit instead, with no rule.
- The leads aimed at the section: violations a document asserts, each a clue to check, never a fact.
- The glossary terms the section uses.
- The context's boundary, and the code paths and modules within it.

## What to find

Read the code at the boundary: what a user or a neighbouring context can observe of it. Then give:

- **Each rule's finding**, one of four, with the code that shows it (file and line):
  - **held**: the code produces the behaviour the rule states;
  - **done otherwise**: the code produces a different behaviour, a violation;
  - **absent**: no code produces it, a gap of intention;
  - **doubtful**: the code does not let you tell.
- **Each lead**: **confirmed**, with the code that shows it, or **not reproduced**, with what you read.
- **Each observable behaviour no rule describes**, stated as the rule it would serve, in the words of the domain, never as its mechanism: the test of `writing-functional-specs` applies, another implementation of the same intention must read it as true. Give where it shows.
- **Each term's name in the code**, and in the interface when it shows there: whether that name says the term, or the term has no name in the code.

Conformance is behaviour: a clumsy implementation that produces what a rule promises holds it.

When you cannot cover part of the section or of the code (too large, unreadable, out of reach), say so: that part is **not audited**, with the reason. "Nothing found" is said only of what you read.

Done when every rule, every lead and every term has its line, and every part of the code given is audited or declared not audited.

## Output

Only this, in the project's documents language for the texts:

```
Rules
- <rule, in a few words> | held | done otherwise | absent | doubtful | <file:line> | <what the code does, one line>
Leads
- <lead> | confirmed | not reproduced | <file:line or what you read>
Behaviours
- <the rule it would serve> | <file:line>
Terms
- <term> | <name in the code> | faithful | unfaithful | none
Not audited
- <part> | <reason>
```
