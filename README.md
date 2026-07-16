# improve-code-automatically
# Improve your code automatically with AI

AI tools that help you to improve Java code quality —
safely, predictably, and without breaking anything.

Every bundle here follows the same principle: **AI applies the fix, a mechanical gate (compile
and/or tests) verifies it, and only what genuinely needs a human gets flagged for review** — never
the other way around.

---

## What's inside

### [sonarqube/](./sonarqube/)

AI-fix prompts for SonarQube Java rules — 69 safe, fully-automatic rules across 15 categories
(out of 278 reviewed), for Claude Code and GitHub Copilot. Paste a prompt, review the diff,
commit. The other 209 rules are documented with reasons in `sonarqube/excluded/`.

### [java-fully-safe-automated-code-improvement/](./java-fully-safe-automated-code-improvement/)

General Java refactoring prompts (naming, logic, immutability, collections, tests, …) beyond what
SonarQube flags — split into a **SAFE** tier that runs fully automatically behind a compile-gate
with auto-revert, and an **AGGRESSIVE** tier that can change behavior and requires a branch, a
full test run, and a diff review.

### [coding-prompt-quality-gate-claude-code/](./coding-prompt-quality-gate-claude-code/)

A self-checking gate that gets in front of *your* prompts, not the code: before Claude Code acts
on a coding request, it checks it against 6 prompt-quality rules and pushes back with the gaps
plus a stronger version if something important is missing. Enforced via a `UserPromptSubmit` hook
that fires on every prompt.

### [coding-prompt-quality-gate-copilot/](./coding-prompt-quality-gate-copilot/)

The same prompt-quality gate, adapted for GitHub Copilot in JetBrains IDEs / VS Code via
`.github/copilot-instructions.md` and scoped instruction files. A softer, model-enforced version
of the Claude Code bundle above, since Copilot has no equivalent hook mechanism.

### [context-engineering-claude-code/](./context-engineering-claude-code/)

Token- and cost-saving guardrails for Claude Code: model selection, conciseness, "think in code",
targeted file references, CLI-over-MCP. Unlike the Copilot sibling, this bundle actually **forces**
what can be forced — `PreToolUse` hooks deny raw log/file dumps, a live statusline shows real
context-window %, and a cheap Haiku subagent handles search/lookups.

### [context-engineering-copilot/](./context-engineering-copilot/)

The same context-engineering goals (model selection, conciseness, session hygiene) for GitHub
Copilot, plus a standalone Prompt Quality Evaluator. Since Copilot has no hook system, every rule
here is advisory — the companion doc grades each one on whether it can realistically hold.

---

## Philosophy

Prefer mechanical verification over trust, and trust over ceremony: a change that can't change
behavior ships with a compile check; a change that can ships behind tests and a diff review.
Nothing here asks a human to review what a gate can already verify.

More at [improvecode.ai](https://improvecode.ai)

---

*improvecode.ai — code quality for the AI era*
