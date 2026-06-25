## SonarQube — AI Fix Prompts for Java

## Fix SonarQube issues automatically with Claude Code or GitHub Copilot

### How to use

📄 For overview, use cases, and time-saving stats see `sonarqube-ai-fix-prompts-info.md`

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
  - Java version (S6204 requires Java 16+, S6218 pattern matching requires Java 16+)
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

  Within each category: apply AUTO-FIX rules first, then FLAG-ONLY rules.
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

### 📦 CATEGORY PROMPTS — fix one type of issue at a time

```
Step 1 — read project config once (do not modify):
  Read pom.xml or build.gradle. Note Java version and Lombok presence.

Step 2 — for each .java file in \[FILE\_OR\_PATH], one at a time:
  Read → apply all rules from the \[CATEGORY NAME] section of the RULES REFERENCE → save → next file
  Within the category: apply AUTO-FIX rules first, then FLAG-ONLY rules.
  Print per file: "FileName.java — X fixes applied, Y flagged"
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
  Within each category: AUTO-FIX rules first, then FLAG-ONLY rules.

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

All prompts above reference a **RULES REFERENCE** — the full list of categorised SonarQube rules with auto-fix (`\[A]`) and flag-only (`\[F]`) annotations.

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
   See temp/sonarqube-ai-fix-prompts-rules.md for the SonarQube RULES REFERENCE.
   ```

3. Claude will treat the rules as persistent project context without requiring a manual attachment.

> 📄 Official docs: \[Claude Code — Project memory (CLAUDE.md)](https://docs.anthropic.com/en/docs/claude-code/memory)

#### Option D — Keep prompts self-contained (copy-paste)

Append the full content of `sonarqube-ai-fix-prompts-rules.md` at the end of whichever prompt you send.
This is the most portable option and works with any AI tool without any setup.

\---

