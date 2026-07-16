# java-fully-safe-automated-code-improvement

Refactoring prompts for Java codebases, split by risk tier so an AI agent can run the safe tier
**fully automatically** (compile-gate + auto-revert, minimal human review) while anything that
could change runtime behavior is kept in a separate, clearly-labeled tier that requires a branch,
a full test run, and a diff review.

---

## What's inside

### [safe-refactoring-rules/refactor-prompts-safe.md](./safe-refactoring-rules/refactor-prompts-safe.md)

The **SAFE** tier. 11 categories (Naming, Logic, Code Structure, Null Safety, Immutability,
Formatting, Exceptions, Annotations/Boilerplate, Loops/Collections, Comments, Tests), each with:

- **EDUCATIONAL** prompt — dry run, reports findings as a table, explains *why*, touches nothing
- **SAFE** prompt — applies the change, guarded so it cannot change runtime behavior

Every SAFE prompt runs behind a **verification gate**: compile after each category, and
`git checkout --` (auto-revert) on any compile failure. Because SAFE rules are behavior-preserving
by construction, a compile-only gate is sufficient — no test run needed. Two categories (Null
Safety, Comments) have no SAFE apply step at all ("DEMOTED") — the risk can't be caught by a
compile-only gate, so they moved entirely to the aggressive file.

Includes MEGA PROMPTS that run the full SAFE tier across a package in one pass.

### [safe-refactoring-rules/excluded/refactor-prompts-aggressive.md](./safe-refactoring-rules/excluded/refactor-prompts-aggressive.md)

The **AGGRESSIVE** tier — low-risk but *not* guaranteed safe. Two kinds of rules live here:

1. **Demoted-from-SAFE** — compiles cleanly but can silently change behavior or fail a CI gate
   (e.g. renaming parameters of public/annotated methods, extracting numeric literals,
   `@NotNull`/`@Nullable` annotations, import sorting, logging empty catches, comment removal).
2. **Maximizing** rules — broader rewrites: streams, final fields/classes, constructor/Lombok
   generation, logger unification, exception narrowing.

Every AGGRESSIVE prompt runs on a branch, behind a gate that runs **compile + full test suite**
and reverts on red — but a green gate still requires a manual diff review before committing.
Each risky operation is tagged `⚠` with its concrete failure mode (e.g. `ConcurrentModificationException`
risk on for→for-each, Mockito/CGLIB breakage on `final` classes, JSON/JPA mapping breakage on
field renames).

### [safe-refactoring-rules/copilot-optimized/copilot-optimization.txt](./safe-refactoring-rules/copilot-optimized/copilot-optimization.txt)

Notes (PL) on adapting these prompts for GitHub Copilot specifically: short bullet-point
instructions instead of long paragraphs, imperative verb openers, explicit "do not modify" /
"only within this module" clauses (Copilot doesn't infer scope or educational-mode intent as
reliably as Claude), and short sections instead of one long block.

---

## How to use

1. Point `[PACKAGE_PATH]` at a real package, e.g. `src/main/java/com/example/order`.
2. Run the **EDUCATIONAL** prompt for a category first to see what would change and why.
3. Run the matching **SAFE** prompt (or the SAFE mega prompt) to apply it — safe to run with
   little to no review, since the verification gate reverts on any compile failure.
4. For anything cross-referenced as `→ AGGRESSIVE file`, switch to
   [refactor-prompts-aggressive.md](./safe-refactoring-rules/excluded/refactor-prompts-aggressive.md),
   run it on a branch, let the gate run compile + tests, and **review the diff** before committing.
5. If the target assistant is Copilot rather than Claude Code, adapt the prompts per
   [copilot-optimization.txt](./safe-refactoring-rules/copilot-optimized/copilot-optimization.txt).

---

*Part of [improve-code-automatically](../README.md) — improvecode.ai*
