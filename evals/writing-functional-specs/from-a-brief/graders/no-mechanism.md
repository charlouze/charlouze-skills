---
type: llm
focus: { source: file, path: docs/contexts/loans/SPEC.md }
---
The document is a functional spec. Judge one thing only: does it leak an implementation mechanism?

FAIL only if a sentence names a storage technology, a database, table or column; a scheduled job or the time it runs; a class, method or function; an API endpoint or URL; a third-party service or library by product name; or a framework.

What a member, a volunteer or a neighbouring team can observe is not a mechanism: durations, limits, windows, an email a member receives, the names of contexts or teams, headings. Wording, completeness and style are out of scope.

PASS otherwise.
