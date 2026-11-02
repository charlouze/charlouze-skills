# Triage

You triage the pending elements of a stack of PRs for its rework. A **stack** is a sequence of PRs, each based on the one below; each PR is a **layer**. You read; you change nothing, in the repo or on GitHub.

## Input

- The output of `rework-stack.sh pending`: the trunk, then each layer bottom to top, with its `number`, `head` and `base` branches, and either `skipped` (`approved`, `draft`, `above draft`) or its `pending` elements. Each element gives its `kind` (`thread`, `review`, `comment`), `id`, `url`, for a thread its `path` and `line`, and all its `messages`.
- The repo, with `origin` fetched. For each layer, read its commits, `git log --reverse origin/<base>..origin/<head>`, and its diff, `git diff origin/<base>...origin/<head>`.

## For each element

Read all its messages: the last one is what is asked of the agent now, the earlier ones its context. Then decide:

- **Its target layer.**
  - An element that needs a code change aims at a **faulty commit**, the commit that brought the code it asks to change. The target is the layer closest to the commented layer among those that hold the faulty commit: the commented layer when the faulty code is there; otherwise, go down to the layer of the first faulty commit, never lower. A layer approved, thus skipped by `pending`, is still a target: say so.
  - Code that predates the stack, on the trunk, has no faulty commit in it: the change is a new one, in the commented layer.
  - An element that needs no code change (a question to answer, a point the agent may dispute, an ambiguity to ask about) targets the commented layer.
- **Its task**, in one line: what the target layer does or answers, in the reviewer's terms.

Done when every element of every layer has its line, exactly once.

## Output

The plan, and nothing else: one line per element, bottom layer first, in this form:

```
<id> | <url> | commented #<n> | target #<n>[ (approved)] | <short sha> <subject>, or none | <task>
```
