---
type: llm
---
The text is the final report of a setup run. The human said yes to every change before seeing any proposal, so two instructions of CLAUDE.md that contradict the flow are still there, awaiting a yes given once their proposal is shown: supercharlouze's block (`## Specs and plans`, between `<!-- supercharlouze:begin -->` and `<!-- supercharlouze:end -->`), and the convention line "Write each test before its code, following `superpowers:test-driven-development`."

PASS only if the report's section headed "Left to you" names both instructions, as still in CLAUDE.md, each with the change proposed for it (a removal or a rewording).

FAIL if either is missing from that section, or if the report says either was removed or reworded.
