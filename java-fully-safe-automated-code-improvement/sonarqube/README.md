# No More Manual Sonar Fixes.

> Paste a prompt. Review the diff. Commit.
> That's it — AI handles the rest.

Every time SonarQube flags an issue in your code, someone has to fix it manually.
Multiply that by hundreds of issues, dozens of files, and every sprint —
and you're spending hours on work that follows fixed, predictable rules.

**This file gives AI everything it needs to fix those issues automatically.**
No configuration. No plugins. Works with Claude Code and GitHub Copilot.

> ✅ **All 69 rules are safe, fully automatic AI fixes — no breaking changes, no business logic touched, no human intervention, applicable to any Java project.**
> Rules that could only add a TODO, or whose fix could change behavior or require guessing intent, are not in the prompts — they live in `sonarqube-excluded-rules.md`.

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

**Pre-PR cleanup** — run DEAD CODE category, strip unused imports, parameters, and local variables

**Onboarding legacy code** — run FIX ALL once, establish a clean Sonar baseline

**CI pipeline fails** — export issue list from Sonar UI, paste into SONAR REPORT PROMPT, done

**Java version upgrade** — run LAMBDA AND FUNCTIONAL category, modernize lambda expression forms and stream patterns

---

## 📊 Coverage — 69 rules across 15 categories

### Rule coverage statistics

| | Count |
|---|---|
| Public SonarQube Java rules reviewed | **278** |
| Rules included in prompts (safe, fully automatic) | **69** (25%) |
| Rules excluded (flag-only, review-needed, or human judgment) | **209** (75%) |

> All excluded rules are documented with reasoning in `sonarqube-excluded-rules.md`.

### Rules by category

| Category | Rules | What gets fixed |
|-|-|-|
| Naming | 2 | camelCase locals/params, type parameters |
| Dead Code | 3 | Unused imports, parameters, local variables |
| Null and Boolean | 3 | isEmpty(), redundant boolean literals |
| Code Style | 20 | Modifier order, redundant parens, charset constants |
| String | 2 | toString on String, parameterized logging |
| Lambda and Functional | 5 | Lambda expression form, assign-then-return, ThreadLocal.withInitial |
| Exception Handling | 1 | runFinalizersOnExit removal |
| Collections and Loops | 3 | isEmpty(), varargs, raw map generics |
| Concurrency | 2 | static inner class, enum field final |
| Serialization | 5 | Constructors, signatures, clone(), readResolve/readObject |
| Annotations and Boilerplate | 6 | @Override, @Repeatable unwrap, nullability on primitives |
| Spring | 4 | @RestController, @PathVariable, single-constructor @Autowired cleanup |
| Test Quality | 6 | AssertJ reorders, JUnit5 visibility/@Nested, Mockito static import |
| Security (Mechanical) | 2 | runFinalizersOnExit removal, secure temp files |
| Structure | 8 | compareTo contract, entrySet, try-with-resources |
| **Total** | **69** ¹ | |

¹ *3 rules appear in 2 categories (S1155, S2151, S4454) — category sum is 72, unique total is 69.*

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
* **Fully automatic** — applied with no human intervention; the AI never guesses
* **Verified** — all 69 rules confirmed in public SonarQube sources

---

## Files in this folder

| File                                                                       | Contents |
|----------------------------------------------------------------------------|---|
| [`sonarqube-ai-fix-prompts.md`](./sonarqube-ai-fix-prompts.md)             | 4 ready-to-use prompts (FIX ALL, CATEGORY, PR, SONAR REPORT) |
| [`sonarqube-ai-fix-prompts-rules.md`](./sonarqube-ai-fix-prompts-rules.md) | Full RULES REFERENCE — 69 safe, fully-automatic auto-fix rules, each with a per-rule Guard |
| [`sonarqube-excluded-rules.md`](./sonarqube-excluded-rules.md)             | 209 excluded rules with documented reasons — Breaking, Conditional, Re-audit, Flag-only/review, Safety re-audit, SAFE-prompt alignment, Behavior-correcting, Removed |
