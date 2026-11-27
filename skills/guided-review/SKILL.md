---
name: guided-review
description: Review a stack of PRs with the human, layer by layer, bottom up: present each unchecked decision to settle, each thread to judge and each unchecked manual check, with the diff excerpt and your opinion, collect the human's verdicts, and post them as one GitHub review per layer, under the human's name, once they approve it.
argument-hint: "[a PR of the stack]"
disable-model-invocation: true
---

# Guided review

A **stack** is a sequence of PRs, each based on the one below, reviewed one by one and merged together; each PR is a **layer**. The human runs the **guided review** in a fresh session after a run or a rework, to judge with you what the stack submits to them: its **decisions to settle**, its **points of attention** and its **manual checks**. For each, you show where it sits in the diff, explain what is at stake and give your opinion; the human gives their **verdict**: "ok", or what to change. Their verdicts end up on GitHub, as a review they could have written by hand, so that `/rework-stack`, run afterwards in any session, reads them like any other review.

Write in the project's documents language.

## The script

`bash <this skill's directory>/scripts/guided-review.sh`, whose header gives its commands, outputs and codes. It is the only way the guided review reads the threads and posts the verdicts.

- `notes <PR>`: the stack, bottom to top, each layer either `skipped` or with its `source` and its **threads to judge** (`notes`): points of attention (`note`, with their `rank`) and a rework's answers to the human's threads (`answer`).
- `submit <PR> <file>`: posts one layer's review from a submission file.

**The script acts under the human's identity, always.** It drops `GH_TOKEN` and `GITHUB_TOKEN` itself, so `gh` falls back on the human's own account. Run it as your instructions run any `gh` command, identity wrapper included: the script overrides it. On **code 4**, the identity is not a user: tell the human to log in with `gh auth login`, and stop.

**What you read yourself**, posting nothing: a layer's diff, by `git` (`git fetch`, then `git diff origin/<base>...origin/<head>`), and its PR body (`gh pr view <n> --json body`). A thread's messages come from `notes` only.

## Steps

### 1. Read the stack

Run `notes` from the PR the human names, else the PR of the current branch. Save its output to a file outside the repo.

- **Code 3**, the stack forks: name the two PRs, ask the human which one belongs to the stack, and stop.
- **No layer to review**, every one `skipped`: say so, name the skipped layers with their reason, and stop.

Done when you hold `notes`' output with at least one layer to review.

### 2. Review each layer, bottom up

For each layer that is not `skipped`, in order, read its PR body and list its items, in this order:

1. **Decisions to settle**: each unchecked box, `- [ ] <text>`, of the body's section that holds them. A refused decision can make the points that follow from it moot: say so when you reach them.
2. **Threads to judge**: the `note`s by `rank`, then the `answer`s, as `notes` gives them. When the layer's `source` is `body`, its points of attention live in the body's section that holds them: present each there, after the decisions, then the `answer`s.
3. **Manual checks**: each unchecked box of the body's section that holds them.

A section written as plain text, without boxes, from a project whose instructions predate them: present it whole, item by item, every time; nothing in it can be checked.

Present the items one at a time, loading each one's material only when you reach it: the diff excerpt around its line (for a thread, its `path` and `line`), and the thread's messages. For each, say what is at stake, give your opinion, and take the human's verdict. For a manual check, tell the human what to run and what to look at, and take what they observed. The human's verdict prevails over your opinion.

Done when every item of the layer has its verdict.

### 3. Submit the layer's review

Turn the verdicts into the submission file, by this table:

| Item | Verdict | Submission |
|---|---|---|
| thread to judge | ok | its id in `resolve` |
| thread to judge | a change | the request in `replies`, `{"thread": "<id>", "body": "…"}` |
| point of attention from the body | ok | nothing |
| point of attention from the body | a change | the request in `body`, quoting the point |
| decision to settle | accepted | its exact text in `checks` |
| decision to settle | refused | the refusal and its reason in `body` |
| manual check | passed | its exact text in `checks` |
| manual check | failed | what the human observed in `body` |

A box of a section without boxes gets no `checks` entry: its verdict goes to `body` when it asks for a change, and nowhere otherwise.

```json
{"event": "REQUEST_CHANGES", "body": "…",
 "replies": [{"thread": "<id>", "body": "…"}],
 "resolve": ["<thread id>"],
 "checks": ["<exact text of a box>"]}
```

- **The voice.** Every text is the human's: first person, in their words or in words they approved, never starting with `🤖`, which would make it read as yours. Your opinion that the human did not follow stays in the session.
- **`body`** is never empty: when nothing goes there, a one-line summary of what was reviewed.
- **The event.** `REQUEST_CHANGES` as soon as the review carries a request, a refusal or a failure, in `replies` or in `body`; `APPROVE` only when the human says so explicitly, and never with a request; `COMMENT` otherwise. When the human is the PR's author, the script submits `COMMENT` whatever you ask: say so.

Show the human the whole file and the event it gives, and run `submit` only once they agree; a text they want changed, change it and show the file again. **Code 5**, refused: fix what its reason names, show the file again. **Code 1** with a `review` link: the review is posted, and `failed` names what was not done after it (a thread to resolve, the boxes to check): tell the human, who does it by hand. **Code 1** without one: nothing is posted; show the error. GitHub allows one pending review per person on a PR: when the human already has one on this layer, they submit or discard it, then you run `submit` again.

Done when the layer's review is posted, its link and event noted, then go back to step 2 for the next layer.

### 4. Recap

End on this recap:

- each layer reviewed, with its review's link and event;
- the layers the human can approve now: nothing requested, every decision accepted, every check passed, when they did not approve them already;
- what failed after a submission, still to do by hand;
- the skipped layers, with their reason;
- next: `/rework-stack <PR>`, in this session or another.

Done when each item above is given, or "nothing" for an empty one.
