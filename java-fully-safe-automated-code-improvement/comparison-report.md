# Comparison Report — Two Java Auto-Refactoring Rule Sets

Comparing the two rule sources in this folder:

| | **File A — Claude Code SAFE prompts** | **File B — SonarQube AI-fix rules** |
|---|---|---|
| Path | `safe-refactoring-rules/refactor-prompts-safe.md` | `sonarqube/sonarqube-ai-fix-prompts-rules.md` |
| Form | Narrative **prompts** (educational + apply) per category | Terse **one-line rules** keyed to Sonar rule IDs |
| Size | 11 categories + MEGA prompt (~554 lines) | 72 rules across 15 sections (~155 lines) |
| Authority model | Self-derived, guard-first, conservative | Anchored to official Sonar rule IDs (Sxxxx) |
| Safety gate | **Compile-only** gate, explicitly defined, with revert step | None stated — relies on each rule being "mechanical" |
| Human review | Designed for **zero** review (autonomous) | Claims "no human intervention" |
| Verification | Built-in `mvn/gradle compile` + `git checkout` revert loop | Not specified |

---

## 1. What each file *is*

**File A (Claude Code SAFE)** is a *procedure*. Each category ships two prompts — an
EDUCATIONAL dry-run that only reports a findings table, and a SAFE apply that makes the edit —
plus a hard-rules list, explicit GUARDs, and a shared **verification gate** that compiles after
each category and reverts the whole category on failure. Its governing claim is narrow and
testable: *every possible model mistake in this tier surfaces as a compile error*, so a
compile-only gate (no test run, no human) is sufficient. Anything that can compile yet change
behavior is deliberately **demoted** to a companion AGGRESSIVE file (e.g. `@NotNull` adding,
import sorting, empty-catch logging, comment removal, magic-number extraction).

**File B (SonarQube)** is a *catalog*. 72 fixes, each one line, each tagged with the Sonar rule
ID it implements (S117, S1128, S1125, …). It is broad and dense, covering areas File A never
touches — serialization contracts, concurrency, security, Spring, AssertJ/Mockito test quality.
It states a blanket safety claim ("never changes public API, business logic, or compilation")
but provides no mechanism (no gate, no revert, no dry-run) to enforce it.

---

## 2. Where they overlap (the common safe core)

Both agree on a mechanical, behavior-neutral core:

| Fix | File A | File B |
|---|---|---|
| Remove unused imports | §3/§6 | S1128 |
| `if (x == true)` → `if (x)` etc. | §2 Logic | S1125 |
| `size() == 0` → `isEmpty()` | §9 | S1155 |
| 3+ duplicate string literals → constant | §3 | S1192 |
| Add missing `@Override` | §8 | S1161 / S2177 |
| Local/param naming (camelCase / de-abbreviate) | §1 | S117 |

On these six, the two files are mutually confirming — the strongest signal that they belong in a
truly-safe tier.

---

## 3. Where they diverge — the important part

### 3a. File B applied things File A explicitly *demoted as unsafe* — now reconciled

This was the headline finding of the original audit. Four File B rules (marked ✅ below) were
exactly the operations File A judged to have a "compiles-clean-but-changes-behavior" failure mode
and moved out of its safe tier. **As of the 2026-06 re-tier they have been removed from File B**
(now 72 rules) and recorded in `not-safe-rules/sonarqube-excluded-rules.md`; the table below is
the finding as originally identified, kept for the rationale.

| Operation | File B (applies it) | File A (verdict) |
|---|---|---|
| ✅ **Log empty catch blocks** | S108 — *adds a logger + log line* | **Demoted to AGGRESSIVE** — observable output → log-asserting tests fail; intentional swallow becomes noise |
| ✅ **Loop → stream aggregation** | S3631 (`for`→`Arrays.stream().sum()`) | Forbidden in SAFE — "Do NOT convert loops to streams" |
| ✅ **Loop copy → `addAll`/`arraycopy`** | S3012 | Not in SAFE — semantics differ on null/concurrent/duplicate handling |
| ✅ **Concrete → interface type** (`ArrayList`→`List`) | S1319 | Not in SAFE — can break call sites needing the concrete API |
| **`@Autowired` removal on sole constructor** | S6818 | Out of SAFE scope — annotation/DI behavior (still present — candidate for review) |

> ✅ = removed from File B in the 2026-06 re-tier. S6818 was flagged but left in for now.

File B's "no human intervention" promise is therefore **broader and less defensible** than File
A's. Without a test run, S108 alone can silently red a CI build that asserts on log output.

### 3b. File A has guard/verification machinery File B lacks entirely

- **Compile-then-revert gate** — File A reverts a whole category on any compile failure;
  File B has no rollback story.
- **EDUCATIONAL dry-run** — File A lets you preview every finding as a table before applying;
  File B is apply-only.
- **Explicit GUARDs** — e.g. File A skips a boolean-return rewrite on boxed `Boolean`
  (null/unboxing risk), skips renames that would shadow a field, skips diamond on anonymous
  classes pre-Java-9. File B's rules carry occasional inline "skip if…" notes but far fewer.
- **Demotion cross-references** — File A names *where* the riskier sibling lives and *why*.

### 3c. File B has far broader coverage File A never attempts

File B owns whole domains absent from File A:

- **Serialization** (S2060/S2061/S2062/S2157/S2675) — `writeObject`/`readObject` signatures,
  `readResolve` visibility, `Cloneable`.
- **Concurrency** (S2066 static inner class, S3066 enum field immutability).
- **Spring** (S3751, S6818, S6833, S6856 path-variable binding).
- **Security-mechanical** (S5445 temp-file, S4925 JDBC driver, S2151 finalizers).
- **Test quality** (S5779/S5790/S5810/S5833/S5841/S5863/S6068 — AssertJ, Mockito, JUnit5).
- **Numeric/contract correctness** (S2167 `compareTo` MIN_VALUE, S2200, S4517 signed-byte).

Many of these are genuinely subtle, high-value fixes — but several are also the *least*
"mechanical" (S6856 requires verifying the param name matches the URL template; S2167 is a
correctness bug fix, not a style change).

---

## 4. Advantages and disadvantages

### File A — Claude Code SAFE prompts

**Advantages**
- **Defensible safety claim.** The compile-only gate is justified by an explicit invariant
  (every mistake → compile error) and backed by an automatic revert. This is the only one of the
  two that can honestly say "run unattended."
- **Self-checking workflow.** Dry-run preview + per-category compile + rollback makes failures
  cheap and observable.
- **Guard-first.** Edge cases (boxed booleans, field shadowing, reflective param binding,
  pre-Java-9 diamond) are called out and skipped rather than hand-waved.
- **Explicit tiering.** Risky operations aren't silently dropped — they're routed to a named
  AGGRESSIVE file with the reason, so nothing is lost, just gated.
- **Self-documenting.** Educational blocks teach *why*, useful for onboarding/review.

**Disadvantages**
- **Narrow coverage.** 11 categories; nothing on serialization, concurrency, Spring, security,
  or rich test refactors.
- **Verbose.** ~554 lines of prose to express far fewer transformations; higher token cost to
  feed to a model, slower to scan.
- **No external authority.** Rules are self-derived; no rule IDs to trace to a linter's
  rationale, suppression, or CI integration.
- **Java-version/tooling assumptions** baked into prose rather than config.

### File B — SonarQube AI-fix rules

**Advantages**
- **Breadth and density.** 72 high-value fixes in a compact, scannable list — far more
  coverage per line.
- **Traceable.** Every rule maps to an official Sonar ID, so each fix has published rationale,
  a CI counterpart, and a suppression mechanism.
- **Catches real bugs, not just style.** S2167, S4517, S2061 etc. fix latent correctness/contract
  defects File A never looks for.
- **Token-efficient** to hand to a model.

**Disadvantages**
- **Overstated safety.** The "no human intervention / never changes behavior" claim does not
  hold for several rules (S108 logging, S3631 stream conversion, S3012 copy rewrite, S1319
  interface-typing). By File A's own analysis these can compile yet change observable behavior.
- **No safety gate.** No dry-run, no compile-and-revert, no rollback unit — a bad apply has no
  defined recovery.
- **Uneven "mechanical-ness."** Rules range from trivially safe (S1128) to judgment-requiring
  (S6856 param-name/template match, S2147 "skip if bodies differ even slightly") under one flat
  "safe" banner.
- **No preview/education layer** — apply-only, harder to review intent.

---

## 5. Bottom line / recommendation

The two files are **complementary, not competing**, and they disagree on one real thing: *what
counts as safe-to-run-unattended*.

- **File A is the safer engine.** Its compile-only-gate + revert + guard discipline is the only
  rigorous "autonomous, no-review" story here. Trust its tiering.
- **File B is the richer rule catalog.** Its breadth (serialization, concurrency, Spring,
  security, test quality, correctness bugs) is where the value-per-line is.

**Suggested synthesis:** adopt **File A's verification framework** (dry-run → per-category
compile → revert; SAFE vs AGGRESSIVE tiering) and **populate it with File B's rule catalog**,
re-tiering each Sonar rule through File A's lens:

- *Pure-mechanical / compile-or-nothing* (S1128, S1125, S1155, S1192, S1161, S1858, S1110, …) →
  **SAFE tier**.
- *Compiles-clean-but-can-change-behavior or needs judgment* (**S108**, **S3631**, **S3012**,
  **S1319**, S2147, S6856, S6818) → **AGGRESSIVE tier** (run the test suite + review the diff).

That gives you File B's coverage with File A's honesty about what truly needs no human.

> ✅ **Resolved (2026-06):** the four rules where File B was more aggressive than File A's safe tier
> — **S108** (log empty catch), **S3631** (loop→stream), **S3012** (loop copy→built-in), **S1319**
> (concrete→interface type) — have been removed from `sonarqube-ai-fix-prompts-rules.md` (76 → 72
> rules) and moved to `not-safe-rules/sonarqube-excluded-rules.md` under the
> *🟤 SAFE-prompt alignment re-audit (2026-06)* section (total excluded 202 → 206). The two files
> now agree on what is safe to run unattended.
