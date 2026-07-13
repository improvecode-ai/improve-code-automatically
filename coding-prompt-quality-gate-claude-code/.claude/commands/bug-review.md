---
description: Structured bug review of a named function or file (not the whole codebase)
---

# Bug Review

> Derived from `docs/prompting-best-practices-for-developers.md` — keep in sync.

Review the code I name (the selected code, or the file/function in `$ARGUMENTS`) for bugs. Don't jump straight to a fix. Respond in this order:

1. Summarize what the code currently does, in plain language.
2. List its inputs, outputs, and any side effects.
3. Flag each bug with severity (low / medium / high) and the cause.
4. Propose the smallest fix for each.
5. Add 2–3 tests that would catch each bug if it recurred.

Scope the review to the named function or file — not the whole codebase.
