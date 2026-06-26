# No More Manual Sonar Fixes.

> Paste a prompt. Review the diff. Commit.
> That's it — AI handles the rest.

Every time SonarQube flags an issue in your code, someone has to fix it manually.
Multiply that by hundreds of issues, dozens of files, and every sprint —
and you're spending hours on work that follows fixed, predictable rules.

**This file gives AI everything it needs to fix those issues automatically.**
No configuration. No plugins. Works with Claude Code and GitHub Copilot.

> ✅ **All 165 rules are safe for AI automation — no breaking changes, no business logic touched, applicable to any Java project.**
> Rules requiring domain context are flag-only (add a TODO comment) — AI never guesses.

---

## ⏱️ Time saved

| Scenario | Manual time | With AI |
|-|-|-|
| Fix one SonarQube scan failure (10–20 issues) | 30–60 min | 2 min review |
| Clean up a legacy module (100+ issues) | 1–2 days | 20 min review |
| Pre-PR cleanup on every branch | 10–15 min per PR | 1 min |
| Clear personal issue queue | 1–3 hours | 5 min |
| Sprint-end quality pass | Half a day | 30 min review |

---

## 🚀 How to use

**1. Choose a prompt:**

| Prompt | When to use |
|-|-|
| **FIX ALL** | Fix everything in a file or package at once |
| **CATEGORY PROMPTS** | Fix one type of issue across a package |
| **PR PROMPT** | Fix only new/changed code in current branch — runs `git diff` automatically |
| **SONAR REPORT PROMPT** | Paste your SonarQube issue list — AI fixes each one at the exact line |

**2. Replace `[FILE_OR_PATH]` with your path**
e.g. `src/main/java/com/example/order`

**3. Paste into Claude Code or GitHub Copilot**

**4. Review git diff → commit**

---

## 💡 Key use cases

**Before every PR** — run PR PROMPT, push clean code, reviewers focus on logic not style

**After a production incident** — run EXCEPTION HANDLING category, find every swallowed exception

**Onboarding legacy code** — run FIX ALL once, establish a clean Sonar baseline

**CI pipeline fails** — export issue list from Sonar UI, paste into SONAR REPORT PROMPT, done

**Java version upgrade** — run LAMBDA AND FUNCTIONAL category, modernize lambda expression forms and stream patterns

---

## 📊 Coverage — 165 rules across 15 categories

### Rule coverage statistics

| | Count |
|---|---|
| Public SonarQube Java rules reviewed | **278** |
| Rules included in prompts (safe for AI) | **165** (59%) |
| Rules excluded (need human judgment) | **113** (41%) |

> All excluded rules are documented with reasoning in `sonarqube-excluded-rules.md`.

### Rules by category

| Category | Rules | % | What gets fixed |
|-|-|-|-|
| Naming | 2 | 1% | camelCase locals/params, type parameters |
| Dead Code | 5 | 3% | Unused imports, fields, methods, variables |
| Null and Boolean | 5 | 3% | isEmpty(), redundant boolean literals |
| Code Style | 23 | 14% | Modifier order, redundant parens, string literal flip |
| String | 8 | 5% | String.valueOf in concat, compareTo, parameterized logging |
| Lambda and Functional | 14 | 8% | Lambda expression form, streams, assign-then-return |
| Exception Handling | 11 | 7% | Empty catch, swallowed exceptions, interrupt flag |
| Collections and Loops | 17 | 10% | for-each, isEmpty(), interface type declarations |
| Concurrency | 13 | 8% | static inner class, ThreadLocal cleanup, synchronized fixes |
| Serialization | 7 | 4% | Constructors, signatures, clone(), equals() in records |
| Annotations and Boilerplate | 14 | 8% | @Override, hashCode/equals pairs, @Deprecated |
| Spring | 6 | 4% | @RestController, @PathVariable, single-constructor @Autowired cleanup |
| Test Quality | 15 | 9% | AssertJ, JUnit5, assertion order, Mockito |
| Security (Mechanical) | 10 | 6% | XXE, weak SSL, insecure temp files |
| Structure | 20 | 12% | Magic numbers, dead code, stream misuse |
| **Total** | **165** ¹ | **100%** | |

¹ *5 rules appear in 2 categories (S1155, S2151, S3012, S3039, S4454) — category sum is 170, unique total is 165.*

---

## ⚙️ Requirements

* **Claude Code** (`claude` CLI) — [install](https://docs.claude.ai/en/docs/claude-code)
* **GitHub Copilot** in IntelliJ IDEA (with agent/terminal access enabled)
* **GitHub Copilot** in VS Code (with terminal access)
* Java project with `pom.xml` or `build.gradle`
* SonarQube instance — optional, prompts work standalone without it

---

## 🔒 Safety

Every rule in this file is:

* **Public** — sourced from official SonarQube Sonar way Java profile
* **Mechanical** — AI applies a fixed, predictable transformation
* **Non-breaking** — does not change public API, business logic, or compilation
* **Verified** — all 165 rules confirmed in public SonarQube sources
* Rules requiring domain context are **flag-only** (add TODO comment, never auto-fix)

---

## Files in this folder

| File                                                                       | Contents |
|----------------------------------------------------------------------------|---|
| [`sonarqube-ai-fix-prompts.md`](./sonarqube-ai-fix-prompts.md)             | 4 ready-to-use prompts (FIX ALL, CATEGORY, PR, SONAR REPORT) |
| [`sonarqube-ai-fix-prompts-rules.md`](./sonarqube-ai-fix-prompts-rules.md) | Full RULES REFERENCE — 165 rules with auto-fix `[A]` and flag-only `[F]` annotations |
| [`sonarqube-excluded-rules.md`](./sonarqube-excluded-rules.md)             | 113 excluded rules with documented reasons — Breaking, Conditional, Re-audit, Removed |
