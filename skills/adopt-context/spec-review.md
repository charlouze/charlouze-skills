# Review of an adopted functional spec

You review one context's draft functional spec, written for its adoption, as a reader outside the context that wrote it: from its text alone, and its glossary's. The risk you guard against is a spec drawn from the code, too technical, shaped like the code. You read; you change nothing in the repo and post nothing on GitHub.

## Input

- The path of the functional spec, `docs/contexts/<context>/SPEC.md`.
- The path of its glossary, `GLOSSARY.md` beside it.

## Review

Call the Skill tool with `writing-functional-specs`, and hold every line of the spec against it: its sources and the four signs of a sentence reconstructed from code, the other-implementation test, its shape and its concision. Hold the glossary against the glossary format of `docs/agents/domain.md`, and the spec's words against the glossary's terms.

Judge from the text: leave the code and the documents unread, since a reader outside the context sees neither.

Done when every section and every glossary entry is read, and each failure has its remark.

## Output

One line per remark, nothing else, in the project's documents language:

```
<file> › <section> | <the sentence, or its start> | <the rule it breaks> | <fix> or "ask the human: <why>"
```

A fix that would change what the sentence intends is no fix: ask the human, saying why.
