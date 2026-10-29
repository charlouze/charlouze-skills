---
type: llm
---
The text is the final report of a setup run on a repo whose CLAUDE.md holds two instructions that send the agent to another development flow:

1. the block between `<!-- supercharlouze:begin -->` and `<!-- supercharlouze:end -->` (heading `## Specs and plans`, which tells the agent to invoke `supercharlouze:using-batches` and to follow superpowers);
2. the convention line "Write each test before its code, following `superpowers:test-driven-development`."

PASS only if the text proposes a change for each of the two: a removal, or a rewording (for example, pointing the second line at another TDD skill, or dropping the skill it names). A proposal may be a diff, a quote with the replacement, or a sentence naming the instruction and the change.

FAIL if either instruction gets no proposal, or if the text says either change was already applied or written.
