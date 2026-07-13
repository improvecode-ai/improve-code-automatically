# Copilot Prompt Quality Gate

A self-checking prompt gate for GitHub Copilot in JetBrains IDEs (IntelliJ etc.).
Before Copilot acts on a coding request, it checks the request against a small set
of prompt-quality rules and, if something important is missing, returns feedback
plus a stronger version before proceeding.

## File layout (already arranged in this bundle)

```
.github/
  copilot-instructions.md                  # always-on core gate + 6 rules
  instructions/
    writing-tests.instructions.md          # loads only on test files (path-scoped)
  prompts/
    bug-review.prompt.md                   # invoked on demand via /bug-review
docs/
  prompting-best-practices-for-developers.md   # SOURCE OF TRUTH for the rules
```

## Install

1. Copy the `.github/` and `docs/` folders into the root of your repository
   (merge with any existing `.github/` folder).
2. In your JetBrains IDE, make sure the GitHub Copilot plugin has custom
   instructions enabled (on by default).
3. Done. The core gate now applies to every Copilot chat request in that repo.
   Test rules load automatically when editing test files. Trigger a bug review
   by typing `/bug-review` in Copilot chat.

## Keep in sync

`docs/prompting-best-practices-for-developers.md` is the source of truth.
The three `.github` files are derived from it — if you change the rules in the
doc, update the gate files to match (each file has a header noting this).

## Adjust before use

- **Source-doc path:** all gate files reference `docs/prompting-best-practices-for-developers.md`.
  Change that path in each file if you keep the doc elsewhere.
- **Test globs:** `writing-tests.instructions.md` uses a generic JS/TS-style
  `applyTo` glob set. Swap for your stack (e.g. `**/test_*.py`, `**/*_test.py`).

## Note on limits

This is a soft gate the model enforces on itself, not a hard block — a developer
can still force the original prompt. For true enforcement, move the check to CI
or Copilot PR code review.
