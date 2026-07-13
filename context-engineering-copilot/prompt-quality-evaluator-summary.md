# Prompt Quality Evaluator v2.2

## Tags
prompt-engineering, ai-tools, productivity, quality-check, custom-instructions

---

## Markdown version

### What it is

A system prompt you paste once at the start of a conversation (or into Custom Instructions in Claude/ChatGPT). It makes the model evaluate your prompt against 6 common mistakes *before* executing your task:

- ✅ **Good** (0 issues) → executes normally
- ⚠️ **Minor fix** (1 issue) → executes, adds a one-line suggestion
- ❌ **Needs improvement** (2+ issues) → doesn't execute yet, shows what's wrong with your prompt and a complete, ready-to-use improved version

Works in Claude, ChatGPT, Copilot, and Gemini — paste location varies (Custom Instructions for Claude/ChatGPT, start of conversation for Copilot/Gemini).

### 6 Most Common Mistakes When Asking AI (the basis for the evaluator)

1. **No context** — Treating AI like a search engine (typing "diet" instead of a real instruction). The model doesn't know exactly what you need or what the output will be used for. Fix: state what you need and what it's for.

2. **No perspective** — The model doesn't know what language level or audience to write for, so answers come out generic. Fix: describe the language level and reader (e.g., "explain simply, no jargon, for someone non-technical") instead of giving a job title.

3. **No examples** — Saying "write in my style" without providing samples is useless — the model guesses. Fix: paste 2-3 examples of the style/format you want.

4. **Hallucination risk** — AI states wrong facts (numbers, dates, sources) with full confidence. Fix: add "if you're not sure, say 'needs verification' instead of guessing" to prompts requiring specific data.

5. **Conflicting instructions** — Contradictory asks ("be concise but thorough") or mixing data with commands without separation. Fix: use tags like `<document>...</document>` and `<instruction>...</instruction>` to separate data from the task.

6. **No output format** — Not specifying list vs. paragraph, length, number of points leads to mismatched results. Fix: always specify the exact format you want.

### Bonus tips

- Always verify AI-generated facts/numbers/sources before using them.
- Treat the first response as a draft — iterate with follow-ups instead of starting over.

---

## Plain text version

PROMPT QUALITY EVALUATOR V2.2

TAGS: prompt-engineering, ai-tools, productivity, quality-check, custom-instructions

WHAT IT IS

A system prompt you paste once at the start of a conversation (or into Custom Instructions in Claude/ChatGPT). It makes the model evaluate your prompt against 6 common mistakes before executing your task:

- ✅ Good (0 issues) -> executes normally
- ⚠️ Minor fix (1 issue) -> executes, adds a one-line suggestion
- ❌ Needs improvement (2+ issues) -> doesn't execute yet, shows what's wrong with your prompt and a complete, ready-to-use improved version

Works in Claude, ChatGPT, Copilot, and Gemini. Paste location varies: Custom Instructions for Claude/ChatGPT, start of conversation for Copilot/Gemini.

6 MOST COMMON MISTAKES WHEN ASKING AI (the basis for the evaluator)

1. No context
Treating AI like a search engine (typing "diet" instead of a real instruction). The model doesn't know exactly what you need or what the output will be used for.
Fix: state what you need and what it's for.

2. No perspective
The model doesn't know what language level or audience to write for, so answers come out generic.
Fix: describe the language level and reader (e.g., "explain simply, no jargon, for someone non-technical") instead of giving a job title.

3. No examples
Saying "write in my style" without providing samples is useless - the model guesses.
Fix: paste 2-3 examples of the style/format you want.

4. Hallucination risk
AI states wrong facts (numbers, dates, sources) with full confidence.
Fix: add "if you're not sure, say 'needs verification' instead of guessing" to prompts requiring specific data.

5. Conflicting instructions
Contradictory asks ("be concise but thorough") or mixing data with commands without separation.
Fix: use tags like <document>...</document> and <instruction>...</instruction> to separate data from the task.

6. No output format
Not specifying list vs. paragraph, length, number of points leads to mismatched results.
Fix: always specify the exact format you want.

BONUS TIPS

- Always verify AI-generated facts/numbers/sources before using them.
- Treat the first response as a draft - iterate with follow-ups instead of starting over.
