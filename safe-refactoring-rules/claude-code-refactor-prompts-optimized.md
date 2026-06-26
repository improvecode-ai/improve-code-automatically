# Claude Code — Refactoring Prompts (Optimized for Claude Code)

## How to use these prompts

Paste directly into Claude Code in your terminal (`claude`) or via the Claude Code VS Code extension.
Replace `[PACKAGE_PATH]` with a real path, e.g. `src/main/java/com/example/order`.

### Three variants per category
- **EDUCATIONAL** — dry run only, shows findings as a table, touches nothing
- **SAFE** — applies changes, zero breaking risk
- **AGGRESSIVE** — maximizes changes, low risk, review diff before committing

### Processing strategy per category
Each category uses the optimal strategy based on what context the rule actually needs:

| Strategy | When used | How it works |
|---|---|---|
| **File-by-file** | Rules that need only one file | Read → fix → summarize → next file |
| **Scan-then-fix** | Rules needing cross-file awareness | Scan all → report → fix one by one |
| **Single-pass** | Purely mechanical, no context needed | Find pattern → replace inline |

---

## 🏷️ 1. NAMING
**Strategy: file-by-file** — naming decisions are local to one file

### EDUCATIONAL
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find all naming issues:
   - Abbreviated variable/parameter names (usr, mgr, cfg, d, s, f, tmp, res)
   - Boolean fields or variables not phrased as questions (active → isActive, valid → isValid)
   - Redundant class name in field (User.userName → User.name)
   - Constants not in SCREAMING_SNAKE_CASE (secondsInHour → SECONDS_IN_HOUR)
3. Output findings as a table:
   File | Line | Type | Before | After | Why
4. Do NOT modify any file. Move to next file.

At the end: "Found X naming issues in Y files."
```

### SAFE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply these changes:
   - Expand abbreviated local variable and parameter names — infer full name from type and usage context
   - Rename boolean locals and fields to question form (active → isActive)
   - Remove redundant class prefix from private fields (User.userName → User.name)
   - Rename constants to SCREAMING_SNAKE_CASE
3. Print summary: "FileName.java — changed X names: [list of old→new]"
4. Save the file. Move to next file.

Hard rules:
- ONLY touch local variables, method parameters, and private fields
- Do NOT rename public methods, public fields, or anything in a public interface
- Skip rename if the new name would be ambiguous or identical to an existing variable in scope
```

### AGGRESSIVE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply all SAFE naming changes, plus:
   - Rename private methods that are too generic (check() → isValid(), get() → fetchOrder())
     by inferring intent from the method body
   - Rename private methods returning boolean to question form (getActive() → isActive())
   - Remove all abbreviations in private method names
3. Print a changelog table: File | Old name | New name | Reason
4. Save the file. Move to next file.

Hard rules:
- Do NOT rename anything public or package-private
- Do NOT rename if body is too ambiguous to infer intent — skip and note it
```

---

## 🔀 2. LOGIC (Simplifying conditions)
**Strategy: file-by-file** — logic simplifications are purely local

### EDUCATIONAL
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find all logic clarity issues:
   - if (x) return true; else return false; patterns
   - if (x == true) or if (x == false) comparisons
   - Double negations: if (!isNotActive)
   - Complex inline conditions (2+ operators) not extracted to named booleans
3. Output as table: File | Line | Pattern | Before | After | Rule
4. Do NOT modify. Move to next file.
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
- Do NOT touch guard clauses (early return patterns with real business logic)
- Do NOT extract conditions to variables (requires naming judgment)
- Do NOT change any method signatures
```

### AGGRESSIVE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply all SAFE simplifications, plus:
   - Extract all complex inline conditions (2+ boolean operators) to a named boolean variable
     placed on the line directly above the if statement
     Name the variable to express business intent based on context
   - Convert nested if blocks (3+ levels deep) to guard clauses with early return
     ONLY when: no unconditional code exists after the nested block that would be skipped
     Add a comment above each converted guard: // guard: [reason inferred from condition]
3. Print: "FileName.java — X simplifications, Y extractions, Z guard clauses"
4. Save. Move to next file.
```

---

## 🧱 3. CODE STRUCTURE
**Strategy: file-by-file** — dead code, constants, and lambdas are all local decisions

### EDUCATIONAL
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find:
   - Numeric literals (except 0, 1, -1) not assigned to a named constant
   - String literals appearing 3+ times without a constant
   - Unused imports
   - System.out.println calls
   - Lambdas reducible to method references (body is a single method call)
   - Class member order violations (fields → constructors → public methods → private methods)
3. Output as table: File | Line | Issue | Before | After
4. Do NOT modify. Move to next file.
```

### SAFE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply:
   - Remove all unused imports
   - Remove all System.out.println lines (delete entirely)
   - Extract numeric literals (except 0, 1, -1) to private static final constants at top of class
     Name them based on usage context
   - Extract string literals that appear 3+ times to private static final String constants
   - Convert lambdas to method references where the lambda body is a single method call
     e.g. x -> x.toString() → Object::toString
3. Print: "FileName.java — removed X imports, Y println, extracted Z constants, converted W lambdas"
4. Save. Move to next file.

Hard rules:
- Do NOT remove unused private methods or fields (may be used via reflection)
- Do NOT reorder class members
```

### AGGRESSIVE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply all SAFE changes, plus:
   - Remove unused private methods and fields that have no framework annotations
     (@Autowired, @Bean, @EventListener, @Scheduled etc.) — skip if annotated
   - Replace System.out that appears to be application output (not debug) with:
     log.info(...) using the existing logger, or add SLF4J logger if missing
   - Reorder class members: static fields → instance fields → constructors →
     public methods → package-private methods → private methods → inner classes
   - If a private method is called exactly once and its body is under 3 lines, inline it
3. Print full report: constants extracted N, dead code removed N lines,
   lambdas converted N, members reordered in N classes, methods inlined N
4. Save. Move to next file.
```

---

## 🔒 4. NULL SAFETY
**Strategy: file-by-file** — annotation decisions are based on local usage within one file

### EDUCATIONAL
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find:
   - Method parameters used without null check and missing @NotNull
   - Method parameters with explicit null check and missing @Nullable
   - Methods with "return null" statements that could return empty collection instead
   - Ternary null patterns: x != null ? x : default → requireNonNullElse candidate
3. Output as table: File | Line | Issue | Before | After | Contract
4. Do NOT modify. Move to next file.
```

### SAFE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply:
   - Add @NotNull to parameters used directly without null check in the method body
   - Add @Nullable to parameters that have an explicit null check (if param == null)
   - Add @NotNull to return type if the method has no "return null" statements
   - Add @Nullable to return type if the method has at least one "return null" statement
   - Replace "return null" → return List.of() / Collections.emptyList() / Set.of()
     ONLY for methods whose declared return type is List, Set, or Collection
3. Print: "FileName.java — added X @NotNull, Y @Nullable, replaced Z null returns"
4. Save. Move to next file.

Hard rules:
- Use jakarta.annotation for @NotNull/@Nullable (fall back to javax.annotation if jakarta absent)
- Do NOT add Objects.requireNonNull calls (annotation only in SAFE mode)
- Do NOT change Optional return types
```

### AGGRESSIVE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply all SAFE null safety changes, plus:
   - Add Objects.requireNonNull(param, "param must not be null") at the top of each
     public method for every @NotNull parameter that lacks an existing null check
   - Replace: x != null ? x : defaultValue → Objects.requireNonNullElse(x, defaultValue)
3. Print null safety score per file:
   Before: X unannotated params, Y nullable returns, Z missing requireNonNull
   After: what changed
4. Save. Move to next file.
```

---

## 🧊 5. IMMUTABILITY
**Strategy: single-pass per file** — final is purely mechanical, no cross-file context needed

### EDUCATIONAL
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find all variables eligible for final:
   - Local variables assigned exactly once, never reassigned
   - Method parameters never reassigned inside the method body
3. Output as table: File | Line | Variable | Type (local/param)
4. Do NOT modify. Move to next file.

Note at end: "X local variables and Y parameters could be marked final."
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
- Do NOT add final to fields (framework risk: Spring, Hibernate, Jackson)
- Do NOT add final to variables in catch blocks
- Do NOT add final to loop variables (for, for-each, while)
```

### AGGRESSIVE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply all SAFE final changes, plus:
   - Add final to private fields that are:
     (a) assigned only in the constructor
     (b) have no setter method
     (c) are NOT annotated with @Autowired, @Inject, @Value, @PersistenceContext, @Column
     (d) are in a class NOT annotated with @Entity, @Component, @Service, @Repository
   - Add final to the class declaration if:
     (a) no class in [PACKAGE_PATH] extends it
     (b) it has no @Component/@Service/@Repository annotation (Spring proxies need non-final)
3. Print: "FileName.java — finalized X locals, Y params, Z fields, W classes"
4. Save. Move to next file.
```

---

## 🧹 6. FORMATTING AND STYLE
**Strategy: scan-then-fix** — logger consistency requires seeing all files before fixing

### EDUCATIONAL
```
Step 1 — scan all files in [PACKAGE_PATH]:
  For each .java file, note:
  - Logger style used (SLF4J / java.util.logging / Log4j / System.out / none)
  - Import ordering issues (unsorted, unused)
  - Methods missing blank-line grouping (validation block / logic block / return)

Step 2 — report:
  - Logger inconsistency summary: "X files use SLF4J, Y use java.util.logging, Z use System.out"
  - Per-file table: File | Issue | Line | Before | After

Do NOT modify anything.
```

### SAFE
```
Step 1 — scan all .java files in [PACKAGE_PATH] and note which logger style is dominant.

Step 2 — for each file, one at a time:
1. Read the file
2. Apply:
   - Sort imports: static imports first, then java.*, javax.*, org.*, com.*, then project packages
   - Remove unused imports
   - Add blank lines to separate logical method sections where clearly missing:
     (1) parameter validation block
     (2) business logic
     (3) return statement
     — add blank lines only, never remove existing ones
   - If dominant logger is SLF4J and this file uses System.out: add SLF4J logger declaration,
     replace System.out.println with log.info/log.debug/log.warn as appropriate
3. Print: "FileName.java — sorted imports, added X blank lines, unified logger: yes/no"
4. Save. Move to next file.

Hard rules:
- Do NOT reformat indentation
- Do NOT change line lengths
- Do NOT change logger variable name if one already exists
```

### AGGRESSIVE
```
Step 1 — scan all .java files in [PACKAGE_PATH]:
  - Determine dominant logger (most files use which framework)
  - Find all inconsistencies: size()==0 vs isEmpty(), logger styles, import styles

Step 2 — for each file, one at a time:
1. Read the file
2. Apply all SAFE formatting changes, plus:
   - Unify ALL loggers to SLF4J regardless of what is used:
     private static final Logger log = LoggerFactory.getLogger(ClassName.class);
   - Within each class: if isEmpty() is used anywhere, replace all size()==0 and size()>0
   - Remove trailing whitespace
   - Normalize blank lines: max 1 consecutive blank line inside a method body,
     max 2 between method declarations
3. Print consistency report per file
4. Save. Move to next file.
```

---

## 🧪 7. EXCEPTIONS
**Strategy: file-by-file** — exception handling decisions are local to one file

### EDUCATIONAL
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find:
   - Empty catch blocks (body is empty or contains only a comment)
   - Unnecessary casts (variable is already the target type)
3. Output as table: File | Line | Issue | Before | After | Risk
4. Do NOT modify. Move to next file.
```

### SAFE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply:
   - Replace empty catch blocks with logging:
     If a logger (log, logger, LOG) already exists in the class:
       log.warn("Unexpected {}: {}", e.getClass().getSimpleName(), e.getMessage(), e);
     If no logger exists: add SLF4J logger declaration, then add the warn line
   - Remove unnecessary casts where the variable's declared type already matches the cast target
3. Print: "FileName.java — fixed X empty catches, removed Y unnecessary casts"
4. Save. Move to next file.

Hard rules:
- Do NOT narrow catch(Exception) to a specific type
- Do NOT convert finally blocks to try-with-resources
- Do NOT change any exception types being thrown
```

### AGGRESSIVE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply all SAFE exception changes, plus:
   - Where catch(Exception e) is used: inspect the try block. If ALL method calls inside
     only declare specific checked exceptions (visible in source within this file),
     narrow catch to those specific types. If ambiguous, skip and add:
     // TODO: narrow exception type — currently catching Exception broadly
   - Where a catch block only contains: throw new RuntimeException(e)
     Verify the original exception is passed as cause. If not: fix it.
     If yes: add a comment // wrapping checked exception — intentional
3. Print: "FileName.java — X catches fixed, Y casts removed, Z catches narrowed, W skipped"
4. Save. Move to next file.
```

---

## 🧩 8. ANNOTATIONS AND BOILERPLATE
**Strategy: file-by-file** — @Override detection is purely local (compiler-level)

### EDUCATIONAL
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find:
   - Methods that override a parent class method or implement an interface method
     but are missing the @Override annotation
3. Output as table: File | Line | Method | Missing annotation
4. Do NOT modify. Move to next file.

Explain once at the start: "@Override is a compile-time safety net.
If the parent method is renamed, the compiler immediately flags the orphaned override."
```

### SAFE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Add @Override to every method that:
   - Overrides a method from a superclass, OR
   - Implements a method from an interface
   — where @Override is currently missing
3. Print: "FileName.java — added @Override to X methods: [method names]"
4. Save. Move to next file.

Hard rules:
- Do NOT generate constructors
- Do NOT add any Lombok annotations
- Do NOT modify existing annotations
```

### AGGRESSIVE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply all SAFE annotation changes, plus:
   - If the class has fields but no constructor: generate an all-fields constructor.
     Access modifier: match the class (public class → public constructor)
   - Check pom.xml or build.gradle (read it once at start) to see if Lombok is a dependency.
     If yes: replace all manually written single-line getters and setters with
     @Getter / @Setter at field level (not class level — per-field is safer)
3. Print full change summary per file
4. Save. Move to next file.

Hard rules:
- Do NOT add @Builder
- Do NOT add @EqualsAndHashCode
- Do NOT add Lombok if it is not already in pom.xml / build.gradle
```

---

## 🔧 9. LOOPS AND COLLECTIONS
**Strategy: single-pass per file** — all changes are pattern-based, purely mechanical

### EDUCATIONAL
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find:
   - Indexed for loops where the index is only used for list.get(i) (for-each candidate)
   - size() == 0 or size() > 0 comparisons (isEmpty() candidate)
   - Collections.sort(list) calls (list.sort() candidate)
   - Missing diamond operator: new ArrayList<String>() (new ArrayList<>() candidate)
   - Raw types: List, Map, Set without generic type parameter
3. Output as table: File | Line | Pattern | Before | After
4. Do NOT modify. Move to next file.
```

### SAFE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply:
   - Replace size() == 0 with isEmpty()
   - Replace size() > 0 with !isEmpty()
   - Add diamond operator: new ArrayList<String>() → new ArrayList<>()
   - Replace Collections.sort(list) → list.sort(null)
     Replace Collections.sort(list, comparator) → list.sort(comparator)
   - Replace indexed for loop → for-each ONLY when loop variable i is used
     exclusively for list.get(i) and nothing else
3. Print: "FileName.java — X isEmpty(), Y diamond ops, Z sort(), W for-each conversions"
4. Save. Move to next file.

Hard rules:
- Do NOT convert any loops to streams
- Do NOT add generics to raw types (type inference required — risky without full context)
```

### AGGRESSIVE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply all SAFE collection changes, plus:
   - Add generics to raw types where the type is unambiguous from context:
     infer from: add() call arguments, return type declaration, variable assignment target
   - Convert simple for-each loops to Stream API for these patterns only:
     (a) filter pattern: loop with if + list.add(item) inside → .filter().collect()
     (b) map pattern: loop transforming each element into another list → .map().collect()
     (c) count pattern: loop with counter++ → .count()
     Do NOT convert if the loop has: break, return, exception throwing, or multiple side effects
   - Replace Collections.unmodifiableList(new ArrayList<>(source))
     with List.copyOf(source) — only if Java version in pom.xml is 10 or higher
     (check pom.xml once at start)
3. Print: "FileName.java — X generics added, Y streams introduced, Z copyOf replacements"
4. Save. Move to next file.
```

---

## 🔥 10. COMMENTS
**Strategy: file-by-file** — comment quality is a purely local decision

### EDUCATIONAL
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find:
   - Inline comments that describe WHAT the next line does (not WHY)
     e.g. // increment counter, // call the service, // return result
   - Commented-out code blocks
   - TODO or FIXME with no description (just the tag, nothing else)
3. Output as table: File | Line | Type | Comment text | Verdict
4. For what-comments where the variable/method name is poor: suggest a better name
5. Do NOT modify. Move to next file.

Explain once: "A comment describing WHAT signals the code needs a better name, not a better comment."
```

### SAFE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply:
   - Remove inline comments that only describe what the very next line does
   - Remove all commented-out code blocks (consecutive lines starting with //)
3. For every removal, print:
   "Removed from FileName.java:LINE — [comment text]"
   so the developer can review the removal log
4. Save. Move to next file.

Hard rules:
- Do NOT remove Javadoc comments (/** ... */)
- Do NOT remove comments that explain WHY (business reason, workaround, limitation)
- Do NOT remove TODO or FIXME tags
- Do NOT remove license headers
```

### AGGRESSIVE
```
For each .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply all SAFE comment changes, plus:
   - For TODO/FIXME with no description: add context inferred from surrounding code:
     // TODO: [method name] — [inferred intent from code context]
   - If a what-comment is the ONLY documentation for a poorly named method or variable:
     do NOT remove the comment — instead add to a separate output section:
     "Rename suggestion: [FileName:LINE] rename X to Y (comment is the only doc)"
3. Output two sections:
   1. Changes applied (removals log)
   2. Rename suggestions (where comment compensates for poor naming)
4. Save. Move to next file.
```

---

## 🧪 11. TESTS
**Strategy: single-pass per file** — assertion patterns are purely mechanical text replacements

### EDUCATIONAL
```
For each test .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Find:
   - assertEquals(true, x) → assertTrue(x) candidate
   - assertEquals(false, x) → assertFalse(x) candidate
   - assertEquals(null, x) → assertNull(x) candidate
   - assertNotEquals(null, x) → assertNotNull(x) candidate
3. Output as table: File | Line | Before | After | Why
4. Do NOT modify. Move to next file.

Explain once: "assertTrue(x) reads as a sentence. assertEquals(true, x) forces mental parsing
and produces a worse failure message: 'expected true but was false' vs 'expected: true but was: false'."
```

### SAFE
```
For each test .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply:
   - assertEquals(true, x)       → assertTrue(x)
   - assertEquals(false, x)      → assertFalse(x)
   - assertEquals(null, x)       → assertNull(x)
   - assertNotEquals(null, x)    → assertNotNull(x)
3. Print: "FileName.java — X assertions modernized"
4. Save. Move to next file.

Hard rules:
- Apply to JUnit 4 and JUnit 5 style assertions only
- Do NOT change AssertJ (assertThat) or Hamcrest (assertThat + matcher) assertions
- Do NOT change existing assertion failure messages
```

### AGGRESSIVE
```
First: check pom.xml or build.gradle once to see if AssertJ is on the classpath.

For each test .java file in [PACKAGE_PATH], one at a time:
1. Read the file
2. Apply all SAFE assertion changes, plus:
   - assertTrue(list.size() == N) → assertEquals(N, list.size())
   - assertTrue(list.isEmpty()) → assertThat(list).isEmpty() (if AssertJ available)
     otherwise keep as assertTrue(list.isEmpty())
   - assertNotNull(x) immediately followed by assertEquals(expected, x) on the next line:
     remove the assertNotNull — assertEquals already fails on null
   - assertTrue(str.contains("x")) → assertThat(str).contains("x") (if AssertJ available)
3. Print: "FileName.java — X modernized, Y redundant assertions removed"
4. Save. Move to next file.
```

---

## 🎯 MEGA PROMPTS — all 11 categories

### EDUCATIONAL (full scan, no changes)
```
Perform a full code quality scan of [PACKAGE_PATH].
Process files one at a time. For each file: read → scan all 11 categories → move on.
Do NOT modify any file.

Categories to scan:
1. Naming — abbreviations, non-question booleans, redundant context, constant style
2. Logic — boolean return simplification, x==true patterns, double negations
3. Structure — magic numbers, repeated strings, unused imports, System.out, lambda→method ref
4. Null safety — missing @NotNull/@Nullable, null collection returns
5. Immutability — final candidates (local vars and parameters only)
6. Formatting — missing blank-line grouping, import order, logger inconsistency
7. Exceptions — empty catch blocks, unnecessary casts
8. Boilerplate — missing @Override
9. Collections — for→forEach, isEmpty(), diamond operator
10. Comments — what-comments, commented-out code
11. Tests — assertEquals(true/false/null) patterns

Output format per finding (all categories, all files):
| Category | File | Line | Before | After | Why |

Final summary:
"Scanned X files. Found Y issues across 11 categories.
Top 3 by issue count: [category: N], [category: N], [category: N]"
```

### SAFE (full refactor, file-by-file)
```
Apply all SAFE refactoring to [PACKAGE_PATH].

Step 1 — read pom.xml or build.gradle once:
  - Note Java version (for Java 10+ features)
  - Note if Lombok is present
  - Note dominant logger framework

Step 2 — process files one at a time in this order of operations per file:
  1. Remove unused imports
  2. Sort imports (static → java → javax → org → com → project)
  3. Add @Override to eligible methods
  4. Fix isEmpty() patterns (size()==0, size()>0)
  5. Add diamond operator where missing
  6. Fix for-each where index is unused
  7. Simplify boolean returns (if x return true; else return false; → return x;)
  8. Fix x==true / x==false patterns
  9. Add final to local variables and parameters
  10. Add @NotNull/@Nullable based on local usage
  11. Replace null collection returns with List.of() / Collections.emptyList()
  12. Extract magic numbers to named constants
  13. Remove System.out.println
  14. Fix empty catch blocks (add log.warn)
  15. Remove what-comments and commented-out code
  16. Fix assertEquals(true/false/null) in test files

Step 3 — after all files:
  Print summary table:
  | Category | Files changed | Changes applied |

Hard rules:
- Do NOT touch public API signatures
- Do NOT touch class fields
- Do NOT add Lombok
- Do NOT convert loops to streams
- Do NOT narrow catch(Exception)
```

### AGGRESSIVE (full refactor, scan-then-fix)
```
Apply aggressive but safe refactoring to [PACKAGE_PATH].

Step 1 — read once (do not modify yet):
  - pom.xml or build.gradle: Java version, Lombok presence, AssertJ presence
  - Scan all .java files: note dominant logger, find cross-file inconsistencies

Step 2 — process files one at a time:
  Apply all SAFE mega prompt operations, plus:
  - Rename abbreviations in local vars, parameters, private fields and methods
  - Extract complex boolean conditions (2+ operators) to named variables
  - Convert eligible lambdas to method references
  - Reorder class members (fields → constructors → public → private)
  - Unify all loggers to SLF4J
  - Add Objects.requireNonNull for @NotNull parameters in public methods
  - Add final to private fields not touched by frameworks
  - Modernize test assertions (AssertJ if available, otherwise JUnit semantic forms)
  - Add context to empty TODO/FIXME comments

Step 3 — final output:
  1. Full changelog grouped by category and file
  2. Skipped items with reason: "Skipped X in FileName.java — [reason]"
  3. Manual review list: things intentionally left untouched
     e.g. "catch(Exception) in OrderService.java:45 — thrown types not fully visible"

Hard rules:
- Do NOT change public method signatures
- Do NOT add @Builder or @EqualsAndHashCode
- Do NOT convert loops with side effects to streams
- Do NOT convert finally blocks to try-with-resources
- Do NOT narrow catch(Exception) unless all thrown types are visible in the same file
```
