## SonarQube — AI Fix Prompts for Java

## Fix SonarQube issues automatically with Claude Code or GitHub Copilot

### How to use

📄 For overview, use cases, and time-saving stats see `README.md`

💡 **Quickest way:** attach this file to Claude Code or Copilot Chat and type e.g. `Fix all SonarQube issues in src/main/java/com/example/order` — no prompt copying or editing needed.

Replace `\[FILE\_OR\_PATH]` with your target, e.g. `src/main/java/com/example/order`  
Choose a prompt below (FIX ALL / CATEGORY / PR / SONAR REPORT)  
All prompts apply rules from the RULES REFERENCE — see `sonarqube-ai-fix-prompts-rules.md`
Review git diff before committing

\---

### 🔧 FIX ALL — fix all SonarQube issues in a file or package

```
Step 1 — read project config once (do not modify):
  Read pom.xml or build.gradle. Note:
  - Java version (some modernization fixes need a recent language level)
  - Lombok present? (needed for boilerplate rules)
  - Dominant logger (SLF4J / Log4j / java.util.logging)

Step 2 — for each .java file in \[FILE\_OR\_PATH], one at a time:
  Read → apply rules in order below → save → next file

  Apply categories in this order (later rules can depend on earlier ones):
  1. DEAD CODE            — remove unused imports before other changes create new ones
  2. NAMING               — rename before logic changes reference old names
  3. CODE STYLE           — structural cleanup
  4. NULL AND BOOLEAN     — boolean and null simplifications
  5. COLLECTIONS AND LOOPS
  6. STRING
  7. LAMBDA AND FUNCTIONAL — convert after loops are cleaned (avoid double-conversion)
  8. EXCEPTION HANDLING
  9. CONCURRENCY
  10. SERIALIZATION
  11. ANNOTATIONS AND BOILERPLATE
  12. SPRING
  13. TEST QUALITY
  14. SECURITY (MECHANICAL)
  15. STRUCTURE

  After all categories: re-run DEAD CODE to catch any new unused imports created by earlier fixes.

Hard rules:
- Do NOT change public method signatures
- Do NOT change business logic
- If a fix requires domain knowledge → skip and note: "Skipped \[rule] in \[file:line]"

After all files print:
| File | Rule | Count |
List skipped items with reason.
```

\---

### 🏛️ FIX ALL — whole repository or a set of packages

For large scope you have two modes. They produce the **same set of applied fixes** —
parallelism changes speed, not the outcome — because every guard is evaluated identically
with read-only access to the whole repo.

**Which to pick:**
- **One main thread (Prompt A)** — safest, deterministic order, linear diff to review. Best
  for the first run or smaller scope.
- **Subagents (Prompt B)** — faster on large repos. Safe because of two things, and **not**
  because packages isolate dependencies (in real all-public projects they don't):
  (a) **disjoint write ownership** — a `.java` file belongs to exactly one package, so no
  two subagents ever edit the same file; and (b) **no applied fix is cross-file** — the
  API-preserving guards force SKIP on any fix that would have to touch a second file, so
  every applied fix stays inside its owning file. A subagent may READ other packages to
  evaluate a guard; it must never EDIT them.

Both modes emit the **3-section report** defined at the end of this section (and only that
report — not the simple count table used by the single-package FIX ALL above).

> Note on what looks cross-file but isn't: visibility changes (S3751, S5810, S2062, S1174)
> are single-file edits gated on runtime/semantics, not compilation. S6833 may leave a
> redundant (harmless) `@ResponseBody` on an inherited parent method — the applied edit
> still stays in the controller's own file.

#### Prompt A — single main thread (Copilot in IntelliJ, or any one-thread tool)

```
Apply the SonarQube safe auto-fix RULES REFERENCE (sonarqube-ai-fix-prompts-rules.md)
to the WHOLE repository (or the listed packages). Work file-by-file, sequentially.

SCOPE: [REPO_ROOT  or  list of packages, e.g. src/main/java/com/example/order, .../billing]

Step 1 — read project config ONCE (do not modify):
  Read every pom.xml / build.gradle. Note and keep in context for all files:
  - Java language level   (needed by S7158, S1161, S2151)
  - Lombok present?
  - Dominant logger SLF4J / Log4j2 / java.util.logging   (for S2629)
  - Null-analysis / strict build tooling: NullAway, errorprone, -Werror  (for S4454, S1596, S1444)

Step 2 — enumerate all .java files under SCOPE. Process them grouped by package, one file at a time.

Step 3 — for each .java file:
  a. Read the full file.
  b. Apply rule categories IN THIS ORDER (later depend on earlier):
     1 DEAD CODE  2 NAMING  3 CODE STYLE  4 NULL AND BOOLEAN
     5 COLLECTIONS AND LOOPS  6 STRING  7 LAMBDA AND FUNCTIONAL
     8 EXCEPTION HANDLING  9 CONCURRENCY  10 SERIALIZATION
     11 ANNOTATIONS AND BOILERPLATE  12 SPRING  13 TEST QUALITY
     14 SECURITY (MECHANICAL)  15 STRUCTURE
  c. For EVERY occurrence, evaluate the rule's GUARD before editing.
     If the guard needs info outside this file — a caller, subclass, supertype,
     overloaded method, the annotation's own definition, or a sibling package-info.java —
     LOOK IT UP in the repo (read-only). This matters especially for:
       detection:  S1161, S2177, S3038, S3252, S1710
       guards:     S1444, S3066, S4351, S6833, S2062, S1128, S1192, S1596, S2147, S3878
     If the guard condition holds → record it in the report (never guess intent).
  d. Re-run DEAD CODE on the file (remove imports made unused by the fixes).
  e. Save the file before moving to the next.

HARD RULES:
- Never change a public/protected method signature or any public API.
- Never change business logic; anything needing domain knowledge → record + note.
- Finish each file fully before the next; no half-fixed files.

Output: emit the 3-SECTION REPORT (see below). After each package print a one-line tally.
```

#### Prompt B1 — orchestrator (Claude Code main thread; dispatches, does not edit)

```
ROLE: Orchestrator for repo-wide SonarQube safe auto-fix. You DISPATCH work; subagents edit.

SCOPE: [REPO_ROOT  or  list of packages]

Step 1 — read project config ONCE (pom.xml / build.gradle, all modules). Capture as SHARED CONTEXT:
  Java level · Lombok? · dominant logger · null-analysis/-Werror tooling.
  Pass this verbatim to every subagent (they must NOT re-read config).

Step 2 — partition work into DISJOINT WRITE SETS (one package = one work unit). A .java file
  belongs to exactly one package, so package units are disjoint by construction.
  Why this is safe (NOT because packages isolate dependencies — in all-public projects they
  don't): (a) disjoint write ownership — no two subagents ever edit the same file, so no
  write/merge conflicts; (b) no applied fix is cross-file — the API-preserving guards force
  SKIP on any fix that would touch a second file, so every applied fix stays in its own file.
  A subagent MAY read other packages (read-only) to evaluate a guard; it MUST NOT edit them.
  Package boundaries are chosen only for read-locality, not for isolation.

Step 3 — fan out: launch one subagent per package, concurrency capped (e.g. 4–6).
  Give each subagent: its package path · the SHARED CONTEXT · READ-ONLY access to the WHOLE
  repo (to resolve cross-file guards: supertypes, annotation definitions, callers in other
  packages) · the WORKER PROMPT (B2) + the RULES REFERENCE.
  A subagent may EDIT only files inside its own package. Never run two subagents on the same package.

Step 4 — collect each subagent's 3-section report.
Step 5 — run ONE serialized final step: build/compile the project. If it fails, surface the
  error; do NOT auto-fix further.
Step 6 — merge all reports into ONE 3-SECTION REPORT (see below), plus a header summary:
  | Package | Files | DONE | SKIPPED | NEEDS-REVIEW |
  Sort NEEDS-REVIEW by reason so the human backlog (PUBLIC-API / DOMAIN / AMBIGUOUS / CROSS-UNIT)
  is grouped and actionable.
```

#### Prompt B2 — worker (each subagent)

```
ROLE: Fix all SonarQube safe auto-fix issues in the package assigned to you.
EDIT only files inside your package. READ anything in the repo.
Use the SHARED CONTEXT you were given (Java level, Lombok, logger, build tooling); do NOT re-read config.

For each .java file in your package, one at a time:
  Read → apply categories in order:
    DEAD CODE → NAMING → CODE STYLE → NULL AND BOOLEAN → COLLECTIONS AND LOOPS →
    STRING → LAMBDA AND FUNCTIONAL → EXCEPTION HANDLING → CONCURRENCY → SERIALIZATION →
    ANNOTATIONS AND BOILERPLATE → SPRING → TEST QUALITY → SECURITY (MECHANICAL) → STRUCTURE
  → re-run DEAD CODE → save.

For EVERY occurrence, check the rule's GUARD first. When a guard depends on other files,
READ them (caller, subclass, supertype, overloaded method, annotation definition,
sibling package-info.java) and decide per the 3-SECTION REPORT rules below. Never guess intent.
If the only safe fix would require editing a file OUTSIDE your package, the guard already
mandates SKIP — record it as NEEDS-REVIEW (CROSS-UNIT), do not edit and do not hand it off.

HARD RULES: no public-API/signature change, no business-logic change, no half-fixed files.
Emit the 3-SECTION REPORT.
```

#### 3-SECTION REPORT (used by all three prompts above)

```
Produce exactly these three sections. Every detected issue (of the 69 safe rules) must land
in exactly ONE of them — never silently drop an occurrence. Excluded-rule issues are out of
scope and are not reported here.

1) DONE — fixes actually applied:
   | File:Line | Rule | Change (before → after) | Why safe (guard that HELD) |
   "Why safe" = the one-line reason the guard did NOT fire, e.g.
   "operand is primitive boolean", "method is private, all call sites updated".

2) SKIPPED-BY-GUARD — occurrence found, guard fired, and leaving the code as-is is the
   permanently-correct outcome (no API/domain issue; the code is fine):
   | File:Line | Rule | Guard that fired | Concrete reason |
   e.g. S1125 | Foo.java:12 | operand is boxed Boolean | "rewrite would change null/unboxing behavior".

3) NEEDS-REVIEW — occurrence found, not applied, because a legitimate fix exists but is
   OUTSIDE the safe / no-human posture. This is the human-review backlog:
   | File:Line | Rule | Why not done | What a serialized + reviewed pass would do |
   reason ∈ { PUBLIC-API change · DOMAIN knowledge · intent AMBIGUOUS · CROSS-UNIT edit }.
   e.g. S3066 | Order.java:21 | PUBLIC-API change (field read from billing.InvoiceService) |
        "narrow to private final and update external readers".

Decision rule between (2) and (3): "could a human legitimately finish this fix?"
  yes → NEEDS-REVIEW;  no, the code is correct as written → SKIPPED-BY-GUARD.

Keep reasons specific — always cite the symbol/file that triggered the guard, never just
"guard fired". End with a tally: "<scope> — DONE n, SKIPPED m, NEEDS-REVIEW k across F files".
```

\---

### 📦 CATEGORY PROMPTS — fix one type of issue at a time

```
Step 1 — read project config once (do not modify):
  Read pom.xml or build.gradle. Note Java version and Lombok presence.

Step 2 — for each .java file in \[FILE\_OR\_PATH], one at a time:
  Read → apply all rules from the \[CATEGORY NAME] section of the RULES REFERENCE → save → next file
  Print per file: "FileName.java — X fixes applied"
```

Replace `\[CATEGORY NAME]` with one of:  
`NAMING`  `DEAD CODE`
`NULL AND BOOLEAN`
`CODE STYLE`
`STRING`
`LAMBDA AND FUNCTIONAL`
`EXCEPTION HANDLING`
`COLLECTIONS AND LOOPS`
`CONCURRENCY`
`SERIALIZATION`
`ANNOTATIONS AND BOILERPLATE`
`SPRING`
`TEST QUALITY`
`SECURITY (MECHANICAL)`
`STRUCTURE`
---

### 🔀 PR PROMPT — fix SonarQube issues in current branch changes

```
Step 1 — read project config once (do not modify):
  Read pom.xml or build.gradle. Note Java version and Lombok presence.

Step 2 — discover changed files:
  Run: git diff main...HEAD --name-only

Step 3 — for each changed file, one at a time:
  Run: git diff main...HEAD -- \[filename]
  Read the full file.
  Apply all rules from the RULES REFERENCE ONLY to lines marked with + in the diff.
  Do NOT touch unchanged surrounding lines.
  Apply categories in the same order as FIX ALL (DEAD CODE first, STRUCTURE last).

Hard rules:
- Do NOT change public method signatures
- Do NOT fix pre-existing issues in unchanged lines
- If fix requires domain knowledge → skip and note it

After all files print:
| File | Line | Rule | Fix applied |
"X fixes applied across Y files. Ready for PR."

```

\---

### 📋 SONAR REPORT PROMPT — fix issues from a specific export

```
Step 1 — read project config once (do not modify):
  Read pom.xml or build.gradle. Note Java version and Lombok presence.

Step 2 — fix each issue one by one:

\[PASTE YOUR SONARQUBE ISSUE LIST HERE]
Format: OrderService.java:45 — java:S1128 — Remove unused import

For each issue:
1. Read the file (if not already open)
2. Navigate to the reported line
3. Apply the fix for the rule from the RULES REFERENCE
4. Confirm: "Fixed \[rule] in \[file]:\[line]"

Do NOT change anything beyond the specific issue on that line.
Save after all fixes in a file are done.
Print: list of fixed issues and any skipped with reason.
```

\---

## 📖 RULES REFERENCE

All prompts above reference a **RULES REFERENCE** — the full list of 69 categorised SonarQube rules, every one a safe, fully-automatic auto-fix.

The rules live in a separate file:

```
sonarqube-ai-fix-prompts-rules.md
```

### How to supply the rules to the AI

#### Option A — Attach the file manually (any tool, quickest)

Paste or attach `sonarqube-ai-fix-prompts-rules.md` directly into the chat alongside the prompt you choose.
Both GitHub Copilot Chat and Claude Code accept file attachments / `@file` references.

#### Option B — GitHub Copilot: workspace instructions file

Add the rules as a persistent instruction so Copilot always has them in context:

1. Create (or edit) `.github/copilot-instructions.md` at the root of your repository.
2. Paste the full content of `sonarqube-ai-fix-prompts-rules.md` into that file (or add an `@file` reference if your Copilot version supports it).
3. Copilot Chat will automatically pick up `.github/copilot-instructions.md` for every conversation in that workspace — no need to attach the file each time.

> 📄 Official docs: \[Customizing GitHub Copilot in your organisation](https://docs.github.com/en/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot)

#### Option C — Claude Code: `CLAUDE.md` project memory file

Claude Code reads `CLAUDE.md` (and any `CLAUDE.md` in sub-directories) automatically at the start of every session:

1. Create `CLAUDE.md` at the root of your repository (or in the relevant sub-directory).
2. Paste the full content of `sonarqube-ai-fix-prompts-rules.md` into it, or add a note like:

```
   See sonarqube-ai-fix-prompts-rules.md for the SonarQube RULES REFERENCE.
   ```

3. Claude will treat the rules as persistent project context without requiring a manual attachment.

> 📄 Official docs: \[Claude Code — Project memory (CLAUDE.md)](https://docs.anthropic.com/en/docs/claude-code/memory)

#### Option D — Keep prompts self-contained (copy-paste)

Append the full content of `sonarqube-ai-fix-prompts-rules.md` at the end of whichever prompt you send.
This is the most portable option and works with any AI tool without any setup.

\---

