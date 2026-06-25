# SonarQube Rules Excluded from AI Prompts

This file documents the **84 rules** that were reviewed but **not included** in `sonarqube-ai-fix-prompts-rules.md`.

Each rule was evaluated against three criteria:

1. **Mechanical** — is the fix always the same, regardless of context?
2. **Safe** — can AI apply it without risking compile errors or runtime breakage?
3. **Single-file scope** — is one file enough to apply the fix correctly?

A rule that fails any criterion is excluded. Excluded rules are grouped below by priority: **Breaking** (most dangerous) → **Conditional** → **Removed** (the rest). Each rule appears in exactly one section.

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
| ⚪ Removed | 73 | Not auto-fixable — require human judgment or domain knowledge |
| **Total excluded** | **84** | |

*improvecode.ai*
