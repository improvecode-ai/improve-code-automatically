# SonarQube Rules Excluded from AI Prompts

This file documents the **202 rules** that were reviewed but **not included** in `sonarqube-ai-fix-prompts-rules.md` — leaving **76** fully-automatic, safe auto-fix rules in the prompts.

A rule is excluded when its fix is not mechanical, cannot be applied safely without risking compile errors or runtime breakage, needs more than a single file to apply correctly, or can only be flagged for a human rather than fixed automatically. Excluded rules are grouped below by priority: **Breaking** (most dangerous) → **Conditional** → **Re-audit** → **Flag-only / review-needed** → **Removed** (the rest). Each rule appears in exactly one section.

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

## 🔵 Flag-only / review-needed (2026-06) — demoted to keep every prompt fully automatic

These **71 rules** were dropped so the prompts apply *only* safe, hands-off fixes. They split two ways.

**Flag-only (54) — the AI can detect the issue but can only mark it with a `// TODO`; a human still writes the actual fix.** The correct fix needs intent, a value, or a design decision the AI must not guess.

| Rule | Rule | Rule | Rule | Rule | Rule |
|------|------|------|------|------|------|
| S2583 | S2589 | S1764 | S2183 | S2112 | S2639 |
| S3039 | S3864 | S3958 | S3959 | S4034 | S1143 |
| S1181 | S2235 | S2737 | S3346 | S127  | S1994 |
| S2175 | S2189 | S2251 | S2252 | S3020 | S3923 |
| S3981 | S5413 | S6417 | S6466 | S2168 | S2274 |
| S2276 | S2445 | S3014 | S3078 | S6901 | S2975 |
| S1210 | S1874 | S2970 | S5738 | S5803 | S5960 |
| S6838 | S2925 | S5845 | S5958 | S6103 | S5542 |
| S5547 | S2676 | S3398 | S2232 | S2689 | S6810 |

**Review-needed (17) — the AI *could* edit the code, but the change alters runtime behavior or requires guessing intent, so it must be developer-reviewed.**

| Rule | Category | Why it needs review |
|------|----------|---------------------|
| **S4348** | Lambda | Generating a real `Iterator` needs the right backing field/size — a wrong guess breaks iteration |
| **S6204** | Lambda | `toUnmodifiableList()` → `toList()` differs on null handling |
| **S1150** | Lambda | `Enumeration` → `Iterator` changes the API — unsafe if the method is public |
| **S1166** | Exception | Logging a swallowed exception assumes the swallow was a defect, not intentional |
| **S1989** | Exception | Wrapping a servlet method swallows exceptions that previously propagated to the container |
| **S2142** | Exception | Restoring the interrupt flag changes how interruption propagates |
| **S2272** | Exception | Adding the exhaustion check changes `Iterator.next()` behavior |
| **S2273** | Concurrency | Must pick the correct monitor to `synchronized` on — the wrong lock is a silent bug |
| **S2446** | Concurrency | `notify()` → `notifyAll()` changes thread wake-up / scheduling |
| **S3067** | Concurrency | `synchronized(getClass())` → `Class.class` changes lock identity under subclassing |
| **S5164** | Concurrency | Wrong placement of the `ThreadLocal` try/finally can clear the value too early |
| **S6218** | Serialization | Must pick which fields define record `equals`/`hashCode` — a wrong set changes equality |
| **S4274** | Annotations | `assert` → `if/throw` now always throws (asserts can be disabled in prod) |
| **S3415** | Test | Must guess which `assertEquals` argument is "expected" — a wrong guess bakes in the error |
| **S5831** | Test | Restructuring into `SoftAssertions.assertSoftly` needs the right scope |
| **S5838** | Test | Mapping a chained assertion to the right dedicated method can change what is asserted |
| **S5866** | Test | Adding `UNICODE_CASE` changes which strings the regex matches |

---

## 🟣 Safety re-audit (2026-06) — silent behavior change or guessing intent

A second, stricter per-rule re-audit removed these **18 rules** from `sonarqube-ai-fix-prompts-rules.md`.
Each *could* be auto-edited and the code still compiles — but the result either **changes runtime
behavior silently** (no compile error to catch it) or forces the AI to **guess** a value or intent.
That fails the "100% automatic, no human" bar, so they now require developer review.

| Rule | Category | Why it is not 100% safe |
|------|----------|--------------------------|
| **S1068** | Dead Code | Removing an unused private *field* fails silently when it is read only via reflection (Jackson/JPA without annotations, Spring SpEL, etc.) — the annotation skip-list cannot cover every case |
| **S1144** | Dead Code | Removing an unused private *method* fails silently when it is invoked only via reflection (JUnit, DI by name, serialization callbacks) — no compile error catches it |
| **S1132** | Code Style | `var.equals("L")` → `"L".equals(var)` silently turns an NPE (when `var` is null) into `false` — a caller relying on the throw takes a different branch |
| **S1153** | String | Removing `String.valueOf()` is wrong for `char[]`: `"" + String.valueOf(chars)` (the characters) vs `"" + chars` (array identity hash) — silent output change |
| **S5361** | String | `replaceAll`→`replace` checks only the *pattern*; the **replacement** string treats `$` and `\` specially in `replaceAll`, so `$1`/`\` silently change the result |
| **S1206** | Annotations | Generating `hashCode()` guesses which fields `equals()` uses and changes the hash of every existing `HashMap`/`HashSet` entry |
| **S2254** | Security | `getRequestedSessionId()` → `getSession().getId()` has a side effect (creates a session) and returns a different value |
| **S4830** | Security | Removing a trust-all `TrustManager`/`HostnameVerifier` breaks every connection that relied on it — functional change, not mechanical |
| **S5527** | Security | Removing the hostname-verifier bypass breaks connections that depended on it — same as S4830 |
| **S2755** | Security | Adding XXE `disallow-doctype-decl` can throw on parsers that don't support it and breaks legitimate DOCTYPE usage |
| **S6373** | Security | Adding `FEATURE_SECURE_PROCESSING` can change parser behavior or throw on unsupported parsers |
| **S6376** | Security | Setting `ACCESS_EXTERNAL_DTD`/`ACCESS_EXTERNAL_SCHEMA` to `""` breaks apps that legitimately load external DTDs/schemas |
| **S6913** | Structure | `Math.clamp` arg swap requires guessing which argument is min vs max |
| **S3984** | Structure | Adding `throw` to a bare `new Exception(...)` guesses intent and changes control flow |
| **S2677** | Structure | "Assign and check" the `read()` result is undefined — the AI invents the checking logic |
| **S1872** | Structure | `getClass().getName().equals(...)` → `instanceof` changes semantics (`instanceof` matches subclasses; the name/`==` form is exact-type) |
| **S2225** | Structure | Replacing a null return from `toString()`/`clone()` silently changes the returned value |
| **S6831** | Spring | Removing `@Qualifier` on a `@Bean` is safe only if its value equals the method name; otherwise it silently rewires which bean is selected |

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
| 🔵 Flag-only / review-needed | 71 | Dropped so prompts stay fully automatic — flag-only (54) or needs developer review (17) |
| 🟣 Safety re-audit (2026-06) | 18 | Silent behavior change, reflection risk, or guessing intent — needs developer review |
| ⚪ Removed | 73 | Not auto-fixable — require human judgment or domain knowledge |
| **Total excluded** | **202** | |

*improvecode.ai*
