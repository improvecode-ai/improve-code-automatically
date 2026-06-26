# Claude Code — SAFE Refactoring Prompts

These prompts contain **only refactorings that do not change runtime behavior** — they are
designed to run **automatically, with minimal or no human review**. Every rule here either
cannot change behavior, or is constrained by a guard so that it cannot.

Anything that *can* change behavior, serialization, or test outcomes — even when it usually
won't — lives in the companion file `claude-code-refactor-prompts-aggressive.md`. When a rule
below has a higher-risk sibling, it is cross-referenced as **→ AGGRESSIVE file**.

Each category has two prompts:
- **EDUCATIONAL** — dry run only, shows findings as a table, explains *why*, touches nothing
- **SAFE** — applies the change, zero behavior change

Replace `[PACKAGE_PATH]` with a real path, e.g. `src/main/java/com/example/order`.

---

## ✅ Verification gate (run this as part of every SAFE prompt)

```
Process one category at a time. After applying a category to all files in [PACKAGE_PATH]:
  1. Compile: mvn -q compile test-compile   (or: ./gradlew compileJava compileTestJava)
  2. If compilation FAILS:
     - git checkout -- [PACKAGE_PATH]   (revert the whole category)
     - Report which file/edit caused the failure
     - STOP — do not continue to the next category
  3. If compilation SUCCEEDS: continue.

Why compile-only (no test run) is sufficient here:
SAFE rules change no runtime behavior by design, so passing tests cannot start failing.
The only realistic failure mode is the model misjudging scope (e.g. marking a reassigned
variable final, removing an import that was actually used) — and every one of those is a
COMPILE error, which this gate catches and reverts. Running the test suite is reserved for
the AGGRESSIVE file, where behavior can change.
```

---

## 🏷️ 1. NAMING
**Strategy: file-by-file** — naming decisions are local to one file
**SAFE scope: local variables and parameters only.** Field, constant, and method renames can
break serialization / reflection / public API → **AGGRESSIVE file**.

### EDUCATIONAL
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find naming issues on LOCAL VARIABLES and PARAMETERS only:
   - Abbreviated names (usr, mgr, cfg, d, s, f, tmp, res)
   - Boolean locals/params not phrased as questions (active → isActive, valid → isValid)
3. Output findings as a table: File | Line | Type | Before | After | Why
4. Note (do not act on) field/constant/method names — these are handled in the AGGRESSIVE file.
5. Do NOT modify any file. Move to next file.

At the end: "Found X safe naming issues (locals/params) in Y files."
Explain once: "A name should describe intent. Abbreviations force the reader to decode;
boolean question-form (isActive) reads as a predicate at the call site."
```

### SAFE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply, to LOCAL VARIABLES and METHOD PARAMETERS only:
   - Expand abbreviated names — infer the full name from type and usage context
   - Rename booleans to question form (active → isActive)
3. Print: "FileName.java — changed X names: [old→new]"
4. Save. Move to next file.

Hard rules (these make the rename behavior-safe):
- ONLY local variables and method parameters. NEVER fields, constants, methods, or anything public.
- GUARD — skip the rename if the new name would:
  (a) match the name of any FIELD in scope (would shadow the field and silently change behavior)
  (b) match an existing local/parameter in the same scope
  (c) be ambiguous — if intent is unclear, skip and leave a one-line note
```

---

## 🔀 2. LOGIC (Simplifying conditions)
**Strategy: file-by-file** — logic simplifications are purely local

### EDUCATIONAL
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find:
   - if (x) return true; else return false; patterns
   - if (x == true) / if (x == false) / if (x != true) comparisons
   - Double negations: if (!isNotActive)
3. Output as table: File | Line | Pattern | Before | After | Rule
4. Do NOT modify. Move to next file.

Explain once: "Comparing a boolean to true/false is redundant — the boolean IS the condition.
Returning a boolean directly removes a branch the reader has to trace."
```

### SAFE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply only these mechanical simplifications:
   - if (x) return true; else return false; → return x;
   - if (x == true) → if (x)
   - if (x == false) → if (!x)
   - if (x != true) → if (!x)
   - Double negation: if (!isNotActive) → if (isActive) — ONLY if isActive already exists in scope
3. Print: "FileName.java — X simplifications applied"
4. Save. Move to next file.

Hard rules:
- GUARD — apply the "return true/false → return x" rewrite ONLY when x is a primitive boolean
  and the method returns primitive boolean. If x is a boxed Boolean (or the return type is
  Boolean), skip it — the rewrite would change null/unboxing behavior.
- Do NOT touch guard clauses (early returns with real business logic)
- Do NOT extract conditions to variables (naming judgment → AGGRESSIVE file)
- Do NOT change any method signatures
```

---

## 🧱 3. CODE STRUCTURE
**Strategy: file-by-file**
**Note:** deleting `System.out` and converting lambdas to method references can change behavior
→ **AGGRESSIVE file**. SAFE keeps only the no-behavior-change parts.

### EDUCATIONAL
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find:
   - Numeric literals (except 0, 1, -1) not assigned to a named constant
   - String literals appearing 3+ times that clearly mean the same thing
   - Unused imports (not referenced in code OR in Javadoc {@link}/@see)
3. Output as table: File | Line | Issue | Before | After
4. Do NOT modify. Move to next file.
```

### SAFE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply:
   - Remove unused imports
     GUARD: keep any import still referenced in Javadoc ({@link}, {@linkplain}, @see, @throws)
   - Extract numeric literals (except 0, 1, -1) to private static final constants at top of class
     Name them based on usage context
   - Extract string literals appearing 3+ times to private static final String constants
     GUARD: only when every occurrence clearly denotes the SAME concept; if any occurrence
     might mean something different, leave them all alone
3. Print: "FileName.java — removed X imports, extracted Y constants, Z string constants"
4. Save. Move to next file.

Hard rules:
- Do NOT remove System.out (behavior/test/CLI risk → AGGRESSIVE file)
- Do NOT convert lambdas to method references (capture-timing/overload risk → AGGRESSIVE file)
- Do NOT remove unused private methods or fields (may be used via reflection → AGGRESSIVE file)
- Do NOT reorder class members (init-order risk → AGGRESSIVE file)
```

---

## 🔒 4. NULL SAFETY
**Strategy: file-by-file**
**SAFE adds documentation annotations only.** Replacing `return null` with an empty collection
changes behavior → **AGGRESSIVE file**.

> **Annotation library:** JetBrains `org.jetbrains.annotations.@NotNull` / `@Nullable` —
> documentation / IDE / static-analysis contracts only, **NOT enforced at runtime**.

### EDUCATIONAL
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find:
   - Method parameters used without a null check and missing @NotNull
   - Method parameters with an explicit null check and missing @Nullable
   - Return types whose method has at least one "return null" (Nullable candidate)
3. Output as table: File | Line | Issue | Before | After | Contract
4. Do NOT modify. Move to next file.

Explain once: "These annotations document a contract for the IDE and static analysis. They are
NOT checked at runtime — nothing is thrown. Runtime enforcement (requireNonNull) is AGGRESSIVE."
```

### SAFE
```
PREFLIGHT (once): read pom.xml / build.gradle. Is org.jetbrains:annotations a dependency?
  - If NO: do not add any annotation (it would not compile). Report:
    "Skipped null-safety annotations — org.jetbrains:annotations is not on the classpath."
    Stop this category.
  - If YES: continue.

For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply:
   - Add @NotNull to parameters used directly without a null check
   - Add @Nullable to parameters that have an explicit null check (if param == null)
   - Add @NotNull to a return type if the method has no "return null"
   - Add @Nullable to a return type if the method has at least one "return null"
3. Print: "FileName.java — added X @NotNull, Y @Nullable"
4. Save. Move to next file.

Hard rules:
- Use org.jetbrains.annotations.@NotNull / @Nullable (added in PREFLIGHT only if already present)
- These are NOT runtime-enforced — SAFE changes zero runtime behavior
- Do NOT add Objects.requireNonNull (→ AGGRESSIVE file)
- Do NOT replace "return null" with empty collections (→ AGGRESSIVE file)
- Do NOT change Optional return types
```

---

## 🧊 5. IMMUTABILITY
**Strategy: single-pass per file** — final on locals/params is compiler-verified
**SAFE scope: local variables and parameters only.** final on fields/classes → **AGGRESSIVE file**.

### EDUCATIONAL
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find variables eligible for final:
   - Local variables assigned exactly once, never reassigned
   - Method parameters never reassigned inside the method body
3. Output as table: File | Line | Variable | Type (local/param)
4. Do NOT modify. Move to next file.

Explain once: "final on a local/parameter is fully checked by the compiler — if it were wrong,
the build would fail, so it can never silently change behavior."
```

### SAFE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Add final to:
   - Every local variable assigned exactly once and never reassigned
   - Every method parameter never reassigned inside the method body
3. Print: "FileName.java — added final to X local variables, Y parameters"
4. Save. Move to next file.

Hard rules:
- Do NOT add final to fields (framework/reflection risk → AGGRESSIVE file)
- Do NOT add final to classes (proxy/mock risk → AGGRESSIVE file)
- Do NOT add final to variables in catch blocks
- Do NOT add final to loop variables (for, for-each, while)
```

---

## 🧹 6. FORMATTING AND STYLE
**Strategy: file-by-file** (SAFE needs no cross-file scan)
Logger unification and whitespace normalization → **AGGRESSIVE file**.

### EDUCATIONAL
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find:
   - Import ordering issues (unsorted, unused)
   - Methods missing blank-line grouping (validation block / logic block / return)
3. Output as table: File | Issue | Line | Before | After
4. Do NOT modify. Move to next file.
```

### SAFE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply:
   - Sort imports: static first, then java.* , javax.* , org.* , com.* , then project packages
   - Remove unused imports (keep Javadoc-referenced ones)
   - Add blank lines to separate logical method sections where clearly missing:
     (1) parameter validation  (2) business logic  (3) return
     — add blank lines only, NEVER remove existing ones
3. Print: "FileName.java — sorted imports, added X blank lines"
4. Save. Move to next file.

Hard rules:
- Do NOT reformat indentation or change line lengths
- Do NOT touch System.out or loggers (→ Code Structure / AGGRESSIVE file)
- Do NOT remove trailing whitespace or normalize blank lines
  (would corrupt text blocks """ → AGGRESSIVE file)
```

---

## ⚠️ 7. EXCEPTIONS
**Strategy: file-by-file**
**SAFE logs empty catches only when a logger already exists** (no new dependency). Adding a new
logger, or narrowing catch types, → **AGGRESSIVE file**.

### EDUCATIONAL
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find:
   - Empty catch blocks (body empty or comment-only)
   - Unnecessary casts where the variable's declared type already equals the cast target
3. Output as table: File | Line | Issue | Before | After | Risk
4. Do NOT modify. Move to next file.

Explain once: "An empty catch hides failures. A cast to a type the variable already has adds
noise. Removing such a cast is safe because the static type — and so overload resolution —
is unchanged."
```

### SAFE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply:
   - For empty catch blocks: ONLY if a logger (log, logger, LOG) ALREADY exists in the class,
     add: log.warn("Unexpected {}: {}", e.getClass().getSimpleName(), e.getMessage(), e);
     If NO logger exists, leave the catch unchanged and note it (adding a logger → AGGRESSIVE file).
   - Remove unnecessary casts where the variable's declared type already equals the cast target
     GUARD: only when the cast target type is identical to the variable's declared static type
     (so overload resolution cannot change)
3. Print: "FileName.java — logged X empty catches, removed Y unnecessary casts, skipped Z (no logger)"
4. Save. Move to next file.

Hard rules:
- Do NOT add a new logger / dependency (→ AGGRESSIVE file)
- Do NOT narrow catch(Exception) (→ AGGRESSIVE file)
- Do NOT convert finally to try-with-resources
- Do NOT change exception types being thrown
```

---

## 🧩 8. ANNOTATIONS AND BOILERPLATE
**Strategy: file-by-file** — @Override is compiler-verified
Constructor generation and Lombok conversion → **AGGRESSIVE file**.

### EDUCATIONAL
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find methods that override a superclass method or implement an interface method but are
   missing @Override
3. Output as table: File | Line | Method | Missing annotation
4. Do NOT modify. Move to next file.

Explain once: "@Override is a compile-time safety net. If the parent method is renamed or its
signature changes, the compiler immediately flags the orphaned override. Adding it cannot change
behavior — if it were wrong, the code would not compile."
```

### SAFE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Add @Override to every method that overrides a superclass method OR implements an interface
   method, where @Override is currently missing
3. Print: "FileName.java — added @Override to X methods: [names]"
4. Save. Move to next file.

Hard rules:
- Do NOT generate constructors (→ AGGRESSIVE file)
- Do NOT add any Lombok annotations (→ AGGRESSIVE file)
- Do NOT modify existing annotations
```

---

## 🔧 9. LOOPS AND COLLECTIONS
**Strategy: single-pass per file**
**for→for-each conversion can throw ConcurrentModificationException** → **AGGRESSIVE file**.
SAFE keeps only the equivalent-result rewrites.

### EDUCATIONAL
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find:
   - size() == 0 / size() > 0 comparisons (isEmpty() candidate)
   - Collections.sort(list) calls (list.sort(null) / list.sort(comparator) candidate)
   - Missing diamond operator: new ArrayList<String>() (new ArrayList<>() candidate)
3. Output as table: File | Line | Pattern | Before | After
4. Do NOT modify. Move to next file.
```

### SAFE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply:
   - size() == 0 → isEmpty()
   - size() > 0  → !isEmpty()
   - Collections.sort(list) → list.sort(null); Collections.sort(list, c) → list.sort(c)
   - Add diamond operator: new ArrayList<String>() → new ArrayList<>()
     GUARD: skip anonymous-class instantiations (new ArrayList<String>(){...}) unless the
     project targets Java 9+ (diamond on anonymous classes is illegal before Java 9)
3. Print: "FileName.java — X isEmpty(), Y sort(), Z diamond ops"
4. Save. Move to next file.

Hard rules:
- Do NOT convert indexed loops to for-each (ConcurrentModificationException risk → AGGRESSIVE file)
- Do NOT convert any loops to streams (→ AGGRESSIVE file)
- Do NOT add generics to raw types (type inference → AGGRESSIVE file)
```

---

## 💬 10. COMMENTS
**Strategy: file-by-file**

### EDUCATIONAL
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find:
   - Inline comments that describe WHAT the next line does (// increment counter, // call service)
   - Commented-out code blocks
3. Output as table: File | Line | Type | Comment text | Verdict
4. Do NOT modify. Move to next file.

Explain once: "A comment describing WHAT signals the code needs a better name, not a better
comment. Removing it is safe — comments do not affect compilation or runtime — UNLESS the comment
is actually a tool directive (see guard below)."
```

### SAFE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply:
   - Remove inline comments that only describe what the very next line does
   - Remove commented-out code blocks (consecutive lines starting with //)
3. For every removal, print: "Removed from FileName.java:LINE — [comment text]"
4. Save. Move to next file.

Hard rules — NEVER remove:
- Tool directives, even if they look like throwaway comments:
  // NOSONAR, // noinspection..., // @formatter:off, // @formatter:on,
  // CHECKSTYLE:OFF, // CHECKSTYLE:ON, //$NON-NLS-1$ (and $NON-NLS-N$), // PMD...
  (removing these can FAIL a CI quality gate)
- Javadoc comments (/** ... */)
- Comments explaining WHY (business reason, workaround, limitation)
- TODO or FIXME tags
- License headers
```

---

## 🧪 11. TESTS
**Strategy: single-pass per file**

### EDUCATIONAL
```
For each test .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find:
   - assertEquals(true, x)  → assertTrue(x)
   - assertEquals(false, x) → assertFalse(x)
   - assertEquals(null, x)  → assertNull(x)
   - assertNotEquals(null, x) → assertNotNull(x)
3. Output as table: File | Line | Before | After | Why
4. Do NOT modify. Move to next file.

Explain once: "assertTrue(x) reads as a sentence and gives a clearer failure message than
assertEquals(true, x). These are pure renamings of equivalent JUnit assertions."
```

### SAFE
```
For each test .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply:
   - assertEquals(true, x)     → assertTrue(x)
   - assertEquals(false, x)    → assertFalse(x)
   - assertEquals(null, x)     → assertNull(x)
   - assertNotEquals(null, x)  → assertNotNull(x)
   GUARD: ensure the matching static import exists (e.g. import static org.junit.jupiter.api.
   Assertions.assertTrue;). If it is missing, ADD it — otherwise the file will not compile.
3. Print: "FileName.java — X assertions modernized"
4. Save. Move to next file.

Hard rules:
- Apply to JUnit 4 / JUnit 5 assertions only
- Do NOT change AssertJ (assertThat) or Hamcrest assertions (→ AGGRESSIVE file)
- Do NOT change existing assertion failure messages
```

---

## 🎯 MEGA PROMPTS (SAFE)

### EDUCATIONAL (full scan, no changes)
```
Perform a full SAFE-tier quality scan of [PACKAGE_PATH].
Process files one at a time: read → scan → move on. Do NOT modify any file.

Scan (SAFE-tier only):
1. Naming — abbreviations / non-question booleans on LOCALS and PARAMS only
2. Logic — boolean-return simplification, x==true/false/!=true, double negation
3. Structure — magic numbers, repeated same-concept strings, unused imports
4. Null safety — missing @NotNull/@Nullable (documentation only)
5. Immutability — final candidates (locals and params only)
6. Formatting — blank-line grouping, import order
7. Exceptions — empty catches (logger already present), unnecessary same-type casts
8. Boilerplate — missing @Override
9. Collections — isEmpty(), Collections.sort→list.sort, diamond operator
10. Comments — what-comments, commented-out code (excluding tool directives)
11. Tests — assertEquals(true/false/null) patterns

Output per finding: | Category | File | Line | Before | After | Why |
Final: "Scanned X files. Found Y SAFE-tier issues. Higher-risk findings → see AGGRESSIVE file."
```

### SAFE (full refactor, file-by-file)
```
Apply all SAFE refactoring to [PACKAGE_PATH]. This is the complete SAFE tier — every operation
below is behavior-preserving (or guarded so it cannot change behavior).

PREFLIGHT (read once, do not modify): pom.xml / build.gradle —
  - Is org.jetbrains:annotations present? (gates step 13)
  - Java version (gates the diamond-on-anonymous-class guard)

Process files one at a time, in this order per file:
  1. Remove unused imports (keep Javadoc-referenced)
  2. Sort imports (static → java → javax → org → com → project)
  3. Add blank-line grouping inside methods (add only, never remove)
  4. Add @Override to eligible methods
  5. size()==0 → isEmpty(); size()>0 → !isEmpty()
  6. Add diamond operator (skip anonymous classes unless Java 9+)
  7. Collections.sort(list) → list.sort(null); Collections.sort(list, c) → list.sort(c)
  8. Simplify boolean returns (primitive boolean only) and x==true/false/!=true
  9. Double negation → positive form (only if the positive name exists in scope)
  10. final on local variables and parameters
  11. Rename LOCALS and PARAMS only — expand abbreviations, boolean→question form
      (skip if the new name shadows a field or collides with an existing local)
  12. Extract magic numbers to private static final constants
  13. Extract repeated (same-concept) string literals to constants
  14. Add @NotNull/@Nullable (JetBrains, documentation-only) — ONLY if PREFLIGHT found the dependency
  15. Log empty catch blocks — ONLY if a logger already exists in the class
  16. Remove unnecessary same-type casts
  17. Remove what-comments and commented-out code (NEVER tool directives)
  18. Fix assertEquals(true/false/null) in test files (add the static import if missing)

After EACH file's category pass, and at the end, run the Verification gate (compile + revert).

Hard rules:
- Do NOT touch public API signatures (public/protected methods, fields, interfaces)
- Do NOT touch fields at all (no field rename, no final on fields)
- Do NOT delete System.out, convert lambdas to method refs, convert loops to for-each/streams,
  replace null returns with empty collections, narrow catch(Exception), add Lombok, add new
  dependencies, or generate constructors — all of those live in the AGGRESSIVE file
- @NotNull/@Nullable are documentation only (no requireNonNull in SAFE)
```
