# Claude Code — AGGRESSIVE Refactoring Prompts (review the diff)

These prompts contain refactorings that are **low-risk but NOT guaranteed safe** — they can
change runtime behavior, serialization, framework wiring, or test outcomes. Two groups live here:

1. **Demoted-from-SAFE** rules — they compile cleanly but can silently change behavior
   (null→empty collections, field renames, `System.out` deletion, lambda→method-ref, for→for-each).
2. **Maximizing** rules — broader rewrites (streams, final fields/classes, constructor/Lombok
   generation, logger unification, exception narrowing).

**Run these on a branch. Review the diff. Run the full test suite before committing.**
Each higher-risk operation is tagged ⚠ with its concrete failure mode.

The educational "why this refactor is good" prompts live in `claude-code-refactor-prompts-safe.md`.
Each category below assumes you first apply that file's SAFE prompt for the same category.

Replace `[PACKAGE_PATH]` with a real path.

---

## ✅ Verification gate (run this as part of every AGGRESSIVE prompt)

```
Process one category at a time. After applying a category to all files in [PACKAGE_PATH]:
  1. Compile:  mvn -q test-compile        (or: ./gradlew compileJava compileTestJava)
  2. Test:     mvn -q test                (or: ./gradlew test)
  3. If compile OR tests FAIL:
     - git checkout -- [PACKAGE_PATH]   (revert the whole category)
     - Report which file/edit caused the failure and what broke
     - STOP — do not continue to the next category
  4. If green: continue, but still REVIEW THE DIFF before committing.

Tests are run here (unlike the SAFE file) because these rules CAN change behavior, and a
behavior change only surfaces when tests run. If the project has no tests for an affected area,
treat the change as unverified and flag it for manual review.
```

---

## 🏷️ 1. NAMING (aggressive)
```
First apply NAMING from the SAFE file (locals/params). Then, for each .java file:
1. Read the file
2. Apply:
   - Rename boolean FIELDS to question form (active → isActive)
   - Remove redundant class prefix from private fields (User.userName → User.name)
   - Rename mis-cased constants to SCREAMING_SNAKE_CASE
     ⚠ Field/constant renames can break: Jackson/Gson JSON keys, JPA @Column mapping,
       reflection, and any reference from another file.
     GUARD: skip a field rename if the class is annotated for serialization/persistence
       (@Entity, @Table, @JsonProperty/@JsonSerialize present, MapStruct, etc.) or the field
       has a serialization annotation — unless you also update every mapping and caller.
   - Rename private methods that are too generic (check() → isValid(), get() → fetchOrder())
     by inferring intent from the body; de-abbreviate private method names; private boolean
     methods → question form
     ⚠ skip if the method may be invoked reflectively / by name string.
3. Update every reference within the file. Print a changelog: File | Old | New | Reason
4. Save.

Hard rules:
- Do NOT rename anything public or package-private
- Do NOT rename if intent is ambiguous — skip and note it
```

---

## 🔀 2. LOGIC (aggressive)
```
First apply LOGIC from the SAFE file. Then, for each .java file:
1. Read the file
2. Apply:
   - Extract complex inline conditions (2+ boolean operators) to a named boolean variable on the
     line directly above the if; name it for business intent
   - Convert deeply nested if blocks (3+ levels) to guard clauses with early return
     ⚠ Inverting conditions (De Morgan) and reordering control flow is error-prone.
     ONLY when no unconditional code after the nested block would be skipped, and there is no
     else branch whose semantics would change. Add: // guard: [reason]
3. Print: "FileName.java — X extractions, Y guard clauses"
4. Save.
```

---

## 🧱 3. CODE STRUCTURE (aggressive)
```
First apply STRUCTURE from the SAFE file. Then, for each .java file:
1. Read the file
2. Apply:
   - System.out handling (demoted from SAFE):
     classify each System.out — clearly debug/throwaway → delete; appears to be real application
     output → convert to log.info(...) via the existing logger, or add an SLF4J logger if missing
     ⚠ deleting stdout breaks CLI tools and tests that capture System.out;
       adding a logger needs SLF4J on the classpath.
   - Convert lambdas to method references where the body is a single method call
     ⚠ a method reference captures the receiver at CREATION time (the lambda reads it at CALL
       time) and can resolve to a DIFFERENT overload. Skip if the receiver may be reassigned,
       or if the target method is overloaded.
   - Remove unused private methods and fields with no framework annotations
     ⚠ reflection/serialization usage is invisible. The annotation whitelist is NOT exhaustive —
       also skip @Value, @Inject, @PersistenceContext, @PostConstruct, @PreDestroy, Mockito
       @Mock/@InjectMocks/@Spy/@Captor, JUnit @RegisterExtension, and any field a serializer/JPA
       may set reflectively. When in doubt, keep it and flag it.
   - Reorder class members: static fields → instance fields → constructors → public → package →
     private → inner classes
     ⚠ static and instance field initializers run in DECLARATION order. Do NOT reorder fields
       whose initializers reference earlier fields — keep their relative order.
   - If a private method is called exactly once and its body is under 3 lines, inline it
3. Print a full report.
4. Save.
```

---

## 🔒 4. NULL SAFETY (aggressive)
```
First apply NULL SAFETY from the SAFE file (documentation annotations). Then, for each .java file:
1. Read the file
2. Apply:
   - Replace "return null" with an empty collection (demoted from SAFE):
     List.of() / Set.of() / Map.of() / Collections.empty* — for List/Set/Map/Collection returns
     ⚠ callers that branch on null (if (result == null)) will take a different path, and tests
       asserting assertNull(result) will fail. Verify call sites and tests first.
   - Add Objects.requireNonNull(param, "param must not be null") at the top of each public method
     for every @NotNull parameter lacking a null check
     ⚠ this NOW THROWS where null was previously tolerated — it is the runtime-enforcement layer
       for the documentation @NotNull contracts. Existing callers/tests passing null will break.
   - Replace x != null ? x : default → Objects.requireNonNullElseGet(x, () -> default)
     ⚠ use the ...ElseGet (lazy) form, NOT requireNonNullElse: the eager form evaluates `default`
       even when x is non-null (losing side-effect/laziness) and NPEs if both are null.
3. Print a null-safety report per file.
4. Save.
```

---

## 🧊 5. IMMUTABILITY (aggressive)
```
First apply IMMUTABILITY from the SAFE file (locals/params). Then, for each .java file:
1. Read the file
2. Apply:
   - Add final to private fields that are: assigned only in the constructor; have no setter;
     and are NOT annotated @Autowired/@Inject/@Value/@PersistenceContext/@Column
     ⚠ a final field cannot be set reflectively after construction — this breaks Jackson/JPA
       deserialization that constructs then populates. Skip fields in classes a serializer/ORM
       may hydrate.
   - Add final to the class declaration if no class in [PACKAGE_PATH] extends it and it has no
     @Component/@Service/@Repository
     ⚠ a final class CANNOT be mocked by Mockito (Cannot mock final class), proxied by Spring
       CGLIB (@Configuration, @Transactional on a concrete class), or subclassed by Hibernate
       lazy proxies. Also it may be extended OUTSIDE this package. Skip if the class is mocked in
       tests, is a Spring proxy target, or is an @Entity.
3. Print: "FileName.java — finalized X fields, Y classes (Z skipped: [reasons])"
4. Save.
```

---

## 🧹 6. FORMATTING AND STYLE (aggressive)
```
Step 1 — scan all .java files in [PACKAGE_PATH]: determine the dominant logger by counting
  actual usage in source (NOT from pom.xml); note import/style inconsistencies.
Step 2 — first apply FORMATTING from the SAFE file. Then, for each file:
1. Read the file
2. Apply:
   - Unify ALL loggers to SLF4J:
     private static final Logger log = LoggerFactory.getLogger(ClassName.class);
     ⚠ requires SLF4J on the classpath; changes log configuration/output and may break tests that
       assert on log content or config. (size()==0 → isEmpty() is owned by Collections — not here.)
   - Remove trailing whitespace
   - Normalize blank lines: max 1 consecutive inside a method body, max 2 between methods
     ⚠ NEVER touch whitespace inside a text block (\"\"\" ... \"\"\") — trailing spaces and blank
       lines there are part of the string value. Leave text-block content byte-for-byte.
3. Print a consistency report per file.
4. Save.
```

---

## ⚠️ 7. EXCEPTIONS (aggressive)
```
First apply EXCEPTIONS from the SAFE file. Then, for each .java file:
1. Read the file
2. Apply:
   - For empty catch blocks with NO existing logger: add an SLF4J logger declaration, then the
     log.warn(...) line
     ⚠ requires SLF4J on the classpath.
   - Where catch(Exception e) is used: if ALL calls in the try only declare specific checked
     exceptions visible in this file, narrow catch to those types; if ambiguous, skip and add
     // TODO: narrow exception type — currently catching Exception broadly
     ⚠ narrowing lets previously-caught UNCHECKED exceptions (NPE, IllegalArgument, etc.) escape,
       changing runtime error handling. Only narrow when you are sure nothing else can be thrown.
   - Where a catch only does throw new RuntimeException(e): ensure the cause is passed; if not,
     fix it; if yes, add // wrapping checked exception — intentional
3. Print: "FileName.java — X loggers added, Y catches narrowed, Z skipped"
4. Save.
```

---

## 🧩 8. ANNOTATIONS AND BOILERPLATE (aggressive)
```
First apply BOILERPLATE from the SAFE file (@Override). Read pom.xml/build.gradle once for Lombok.
Then, for each .java file:
1. Read the file
2. Apply:
   - If the class has fields but no constructor: generate an all-fields constructor (access
     matches the class)
     ⚠ adding ANY constructor removes the implicit no-arg constructor → breaks JPA @Entity,
       Jackson deserialization, and Spring instantiation that need a default constructor, and
       any subclass calling super(). Skip @Entity / classes a serializer instantiates; if unsure,
       also keep an explicit no-arg constructor.
   - If Lombok is a dependency: replace hand-written single-line getters/setters with
     @Getter / @Setter at FIELD level
     ⚠ Lombok @Getter on a boolean field `active` generates isActive() (not getActive()) — update
       callers, or skip. Never replace an accessor that has custom logic (defensive copy, lazy
       init, validation, side effects) — only truly trivial one-liners.
3. Print a change summary per file.
4. Save.

Hard rules:
- Do NOT add @Builder or @EqualsAndHashCode
- Do NOT add Lombok if it is not already a dependency
```

---

## 🔧 9. LOOPS AND COLLECTIONS (aggressive)
```
First apply COLLECTIONS from the SAFE file. Read pom.xml once for the Java version. Then, per file:
1. Read the file
2. Apply:
   - Convert indexed for loop → for-each when index i is used only for list.get(i) (demoted from SAFE)
     ⚠ for-each uses an iterator: if the loop body adds/removes from the list, it throws
       ConcurrentModificationException where the indexed loop did not. Also an indexed loop
       re-reads size() each iteration (sees additions); for-each does not. Skip if the body
       mutates the collection.
   - Add generics to raw types where unambiguous (infer from add() args, return type, assignment)
   - Convert simple for-each loops to Stream for these patterns ONLY:
     (a) filter: if + list.add(item) → .filter().collect()
     (b) map: transform each element into another list → .map().collect()
     (c) count: counter++ → .count()
     ⚠ skip if the loop has break/return/throw, a checked exception in the body, multiple side
       effects, or accumulates into a list used elsewhere.
   - Replace Collections.unmodifiableList(new ArrayList<>(source)) → List.copyOf(source), Java 10+ only
     ⚠ List.copyOf THROWS NullPointerException if source contains null elements (unmodifiableList
       did not). Skip if the list may hold nulls.
3. Print: "FileName.java — X for-each, Y generics, Z streams, W copyOf"
4. Save.
```

---

## 💬 10. COMMENTS (aggressive)
```
First apply COMMENTS from the SAFE file. Then, for each .java file:
1. Read the file
2. Apply:
   - For TODO/FIXME with no description: add context inferred from surrounding code
     // TODO: [method] — [inferred intent]
   - If a what-comment is the ONLY documentation for a poorly named method/variable: do NOT
     remove it — instead emit a rename suggestion (this prompt does not perform the rename)
3. Output two sections: (1) changes applied  (2) rename suggestions
4. Save.
```

---

## 🧪 11. TESTS (aggressive)
```
First apply TESTS from the SAFE file. Check pom.xml/build.gradle once for AssertJ. Then, per file:
1. Read the file
2. Apply:
   - assertTrue(list.size() == N) → assertEquals(N, list.size())
   - assertTrue(list.isEmpty()) → assertThat(list).isEmpty()  (only if AssertJ is available)
   - assertTrue(str.contains("x")) → assertThat(str).contains("x")  (only if AssertJ is available)
     ⚠ AssertJ conversions require org.assertj on the classpath and the assertThat static import —
       add the import, or skip. Otherwise the test will not compile.
   - assertNotNull(x) immediately followed by assertEquals(expected, x) on the next line:
     remove the redundant assertNotNull
3. Print: "FileName.java — X modernized, Y redundant assertions removed"
4. Save.
```

---

## 🎯 MEGA PROMPT (AGGRESSIVE)

```
Apply aggressive refactoring to [PACKAGE_PATH]. Run on a branch; review the diff; the
Verification gate runs compile + tests after every category and reverts on red.

Step 1 — read once (do not modify yet):
  - pom.xml / build.gradle: Java version, Lombok presence, AssertJ presence,
    SLF4J presence, org.jetbrains:annotations presence
  - Scan all .java files: dominant logger (by source usage, not pom.xml), cross-file inconsistencies

Step 2 — for each category, first apply the SAFE mega prompt's operations for that area, then
  apply the AGGRESSIVE operations above. Highest-impact, each tagged with its risk:
  - Rename fields/constants/private-methods ⚠ serialization/JPA/reflection
  - Extract complex conditions; nested if → guard clauses ⚠ control-flow inversion
  - System.out → delete or log.info ⚠ CLI/stdout-capturing tests; lambdas → method refs
    ⚠ capture-timing/overload; remove unused private members ⚠ reflection; reorder members
    ⚠ init order
  - return null → empty collection ⚠ null-vs-empty callers; requireNonNull on params
    ⚠ throws on previously-tolerated null; requireNonNullElseGet (lazy)
  - final private fields ⚠ reflective deserialization; final classes ⚠ Mockito/Spring/Hibernate
  - Unify loggers to SLF4J ⚠ dependency + log behavior; whitespace normalization ⚠ text blocks
  - Narrow catch(Exception) ⚠ unchecked exceptions escape
  - Generate all-fields constructor ⚠ removes implicit no-arg ctor; Lombok getters/setters
    ⚠ boolean isX/getX, lost custom logic
  - for → for-each ⚠ ConcurrentModificationException; generics to raw types; loops → streams
    (filter/map/count, no side effects); List.copyOf ⚠ NPE on null elements
  - AssertJ assertion modernization ⚠ dependency + import

Step 3 — final output:
  1. Full changelog grouped by category and file
  2. Skipped items with reason (e.g. "final class OrderService — mocked in OrderServiceTest")
  3. Manual-review list: behavior-affecting changes that no test covered

Hard rules:
- Do NOT change public method signatures
- Do NOT add @Builder or @EqualsAndHashCode
- Do NOT add a dependency that is not already present (skip the rule and report instead)
- Do NOT convert loops with side effects to streams
- Do NOT convert finally to try-with-resources
- Do NOT narrow catch(Exception) unless all thrown types are visible in the same file
```
