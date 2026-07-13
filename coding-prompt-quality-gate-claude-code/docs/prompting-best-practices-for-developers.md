# Prompting Best Practices for Developers

A vague prompt produces a vague (or wrong) result — and the cost isn't just one bad answer, it's the time spent reviewing, rejecting, and re-prompting. This guide gives you a quick mental checklist before you hit enter, then explains each part, plus the techniques and task-specific traps worth knowing.

> This doc is the **source of truth** for the Claude Code prompt-quality gate (`CLAUDE.md`, `.claude/settings.json`, `.claude/skills/`, and `.claude/commands/`). Those files are derived from these rules — keep them in sync when the rules here change.

---

## Quick Reference Template

For any non-trivial prompt, run through this. Each part is explained in the sections below.

> [**Single** task] + [**Specific** criteria & constraints] + [**Surrounding** context — files/patterns to reference] + [Output format] — keep it **Short**.

**Combined example:**
> In `OrderProcessor.process()`, fix the bug where discounts stack when an order has multiple coupons (single task). Only one discount should apply per order, the highest-value coupon (specific criteria). Follow the discount-resolution pattern used in `CartService.ts` (surround). Return the change as a diff with a one-line explanation (output format).

---

## The 4S Framework

A simple checklist for any prompt: **Single, Specific, Short, Surround.**

### Single — one task per prompt

If your prompt contains "and also...", split it. A prompt that asks for a refactor *and* new tests *and* updated docs in one go makes it hard for the AI to do any of the three well, and hard for you to review the result.

*Weaker:*
> Update the user module — fix the validation bug, add tests, and clean up the imports.

*Stronger:*
> In `user.ts`, fix the bug where `validateEmail()` accepts addresses without a TLD (e.g. `user@domain`).

(Run the tests and the cleanup as separate prompts.)

### Specific — explicit criteria, not just an action

This is where most prompt quality is won or lost. "Refactor this class" describes an action but not a target — the AI will pick its own definition of "better." Give it the criteria you'd use to judge the result yourself.

*Weaker:*
> Refactor this class.

*Stronger:*
> Refactor `OrderProcessor` to reduce cyclomatic complexity in `process()` below 10. Extract validation logic into a separate `OrderValidator` class. Keep the public method signatures unchanged.

"Specific" also covers things only you know: coding standards, constraints (no new dependencies, must stay compatible with X), and what should explicitly *not* change.

### Short — specific doesn't mean wordy

A tight bullet list of requirements is easier for the AI to parse — and for you to scan afterward — than a paragraph of prose saying the same thing.

*Weaker:*
> I'd like you to take a look at this function and see if there's a way to make it faster, since right now it's looping through the array multiple times which seems inefficient, and also it would be nice if it handled the empty-array case better.

*Stronger:*
> Optimize `calculateTotals()`:
> - Single pass instead of multiple loops
> - Handle empty array → return `0`, not `NaN`

### Surround — give it context beyond the prompt text

The AI often sees more than your prompt: open editor tabs, file names, and recently edited code all become context. Use that deliberately.

- Keep the files you're referencing open in the editor.
- Use descriptive file/function names — they're free context.
- Point at existing patterns by name: *"follow the same error-handling pattern as `PaymentService.ts`"* rather than re-describing it.

---

## Beyond the 4S

### Show an example instead of describing the pattern

One well-chosen example of the style or structure you want is often worth more than a paragraph describing it — the AI pattern-matches from concrete examples very effectively. This is especially useful for boilerplate, test scaffolding, or repetitive implementations.

> Add a `deleteOrder()` method to `OrderRepository`, following the same try/catch + logging pattern as `updateOrder()` above it.

### Specify the output format

"Fix this bug" can come back as a full rewrite, a diff, an explanation with no code, or code with no explanation — say which one you want.

> Fix this bug. Return only the changed lines as a diff, with a one-sentence explanation of the root cause above it. Don't reformat unrelated code.

### Iterate with specific feedback

The first response is often a draft, not a final answer — that's normal. Rather than "try again," give feedback as specific as a code review comment, so the next attempt builds on what was right instead of starting over.

*Weaker:*
> No, not like that. Try again.

*Stronger:*
> Close — but `OrderValidator.validate()` should throw `ValidationError` (not return `false`), matching the pattern in `PaymentValidator`. Otherwise this looks good, keep the rest as is.

### Give perspective, not a persona

It's tempting to write "act as a security expert." In current models this does less than it used to — a job title doesn't add much the model can act on. What helps is naming the *goal* and *what to check for*, which is concrete enough to steer the output.

*Weaker:*
> Acting as a security expert, review this login handler.

*Stronger:*
> Review this login handler for security problems — specifically SQL injection, timing attacks on the password compare, and weak session handling. List each issue found and the fix.

---

## Task-Specific Pitfalls

The 4S framework covers prompts in general, but two tasks have their own failure modes worth knowing specifically.

### Hunting for bugs — turn "find the bug" into a structured review

An open-ended "find the bug" prompt can work, but on tricky issues the AI may latch onto the first plausible-looking thing instead of the real cause. A structured request gets more reliable results — and often surfaces the bug to *you* before the AI even proposes a fix.

*Weaker:*
> Find the bug in this file.

*Stronger:*
> Review `calculateDiscount()` for bugs:
> 1. Summarize what it currently does, in plain language
> 2. List its inputs, outputs, and any side effects
> 3. Flag any bugs with severity (low/medium/high) and why
> 4. Propose the smallest possible fix for each
> 5. Add 2–3 tests that would catch each bug if it recurred

This also leans on "Single" from earlier: scope the review to the function or file you actually suspect, not the whole codebase. Pasting 500 lines and saying "fix the bug" makes it more likely the AI "fixes" something unrelated and misses the real issue.

### Writing tests — describe the behavior, not "this code"

This is the task where a sloppy prompt does the most quiet damage. "Write unit tests for this function" doesn't ask the AI to verify correctness — it asks it to describe what the code *currently does*, bugs included. The result can be a fully green test suite that locks in broken behavior.

*Weaker:*
> Write unit tests for this function.

*Stronger — requirements first:*
> Write unit tests for `validateCoupon()`. It should:
> - Return `valid: false` for expired coupons
> - Return `valid: false` for coupons used more than `maxUses` times
> - Return `valid: true` plus the discount amount otherwise
>
> Here's the current implementation: [paste code]
> If the implementation doesn't match these rules, flag it — don't write a test that just confirms the current (possibly wrong) behavior.

A few extra guardrails for test prompts:

- Don't ask for "100% coverage" as the goal — it's easy to hit with tests that don't assert anything meaningful. Ask for specific *cases* instead (happy path, empty input, expired/invalid state, etc.).
- Treat the output as a draft. For each test, ask: "if the implementation were wrong, would this test actually fail?" If not, it isn't testing anything.
- For critical logic (payments, auth, access control), write the test *scenarios* yourself first — even just a list of names — and have the AI fill in the implementation. That keeps you, not the AI, in charge of "what correct looks like."

---

## The Core Mindset

Treat the AI like a capable contractor who joined the team this morning: smart and fast, but with zero context about your codebase's history, conventions, or your personal definition of "done." Every assumption you don't write down is a guess they have to make instead.
