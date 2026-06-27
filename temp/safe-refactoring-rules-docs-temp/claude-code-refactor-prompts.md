# Claude Code — Refactoring Prompts (100% Safe Rules)

Each group contains three variants:
- **EDUCATIONAL** — shows what changed and why, ideal for learning
- **SAFE** — applies changes without risk, no explanations
- **AGGRESSIVE** — maximizes changes at acceptable risk

---

## 🏷️ 1. NAMING

### EDUCATIONAL
```
Analyze the Java module/package [PACKAGE_NAME] and find all naming issues:
- abbreviated variable names (usr, mgr, cfg, d, s, f)
- variable names that don't reflect their type or purpose
- boolean fields/variables not phrased as questions (active → isActive)
- redundant context in names (User.userName → User.name)
- constants not in SCREAMING_SNAKE_CASE

For each issue found:
1. Show the BEFORE code snippet
2. Show the AFTER code snippet
3. Explain in one sentence WHY the new name is better

Do NOT apply any changes yet. Only report.
```

### SAFE
```
Refactor all Java files in [PACKAGE_NAME]:
- Expand abbreviated local variable and parameter names (usr → user, mgr → manager, cfg → configuration, d → deliveryDate — infer from context)
- Rename boolean fields and local variables to question form (active → isActive, valid → isValid)
- Remove redundant class name prefix from fields (User.userName → User.name)
- Rename constants to SCREAMING_SNAKE_CASE (SecondsInHour → SECONDS_IN_HOUR)

Rules:
- Apply ONLY to local variables, parameters, and private fields
- Do NOT rename public methods or public fields (breaking change risk)
- Do NOT rename if the new name is ambiguous
- After each file, print a summary: "Changed X names in FileName.java"
```

### AGGRESSIVE
```
Refactor all Java files in [PACKAGE_NAME] for maximum naming clarity:
- Expand all abbreviations in local variables, parameters, private fields, and private methods
- Rename all booleans to question form everywhere (fields, methods, variables)
- Remove redundant context from all field names
- Rename all constants to SCREAMING_SNAKE_CASE
- Rename private methods that are too generic: check() → isValid(), process() → execute() — infer better name from method body
- Rename private methods returning boolean to question form: getActive() → isActive()

After refactoring, generate a CHANGELOG in this format:
File | Old name | New name | Reason
```

---

## 🔀 2. LOGIC (Simplifying conditions)

### EDUCATIONAL
```
Analyze [PACKAGE_NAME] and find all logic clarity issues:
- if/else blocks that return true/false directly
- boolean variables named without question form in conditions
- conditions using if (x == true) or if (x == false)
- negations that could be simplified (!isNotActive)
- complex boolean conditions inline in if statements

For each issue:
1. Show BEFORE snippet with line number
2. Show AFTER snippet
3. Explain the rule: e.g. "Extracting complex conditions to named booleans makes code self-documenting"

Do NOT apply changes.
```

### SAFE
```
Refactor logic in all Java files in [PACKAGE_NAME]:
- Replace: if (x) return true; else return false; → return x;
- Replace: if (x == true) → if (x)
- Replace: if (x == false) → if (!x)
- Replace: if (!isNotActive) → if (isActive) — only when isActive() exists or the variable name allows it

Rules:
- Do NOT touch guard clauses (early returns with business logic)
- Do NOT extract boolean variables — only inline simplifications
- Do NOT change method signatures
- Print each change with BEFORE/AFTER
```

### AGGRESSIVE
```
Refactor all logic in [PACKAGE_NAME] for maximum readability:
- Simplify all boolean returns: if (x) return true; else return false; → return x;
- Remove all x == true / x == false comparisons
- Extract all complex inline conditions (2+ operators) to named boolean variables placed directly above the if statement. Name them to express business intent.
- Simplify double negations
- Convert nested if blocks (3+ levels) to guard clauses using early return — only in methods where early return does not skip any unconditional code after the block

For each guard clause conversion, add a one-line comment above: // Guard: [reason]
Print summary: X simplifications, Y extractions, Z guard clauses applied
```

---

## 🧱 3. CODE STRUCTURE

### EDUCATIONAL
```
Analyze [PACKAGE_NAME] and report structural issues:
- magic numbers (numeric literals not assigned to constants)
- repeated string literals (same string in 3+ places)
- dead code (unused imports, unused private methods, unused fields)
- System.out.println calls
- lambda expressions that could be method references
- class member ordering violations (fields → constructors → public methods → private methods)

For each issue:
1. Show BEFORE
2. Show AFTER
3. Explain why this matters for maintainability

Do NOT apply changes.
```

### SAFE
```
Refactor structure in [PACKAGE_NAME]:
- Extract all numeric literals (except 0 and 1) to private static final constants. Place constants at top of class. Name them descriptively based on context.
- Extract repeated string literals (3+ occurrences) to private static final String constants
- Remove all unused imports
- Remove all System.out.println statements (delete the line, do not replace)
- Convert lambda to method reference where lambda body is a single method call: x -> x.toString() → Object::toString

Rules:
- Do NOT remove unused private methods or fields (may be used via reflection)
- Do NOT reorder class members
- Print each change with file and line number
```

### AGGRESSIVE
```
Perform full structural refactoring of [PACKAGE_NAME]:
- Extract all magic numbers and repeated strings to named constants
- Remove all unused imports, and unused private methods/fields that have no @annotations suggesting reflection use
- Remove all System.out.println — if clearly used for debugging, delete; if used as application output, replace with slf4j logger call: log.info(...)
- Convert all eligible lambdas to method references
- Reorder all class members: static fields → instance fields → constructors → public methods → package-private methods → private methods → inner classes
- If a private method is only called once and is under 3 lines, inline it back into the caller

Generate a full report:
- Constants extracted: N
- Dead code removed: N lines
- Lambdas converted: N
- Methods inlined: N
```

---

## 🔒 4. NULL SAFETY

### EDUCATIONAL
```
Analyze [PACKAGE_NAME] for null safety issues:
- methods or parameters missing @NotNull / @Nullable annotations
- methods returning null instead of empty collections
- missing Objects.requireNonNull() for critical parameters
- ternary null checks that could use Objects.requireNonNullElse()

For each issue:
1. Show BEFORE
2. Show AFTER
3. Explain: e.g. "@NotNull is a contract — it tells the caller and the IDE that null is never acceptable here, preventing NullPointerExceptions before they happen"

Do NOT apply changes.
```

### SAFE
```
Improve null safety in [PACKAGE_NAME]:
- Add @NotNull to all method parameters that are used without null check inside the method body
- Add @Nullable to all method parameters that have an explicit null check inside the method body
- Add @NotNull to method return type if the method never returns null
- Add @Nullable to method return type if the method has at least one "return null" statement
- Replace: return null; → return Collections.emptyList(); or return List.of(); ONLY for methods with return type List, Set, or Collection

Rules:
- Use jakarta.annotation.@NotNull and @Nullable (or javax.annotation if jakarta not present)
- Do NOT add requireNonNull calls — annotation only
- Do NOT change Optional return types
- Print each annotation added with reason
```

### AGGRESSIVE
```
Apply full null safety refactoring to [PACKAGE_NAME]:
- Add @NotNull / @Nullable to all method parameters and return types based on usage analysis
- Replace all "return null" for collection return types with empty collections
- Add Objects.requireNonNull(param, "param must not be null") at the start of public methods for all @NotNull parameters that lack a null check
- Replace null ternary patterns: x != null ? x : defaultValue → Objects.requireNonNullElse(x, defaultValue)
- Add @NotNull to all local variables that are immediately assigned and never reassigned to null

Generate null safety score:
- Before: X unannotated parameters, Y nullable returns, Z missing requireNonNull
- After: what was fixed
```

---

## 🧊 5. IMMUTABILITY

### EDUCATIONAL
```
Analyze [PACKAGE_NAME] for immutability issues:
- local variables and parameters that are assigned once and never reassigned (candidates for final)
- fields that are set only in constructor and never changed (candidates for final)

For each issue:
1. Show BEFORE
2. Show AFTER
3. Explain: e.g. "final on a local variable is a signal to the reader: this value does not change. It reduces cognitive load — you don't have to track whether it might be reassigned later."

Do NOT apply changes.
```

### SAFE
```
Add final to all eligible variables in [PACKAGE_NAME]:
- Add final to all local variables that are assigned exactly once and never reassigned
- Add final to all method parameters that are never reassigned inside the method body

Rules:
- Do NOT add final to fields (risk with frameworks like Spring, Hibernate)
- Do NOT add final to variables in catch blocks
- Do NOT add final to loop variables
- Print count: "Added final to X local variables and Y parameters in FileName.java"
```

### AGGRESSIVE
```
Maximize immutability in [PACKAGE_NAME]:
- Add final to all eligible local variables and parameters
- Add final to all private fields that are only assigned in the constructor and have no setter
- Add final to the class declaration if the class has no subclasses within this module

Rules:
- Do NOT add final to fields annotated with @Autowired, @Inject, @Value, @PersistenceContext
- Do NOT add final to fields in classes annotated with @Entity, @Component, @Service, @Repository
- Do NOT modify public API

Print: "Finalized X local vars, Y parameters, Z fields, W classes"
```

---

## 🧹 6. FORMATTING AND STYLE

### EDUCATIONAL
```
Analyze [PACKAGE_NAME] for formatting and consistency issues:
- methods missing logical blank-line grouping (validation → logic → return)
- inconsistent logger usage (mix of System.out and SLF4J, or different logger styles)
- inconsistent import ordering
- methods where related statements are not visually grouped

For each issue:
1. Show BEFORE
2. Show AFTER
3. Explain: e.g. "Blank lines act as paragraph breaks. Grouping validation, logic, and return separately makes the structure of a method immediately visible."

Do NOT apply changes.
```

### SAFE
```
Fix formatting and style consistency in [PACKAGE_NAME]:
- Sort imports: static imports first, then java.*, then javax.*, then org.*, then com.*, then project imports. Remove unused imports.
- Ensure every method body has logical blank-line separation between: (1) parameter validation, (2) business logic, (3) return statement — add blank lines where missing, do not remove existing ones
- Unify logger declarations: if any class uses SLF4J, ensure all classes in the package use SLF4J consistently. Do not change logger variable names.

Rules:
- Do NOT reformat indentation (leave to IDE/Checkstyle)
- Do NOT change line length
- Print what was changed per file
```

### AGGRESSIVE
```
Apply full formatting and consistency refactoring to [PACKAGE_NAME]:
- Sort and clean all imports
- Add logical blank-line grouping to all methods: validation block → logic block → return. If a method has no clear validation, add a blank line before the return statement.
- Unify all loggers to SLF4J: replace java.util.logging, Log4j direct usage, System.out with SLF4J. Use: private static final Logger log = LoggerFactory.getLogger(ClassName.class);
- Ensure consistency within each class: if isEmpty() is used once, replace all size() == 0 and size() > 0 in that class
- Remove trailing whitespace and normalize blank lines (max 1 consecutive blank line inside method, max 2 between methods)

Print a consistency report per file.
```

---

## 🧪 7. EXCEPTIONS

### EDUCATIONAL
```
Analyze [PACKAGE_NAME] for exception handling issues:
- empty catch blocks
- catch blocks that only have a comment but no action
- unnecessary casts that could cause ClassCastException

For each issue:
1. Show BEFORE
2. Show AFTER
3. Explain: e.g. "An empty catch block silently swallows errors. This is one of the most dangerous patterns in Java — the program continues in an inconsistent state with no indication that something went wrong."

Do NOT apply changes.
```

### SAFE
```
Fix exception handling in [PACKAGE_NAME]:
- Replace all empty catch blocks with: log.warn("Unexpected exception: {}", e.getMessage(), e); — use existing logger variable name if present, otherwise add SLF4J logger
- Remove all unnecessary casts where the variable is already of the target type

Rules:
- Do NOT narrow catch(Exception) to specific type
- Do NOT convert finally to try-with-resources
- Do NOT change exception types
- Print each change with file and line number
```

### AGGRESSIVE
```
Refactor all exception handling in [PACKAGE_NAME]:
- Replace all empty catch blocks with appropriate logging
- Remove all unnecessary casts
- Where catch(Exception e) is used and the try block only calls methods that throw specific checked exceptions (visible in source), narrow the catch to those specific types
- Where a catch block only does: throw new RuntimeException(e) — keep it but ensure the original exception is passed as cause (it may already be)

Rules:
- Do NOT convert finally to try-with-resources
- Do NOT change public method signatures
- If narrowing catch type is ambiguous, leave as-is and add comment: // TODO: narrow exception type

Print: X empty catches fixed, Y casts removed, Z catches narrowed
```

---

## 🧩 8. ANNOTATIONS AND BOILERPLATE

### EDUCATIONAL
```
Analyze [PACKAGE_NAME] for missing boilerplate and annotations:
- methods that override a superclass method but lack @Override
- constructors that could be auto-generated

For each issue:
1. Show BEFORE
2. Show AFTER
3. Explain: e.g. "@Override is a compile-time safety net. If you rename the parent method, the compiler will immediately tell you this override no longer matches — without @Override, the method silently becomes a new method instead."

Do NOT apply changes.
```

### SAFE
```
Add missing boilerplate annotations in [PACKAGE_NAME]:
- Add @Override to all methods that override a superclass method or implement an interface method, where @Override is missing

Rules:
- Do NOT generate constructors
- Do NOT add Lombok annotations
- Do NOT modify existing annotations
- Print: "Added @Override to X methods in FileName.java"
```

### AGGRESSIVE
```
Add all missing boilerplate in [PACKAGE_NAME]:
- Add @Override to all eligible methods
- Generate canonical constructors (all-fields) for classes that have fields but no constructor — add as package-private if class is package-private, public otherwise
- If Lombok is already a dependency in pom.xml/build.gradle: replace all manually written getters/setters with @Getter/@Setter at field or class level

Rules:
- Do NOT add @Builder
- Do NOT add @EqualsAndHashCode
- Do NOT add Lombok if it's not already a project dependency
- Print full change summary
```

---

## 🔧 9. LOOPS AND COLLECTIONS

### EDUCATIONAL
```
Analyze [PACKAGE_NAME] for collection and loop improvement opportunities:
- traditional for loops where index is not used (for-each candidate)
- size() == 0 or size() > 0 checks (isEmpty() candidate)
- Collections.sort() calls (list.sort() candidate)
- raw types (List, Map without generics)
- missing diamond operator

For each issue:
1. Show BEFORE
2. Show AFTER
3. Explain: e.g. "isEmpty() communicates intent directly — 'is this collection empty?' — while size() == 0 forces the reader to mentally parse an arithmetic comparison."

Do NOT apply changes.
```

### SAFE
```
Refactor collections and loops in [PACKAGE_NAME]:
- Replace for(int i = 0; i < list.size(); i++) with for-each ONLY when i is not used inside the loop body for anything other than list.get(i)
- Replace all size() == 0 with isEmpty()
- Replace all size() > 0 with !isEmpty()
- Replace Collections.sort(list) with list.sort(null) or list.sort(comparator) if comparator was passed
- Add diamond operator where missing: new ArrayList<String>() → new ArrayList<>()

Rules:
- Do NOT convert loops to streams
- Do NOT add generics to raw types (requires type inference — risky)
- Print each change with file and line number
```

### AGGRESSIVE
```
Fully modernize collections and loops in [PACKAGE_NAME]:
- Apply all SAFE changes above
- Replace raw types with inferred generics where the type is unambiguous from context: List list = new ArrayList() → List<String> list = new ArrayList<>() — infer type from add() calls or return type
- Convert simple for-each loops to streams ONLY for: filtering (if + continue/add), mapping (transforming each element), counting — do NOT convert loops with multiple operations or side effects
- Replace Collections.unmodifiableList(new ArrayList<>(...)) patterns with List.copyOf(...) where applicable (Java 10+)

Rules:
- Do NOT convert loops that modify the collection being iterated
- Do NOT use streams if the loop has a break or return inside
- Print: X for→forEach, Y raw types fixed, Z streams introduced
```

---

## 🔥 10. COMMENTS

### EDUCATIONAL
```
Analyze [PACKAGE_NAME] for comment quality issues:
- comments that describe WHAT the code does (redundant — code already shows this)
- commented-out code blocks
- TODO/FIXME without context

For each issue:
1. Show the comment
2. Explain why it should be removed or rewritten
3. If the code the comment describes has a poor name — suggest a better name instead

Rule: "A comment that says // increment counter above i++ adds zero value. If you feel the need to explain WHAT code does, that's a signal the code itself needs a better name."

Do NOT apply changes.
```

### SAFE
```
Clean up comments in [PACKAGE_NAME]:
- Remove all comments that only describe what the next line does (// increment i, // call service, // return result)
- Remove all commented-out code blocks (lines starting with //)

Rules:
- Do NOT remove Javadoc comments
- Do NOT remove comments that explain WHY (business reason, workaround, known limitation)
- Do NOT remove TODO/FIXME
- When removing a comment, print it so the developer can review: "Removed comment: [content] from FileName.java:LINE"
```

### AGGRESSIVE
```
Fully refactor comments in [PACKAGE_NAME]:
- Remove all what-comments (describe what code does)
- Remove all commented-out code
- For each TODO/FIXME that has no description, add a minimal context based on surrounding code: // TODO: [inferred context from method name and code]
- If a what-comment is the only documentation for a poorly named method/variable, DO NOT remove the comment — instead suggest a rename in a separate report section: "Consider renaming X to Y (currently explained only by comment)"

Output two sections:
1. Changes applied
2. Rename suggestions based on comment analysis
```

---

## 🧪 11. TESTS

### EDUCATIONAL
```
Analyze test files in [PACKAGE_NAME] for assertion clarity issues:
- assertEquals(true, x) instead of assertTrue(x)
- assertEquals(false, x) instead of assertFalse(x)
- assertEquals(null, x) instead of assertNull(x)
- assertFalse(list.isEmpty()) instead of assertFalse with better message

For each issue:
1. Show BEFORE
2. Show AFTER
3. Explain: e.g. "assertTrue(x) reads as a sentence — 'assert that x is true'. assertEquals(true, x) forces the reader to parse it as a comparison. When the test fails, assertTrue gives a cleaner failure message too."

Do NOT apply changes.
```

### SAFE
```
Improve test assertions in test files in [PACKAGE_NAME]:
- Replace assertEquals(true, x) with assertTrue(x)
- Replace assertEquals(false, x) with assertFalse(x)
- Replace assertEquals(null, x) with assertNull(x)
- Replace assertNotEquals(null, x) with assertNotNull(x)

Rules:
- Apply to JUnit 4 and JUnit 5 style assertions
- Do NOT change AssertJ or Hamcrest assertions
- Do NOT change assertion messages
- Print each change with file and line
```

### AGGRESSIVE
```
Fully modernize test assertions in [PACKAGE_NAME]:
- Apply all SAFE changes
- Replace assertTrue(list.size() == N) with assertEquals(N, list.size())
- Replace assertTrue(list.isEmpty()) with assertThat(list).isEmpty() if AssertJ is on classpath, otherwise keep assertTrue
- Replace assertNotNull(x); assertEquals(expected, x); pairs with a single assertEquals (assertNotNull is redundant when assertEquals would fail on null anyway)
- Replace assertTrue(str.contains("x")) with assertThat(str).contains("x") if AssertJ available

Print: X assertions modernized, Y redundant assertions removed
```

---

## 🎯 MEGA PROMPTS — all groups at once

### EDUCATIONAL (full scan)
```
Perform a full educational code review of [PACKAGE_NAME].

Scan for ALL of the following categories and report findings:
1. Naming — abbreviations, non-question booleans, redundant context, constant style
2. Logic — boolean return simplification, x==true patterns, double negations
3. Structure — magic numbers, repeated strings, dead code, System.out, lambda→method reference
4. Null safety — missing @NotNull/@Nullable, null collection returns
5. Immutability — final candidates (local vars and parameters only)
6. Formatting — missing logical grouping, import order, logger inconsistency
7. Exceptions — empty catch blocks, unnecessary casts
8. Boilerplate — missing @Override
9. Collections — for→forEach, isEmpty(), raw types, diamond operator
10. Comments — what-comments, commented-out code
11. Tests — assertEquals(true/false/null) patterns

Output format per finding:
CATEGORY | FILE:LINE | BEFORE | AFTER | WHY

At the end, print a score:
"Found X issues across 11 categories. Top 3 categories by issue count: ..."
```

### SAFE (full refactor)
```
Apply all SAFE refactoring to [PACKAGE_NAME].

Apply in this order (to avoid conflicts):
1. Remove unused imports
2. Add @Override to all eligible methods
3. Fix isEmpty() patterns (size()==0, size()>0)
4. Add diamond operator where missing
5. Fix for-each where index unused
6. Simplify boolean returns (if x return true else return false → return x)
7. Fix x==true / x==false patterns
8. Add final to local variables and parameters
9. Add @NotNull/@Nullable based on usage
10. Replace null collection returns with List.of() / Collections.emptyList()
11. Extract magic numbers to constants
12. Remove System.out.println
13. Fix empty catch blocks (add logging)
14. Remove what-comments
15. Fix assertEquals(true/false/null) in tests

Rules:
- Do NOT touch public API signatures
- Do NOT touch fields
- Do NOT add Lombok
- After all changes, print a single summary table:
  Category | Files changed | Changes applied
```

### AGGRESSIVE (full refactor)
```
Apply aggressive but safe refactoring to [PACKAGE_NAME].

Apply all changes from the SAFE prompt, plus:
- Rename abbreviations and improve names (local vars, parameters, private members)
- Extract complex boolean conditions to named variables
- Convert eligible lambdas to method references
- Reorder class members (fields → constructors → public → private)
- Unify loggers to SLF4J
- Add Objects.requireNonNull for @NotNull public method parameters
- Clean TODO/FIXME with context
- Modernize test assertions to AssertJ if available, otherwise JUnit semantic assertions
- Add final to private fields not touched by frameworks (no Spring/JPA annotations)

Rules:
- Do NOT change public method signatures
- Do NOT add @Builder or @EqualsAndHashCode
- Do NOT convert loops to streams if loop has side effects
- Do NOT convert finally to try-with-resources
- Do NOT narrow catch(Exception) if not all thrown types are visible

Final output:
1. Full changelog grouped by category
2. List of skipped items with reason
3. Recommendations for manual review (things AI left untouched intentionally)
```
