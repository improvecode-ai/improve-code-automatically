# SonarQube Rules Excluded from AI Prompts

This file documents the **113 rules** that were reviewed but **not included** in `sonarqube-ai-fix-prompts-rules.md`.

A rule is excluded when its fix is not mechanical, cannot be applied safely without risking compile errors or runtime breakage, or needs more than a single file to apply correctly. Excluded rules are grouped below by priority: **Breaking** (most dangerous) → **Conditional** → **Re-audit** → **Removed** (the rest). Each rule appears in exactly one section.

---

## 🔴 Breaking — would break compilation or runtime if auto-applied

| Rule | Category | Why it can break |
|------|----------|-----------------|
| **S6829** | Spring | Wrong constructor picked → wrong beans wired silently |
| **S6830** | Spring | Bean rename breaks any `@Qualifier("old_name")` or `getBean("old_name")` elsewhere in the codebase |
| **S6862** | Spring | Same as S6830 — bean rename breaks all referencing qualifiers |
| **S4042** | Structure | `Files.delete()` on private methods adds `throws IOException`, breaking callers at compile time |

---

## 🟡 Conditional — could be safe only after a codebase-wide pre-check

These rules might be applied mechanically, but only after verifying context that a single file cannot reveal. Without the check, they cause silent logic changes or compile errors — so they stay out of the auto-fix prompts.

| Rule | Category | Required pre-check |
|------|----------|--------------------|
| **S1604** | Lambda & Functional | Verify the interface is truly `@FunctionalInterface` (single abstract method) — AI can misidentify |
| **S2097** | Annotations | Confirm the class name in the `instanceof` check matches the actual enclosing class |
| **S1201** | Annotations | Changing `equals(MyClass)` → `equals(Object)` requires rewriting all comparison logic to use the cast variable |
| **S3824** | Structure | `getOrDefault` vs `computeIfAbsent` — wrong choice silently changes semantics (eager vs lazy evaluation) |
| **S1751** | Collections | Loop-to-if refactor — safe only when `break`/`return` is unconditional on the first iteration |
| **S2114** | Collections | `list.removeAll(list)` → `list.clear()` — safe only if `equals()` is not overridden unusually |
| **S1849** | Collections | Requires knowledge of internal `Iterator` state — risk of logic errors |

---

## 🟠 Re-audit (2026-06) — demoted from auto-fix

A stricter safety re-audit removed these **29 rules** from `sonarqube-ai-fix-prompts-rules.md`.
Each was tagged auto-fix `[A]`/`[F]`, but applying it without developer review can break code
**silently** — it either renames a symbol that other files / serializers / reflection reference,
or it changes runtime behavior. These are *not* flag-only candidates, because the act itself
(a rename or a value change) is the unsafe part.

**Group A — renames (cross-file / serialization / reflection scope):**

| Rule | Category | Was | Why it is not 100% safe |
|------|----------|-----|--------------------------|
| **S100** | Naming | method name → camelCase | Renames a method — every caller (usually in other files) must change; breaks public API. Not single-file. |
| **S101** | Naming | class/interface → CamelCase | Renames a type — breaks all references and the source file name. Whole-codebase scope. |
| **S115** | Naming | constant → SCREAMING_SNAKE_CASE | Renames a constant — `public static final` is referenced cross-file; reflection / config lookups break. |
| **S116** | Naming | field → camelCase | Renames a field — Jackson/JPA use the field name as the JSON property / DB column key, so serialization changes silently. No compile error. |
| **S120** | Naming | package → lowercase | Renames a package — moves files and breaks every import across the codebase. |
| **S1700** | Code Style | field duplicating class name → rename | Field rename — same serialization / reflection break as S116. |
| **S2387** | Code Style | child field shadows parent → rename child field | Field rename, plus the de-shadowing changes which field is read at runtime. |

**Group B — runtime behavior changes (AI cannot know if the original was intentional):**

| Rule | Category | Was | Why it is not 100% safe |
|------|----------|-----|--------------------------|
| **S2447** | Null & Boolean | `Boolean` returns null → `Boolean.FALSE` | Changes the returned value; a caller branching on `== null` silently takes a different path. |
| **S2789** | Null & Boolean | `return null` → `Optional.empty()` | A caller checking `== null` takes a different branch. |
| **S2110** | Structure | invalid Date month `13 → 11` | Not mechanical — the "correct" month is a guess about intent. |
| **S2695** | Structure | PreparedStatement index `0 → 1` | Changes which parameter is bound; with several `setX` calls the whole mapping can shift. |
| **S1217** | Concurrency | `thread.run()` → `thread.start()` | Completely changes execution (current thread vs new thread). Also contradicts **S2134**, already excluded as intent-dependent — an internal inconsistency. |
| **S2111** | String | `new BigDecimal(0.1)` → `("0.1")` | Different numeric value — can flip computed results and break tests. |
| **S1317** | String | `new StringBuilder('x')` → `String.valueOf('x')` | Different object contents (capacity hint vs initial text). |
| **S2692** | Code Style | `indexOf(x) > 0` → `!= -1` | Different result when the match is at index 0. |
| **S5850** | String | regex `^a\|b$` → `^(a\|b)$` | Changes what the regex matches. |
| **S5917** | String | DateTimeFormatter `Y` → `y` | Changes formatted/parsed dates near year boundaries. |
| **S4524** | Code Style | `default` clause → last | Reordering changes fall-through semantics when cases fall into/out of `default`. |
| **S6219** | Code Style / Serialization | serialVersionUID `0L → 1L` | Breaks deserialization of data serialized under the old UID. |
| **S4347** | Security | `new Random()` → `new SecureRandom()` (universal) | `SecureRandom` reseeds non-deterministically and is far slower / can block; "apply universally" changes behavior and performance of non-security uses. |
| **S1844** | Concurrency | `lock.wait()` → `condition.await()` | Different synchronization mechanism. |
| **S2116** | Concurrency | `arr.hashCode()` → `Arrays.hashCode(arr)` | Identity hash → content hash; changes any map/set keyed on the array. |
| **S2119** | Concurrency | `new Random()` per call → shared field | Changes the random sequence (shared state across calls). |
| **S2122** | Concurrency | executor `0 → 1` core threads | Changes thread-pool execution. |
| **S2204** | Concurrency | `atomicInt.equals(42)` → `get() == 42` | `equals` is always false → real comparison; different result. |
| **S6915** | String | `indexOf("x", len)` → `indexOf("x")` | Searches from 0 instead of the end — a different result. |
| **S2718** | String | `DateUtils.truncate` → `toLocalDate()` | Different time-zone semantics. |
| **S1157** | String | `toUpperCase().equals(...)` → `equalsIgnoreCase` | Differs on null (NPE→false) and locale-specific case folding (e.g. Turkish i). |
| **S1940** | Null & Boolean | `!a.equals(LIT)` → `!LIT.equals(a)` | Flips an NPE-on-null into a value — a caller relying on the NPE takes a different path. |

> **Re-add path:** Group A — S100 / S101 / S115 / S120 could return as **Conditional** if the prompt
> first performs a codebase-wide reference update alongside the rename; S116 / S1700 / S2387 only with
> a "field is never serialized or accessed via reflection" pre-check. Group B has no safe re-add path
> — every fix changes observable behavior, so it needs a human to confirm the original was a defect.

---

## ⚪ Removed — excluded entirely (require human judgment or domain knowledge)

These rules are not auto-fixable. They require understanding intent, security context, architecture, or data flow that AI cannot safely infer from a single file. Grouped by reason below.

### Security — injection & validation (rebuilding logic required)

Fixing these means redesigning how untrusted input is handled — not a mechanical transformation.

| Rule | Rule | Rule | Rule | Rule |
|------|------|------|------|------|
| S2076 | S2078 | S2083 | S2091 | S2631 |
| S3649 | S5131 | S5135 | S5144 | S5145 |
| S5146 | S5147 | S5334 | S5496 | S6096 |
| S6173 | S6287 | S6390 | S6398 | S6399 |
| S6547 | S6549 | S5883 | S6804 | S7044 |

### Cryptography (require cryptographic knowledge)

Correct fixes depend on choosing algorithms, key sizes, and modes — decisions AI must not make blindly.

`S2053` · `S3329` · `S5344` · `S5659` · `S6377` · `S6432`

### Architecture (require codebase-wide / domain knowledge)

| Rule | Reason |
|------|--------|
| S4601 | Spring `HttpSecurity` ordering — depends on the security model |
| S4602 | `@ComponentScan` configuration — depends on package layout |
| S4684 | Persistent entity binding — depends on the data model |
| S7027 | Circular dependencies within a package — structural redesign |
| S7091 | Circular dependencies across packages — structural redesign |
| S7134 | Architectural constraint violations — depend on intended design |

### Platform / framework-specific

| Rule | Reason |
|------|--------|
| S3753 | Spring `SessionStatus` handling — flow-dependent |
| S4433 | LDAP authentication config — environment-dependent |
| S5301 | ActiveMQ configuration — broker-dependent |
| S5679 | OpenSAML usage — protocol-dependent |
| S5876 | Session creation policy — security-model-dependent |
| S6301 | Mobile database usage — platform-specific |
| S6384 | Android intent handling — platform-specific |

### Require data-flow analysis (multi-file reasoning)

| Rule | Reason |
|------|--------|
| S2134 | `Thread.run()` vs `start()` — behavior depends on intent |
| S2222 | Lock release across paths — needs flow analysis |
| S2390 | Class initialization order — cross-class dependency |
| S2886 | Synchronized getter/setter pairs — needs consistency analysis |
| S3046 | Waiting on multiple locks — needs flow analysis |
| S3064 | Double-checked locking — needs memory-model reasoning |

### Require judgment (flag-only candidates, deferred)

| Rule | Reason |
|------|--------|
| S1301 | `switch` with < 3 cases → `if` — structural choice, needs judgment |
| S2637 | `@NonNull` field set to null — fix needs context |
| S4275 | Getter/setter returns wrong field — AI may infer wrong field |
| S4423 | Weak SSL/TLS protocol — breaking change, needs decision |
| S4426 | Weak crypto key size — requires choosing a size |
| S6437 | Hardcoded credentials — AI does not know the correct env var |

### Not yet individually documented

These rules are excluded as requiring context. Per-rule reasoning is not yet documented.

`S131` · `S1479` · `S2115` · `S2118` · `S3042` · `S4349` · `S4929` · `S5261` · `S5411` · `S5808` · `S5857` · `S5869` · `S6001` · `S6262` · `S6320` · `S6397` · `S6416`

---

## Summary

| Section | Count | Action |
|---------|-------|--------|
| 🔴 Breaking | 4 | Never auto-apply — require manual review + codebase-wide search |
| 🟡 Conditional | 7 | Apply only after the stated pre-check passes |
| 🟠 Re-audit demotions | 29 | Removed from auto-fix — rename / behavior-change risk |
| ⚪ Removed | 73 | Not auto-fixable — require human judgment or domain knowledge |
| **Total excluded** | **113** | |

*improvecode.ai*
