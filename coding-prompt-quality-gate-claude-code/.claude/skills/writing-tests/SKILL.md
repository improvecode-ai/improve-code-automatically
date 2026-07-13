---
name: writing-tests
description: Rules for writing or editing tests — unit tests, spec files, test files, test suites. Use whenever creating, adding, or modifying tests so they verify expected behavior rather than locking in the current (possibly buggy) implementation.
---

# Test-Writing Rules

> Derived from `docs/prompting-best-practices-for-developers.md` — keep in sync.

When writing or editing tests:

- **Test expected behavior, not current implementation.** Never write tests that only confirm what the code currently does — that locks bugs into a passing suite.
- **Restate the expected behavior as a list of cases before writing.** If the implementation appears to contradict the intended behavior, flag it instead of encoding the bug into a green test.
- **Don't target "100% coverage."** Target meaningful cases: happy path, empty/invalid input, boundary conditions.
- **For critical logic** (payments, auth, access control), expect the developer to define the scenarios; fill in the implementations against those rather than inventing what "correct" means.
