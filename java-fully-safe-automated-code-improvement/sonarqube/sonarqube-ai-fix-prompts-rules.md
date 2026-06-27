# RULES REFERENCE

*69 safe, mechanical auto-fix rules. Every rule is applied automatically — no human intervention — and never changes public API, business logic, or compilation. Rules that could only add a `// TODO` flag, or whose fix could change runtime behavior or require guessing intent, were moved to `sonarqube-excluded-rules.md`.*

> **GUARD convention.** Most rules below carry an inline `— GUARD:` / `— skip if …` clause. A GUARD names the one edge case where the fix would compile cleanly yet change behavior, fail a test, or fail a CI gate. **The fix is only "safe, fully automatic" while its GUARD holds — if a GUARD condition is met, SKIP the rule for that occurrence and note it; do not guess.** Guards are what make the compile-only / no-human-review posture actually true.

---

## NAMING

- Local/param camelCase: `String UserName = ...` → `userName` (S117)
  — GUARD: rename only LOCAL variables and parameters of NON-public/protected methods that carry no web/binding/serialization annotation (Spring `@RequestParam`/`@PathVariable`, JAX-RS `@PathParam`/`@QueryParam`, Jackson `@JsonProperty`/`@JsonCreator`, MapStruct) — those param names are reflectively bound. Skip if the new name shadows a field in scope or collides with an existing local/param.
- Type param single uppercase or ends with T: `<type>` → `<T>` · `<orderType>` → `<OrderT>` (S119)
  — GUARD: skip if the new name collides with a visible class/type in scope; update any matching `@param <oldName>` Javadoc tag in the same comment.

---

## DEAD CODE

- Remove unused imports (S1128)
  — GUARD: keep any import still referenced in Javadoc (`{@link}`, `{@linkplain}`, `{@value}`, `@see`, `@throws`) or in a sibling `package-info.java`.
- Remove unused parameters — ONLY in private methods (S1172)
  — GUARD: skip if the method is invoked via reflection or used as a method reference / functional-interface target whose arity matters; update every call site in the same compilation unit.
- Remove unused local variables (S1481)
  — GUARD: only when the initializer is a pure value (literal, field read, simple expression). Skip if the initializer has a side effect (method call, assignment, `++`/`--`) — removing it would drop the call.

---

## NULL AND BOOLEAN

- Remove redundant booleans: `if (x == true)` → `if (x)` · `if (x == false)` → `if (!x)` · `return x == true` → `return x` (S1125)
  — GUARD: only when the operand is a primitive `boolean`. Skip a boxed `Boolean` — `x == true` unboxes (NPE on null) while `return x` would return `null`, i.e. the rewrite changes null/unboxing behavior.
- Remove else after jump: `if (x) { return a; } else { b(); }` → `if (x) { return a; } b();` (S1126)
  — GUARD: only when the `if` branch ALWAYS exits on every path (return/throw/break/continue). Skip if it can fall through (e.g. a conditional return, or a `throw` inside a try that is caught).
- isEmpty() over size(): `list.size() == 0` → `list.isEmpty()` · `list.size() > 0` → `!list.isEmpty()` (S1155)
  — GUARD: only for `java.util.Collection` / `Map` / `CharSequence`. Skip custom types whose `isEmpty()` may not equal `size() == 0`, and concurrent collections (`ConcurrentLinkedQueue`) where the two are not equivalent.

---

## CODE STYLE

- Remove redundant parens: `return (x + y)` → `return x + y` — keep if clarifying precedence: `(a + b) * c` (S1110)
  — GUARD: remove only parens that are redundant by Java precedence AND associativity. Keep any that affect grouping, e.g. `x - (a - b)`, `a / (b * c)`.
- Extract assignment from condition: `if ((x = compute()) != null)` → `x = compute(); if (x != null)` (S1121)
  — GUARD: ONLY inside an `if`. NEVER in a `while` / `for` condition — the assignment must re-run each iteration, so hoisting it out turns the loop into an infinite/incorrect loop.
- Canonical modifier order public/protected/private → abstract → static → final: `final static public int X` → `public static final int X` (S1124)
  — GUARD: reorder keyword modifiers only; never move a (type-use) annotation across the type or relative to the modifiers.
- 3+ duplicate string literals → `private static final String CONSTANT_NAME = "value"` (SCREAMING_SNAKE_CASE) (S1192)
  — GUARD: skip if the chosen constant name collides with or shadows an existing/inherited field. Only extract occurrences within ONE class; don't reach into other files for a `private` constant.
- Array type on type not variable: `int a[]` → `int[] a` · `String m()[]` → `String[] m()` (S1195, S1197)
  — GUARD: skip multi-variable declarations like `int a[], b;` — moving `[]` to the type (`int[] a, b;`) would silently make `b` an array too.
- Remove non-case labels from switch (S1219)
  — GUARD: skip if the label is the target of a `break label;` / `continue label;` anywhere in scope.
- for→while when loop variable unused in update: `for (; cond;)` → `while (cond)` (S1264)
  — GUARD: only when the `for` has an EMPTY init and EMPTY update. Skip if the init declares a variable — converting would relocate/leak its scope.
- public static field must be final — skip if assigned outside declaration (S1444)
  — GUARD (extend): also skip if the field is set via reflection, or is an inter-module constant where a future value change must NOT be inlined into other compilation units.
- Deprecated collection constants: `Collections.EMPTY_LIST` → `Collections.emptyList()` · `EMPTY_MAP` → `emptyMap()` · `EMPTY_SET` → `emptySet()` (S1596)
  — GUARD: skip if the raw constant feeds a method overloaded on raw `List` vs `List<T>`, or if a `-Werror` rawtypes build depends on the raw form.
- Merge identical catch bodies: `catch(A e){ log(e); } catch(B e){ log(e); }` → `catch(A|B e){ log(e); }` — skip if bodies differ even slightly (S2147)
  — GUARD (extend): also skip if the caught types are in a subtype relationship (illegal multicatch), or if `e` is passed to a method overloaded on the specific exception types (merge would change overload resolution).
- Dissimilar ternary types → explicit cast: `cond ? intVal : longVal` → `cond ? (long) intVal : longVal` (S2154)
  — GUARD: skip if either operand is a boxed wrapper (`Integer`/`Long`/…) — inserting the cast changes unboxing / NPE timing.
- Static via derived type → declaring class: `Child.PARENT_CONSTANT` → `Parent.PARENT_CONSTANT` (S3252)
  — GUARD: skip if `Child` hides the member with its own declaration (different value), or if changing the qualifier changes which class's static initializer runs first.
- Double brace init → explicit add(): `new ArrayList<>(){{ add("a"); }}` → `List<String> list = new ArrayList<>(); list.add("a");` (S3599)
  — GUARD: skip if the anonymous subtype is observed — `getClass()` checks, serialization (it captures the outer `this`), or the instance's specific type leaks out.
- Single-line if → add braces: `if (x) doIt();` → `if (x) { doIt(); }` (S3973)
  — GUARD: brace exactly the controlled statement; preserve dangling-`else` association.
- Remove redundant field assignments — skip if class `@Entity`/`@MappedSuperclass`/`@Embeddable` or field `@Column`/`@Id`/`@Transient` (S4165)
  — GUARD (extend): also skip if the field is `volatile` (the write may be a memory barrier) or is read via an overridable method called during construction.
- `Integer.toHexString(n)` → `String.format("%x", n)` (S4425)
  — GUARD: only for primitive `int`/`long`; preserve width. Skip boxed/nullable operands (`String.format` NPEs on null, `toHexString` wouldn't compile with null) — and note the result is hot-path slower.
- Remove `@Nonnull`/`@NonNull` from equals() param: `equals(@Nonnull Object o)` → `equals(Object o)` (S4454)
  — GUARD: skip if a null-analysis tool that instruments/enforces the annotation (NullAway, IntelliJ "treat as error") is active in the build.
- String charset → StandardCharsets: `"UTF-8"` → `StandardCharsets.UTF_8` · `"ISO-8859-1"` → `StandardCharsets.ISO_8859_1` (S4719)
  — GUARD: the `Charset` overload does not throw `UnsupportedEncodingException`. If switching makes an existing `catch (UnsupportedEncodingException)` / `throws` dead, remove it too; if that change cascades to callers, skip.
- `str.length() == 0` → `str.isEmpty()` · `str.length() > 0` → `!str.isEmpty()` (S7158)
  — GUARD: `String` is fine on any target. For `StringBuilder`/`StringBuffer`/other `CharSequence`, `isEmpty()` requires Java 15+ — skip on older targets.

---

## STRING

- `str.toString()` on String → `str` (S1858)
  — GUARD: only when the receiver's compile-time type is exactly `String` AND it cannot be null at that point — `str.toString()` NPEs on null, `str` does not, so removal would suppress an exception.
- Log string concat → parameterized: `log.debug("v: " + x)` → `log.debug("v: {}", x)` (S2629)
  — GUARD: only for SLF4J / Log4j2 parameterized loggers. Skip `java.util.logging` and any logger that does not interpret `{}`. Skip if `x.toString()` has side effects (it now runs only when the level is enabled) or the message already contains a literal `{}`.

---

## LAMBDA AND FUNCTIONAL

- Assign-then-return → direct return: `T r = compute(); return r;` → `return compute();` — skip if variable used in finally or try-with-resources (S1488)
  — GUARD (extend): also skip if `r` is captured by a lambda or anonymous class created between the assignment and the return.
- Lambda block single return → expression: `x -> { return x.getName(); }` → `x -> x.getName()` (S1602)
  — GUARD: skip if it introduces target-type ambiguity between overloads (e.g. a method overloaded on `Function` vs `Consumer`).
- Remove parens around single lambda param: `(x) -> x.getName()` → `x -> x.getName()` (S1611)
  — GUARD: only a single param with no explicit type and no annotation (`(@NonNull var x)` / `(int x)` keep their parens).
- Thread wrapping Thread → lambda: `new Thread(myThread)` where myThread is Thread → `new Thread(() -> myThread.run())` (S2438)
  — GUARD: skip if `myThread` is reassigned before the new thread starts — the lambda captures the variable, the original passed the value.
- ThreadLocal anonymous class → `ThreadLocal.withInitial(ArrayList::new)` (S4065)
  — GUARD: only when the anonymous class overrides ONLY `initialValue()` with a side-effect-free constructor. Skip if it overrides other methods (`childValue`, `get`, `set`) or the initializer does more than `new`.

---

## EXCEPTION HANDLING

- Remove `runFinalizersOnExit()` call entirely (S2151)
  — GUARD: a no-op on Java 11+. On Java 8 skip if anything relied on exit-time finalization.

---

## COLLECTIONS AND LOOPS

- `list.size() == 0` → `list.isEmpty()` · `str.length() == 0` → `str.isEmpty()` (S1155)
  — GUARD: see S1155 above — standard `Collection`/`Map`/`CharSequence` only; skip custom/concurrent types where `isEmpty()` may differ.
- Array created for varargs: `method(new String[]{"a", "b"})` → `method("a", "b")` (S3878)
  — GUARD: skip if the target method is overloaded such that spreading changes which overload is selected (`m(String[])` vs `m(Object...)` vs a fixed-arity `m(String, String)`).
- Raw Map iteration → add generic type parameter: `Map` → `Map<String, X>` (S4838)
  — GUARD: only when the actual key/value types are unambiguous from usage. Skip if the type arguments would have to be guessed — wrong inference fails at the use sites.

---

## CONCURRENCY

- Serializable non-static inner class → add `static` keyword (S2066)
  — GUARD: skip if the inner class references any outer-instance member (won't compile), or if instances are serialized and persisted — adding `static` changes the serialized form and breaks deserialization of old data.
- enum public mutable field → `private final`: `public Status status = ACTIVE` → `private final Status status` (S3066)
  — GUARD: skip if the field is reassigned anywhere (final would break it) or read by external callers (`public` → `private` is an API break).

---

## SERIALIZATION

- Externalizable class missing no-args constructor → add `public ClassName() {}` (S2060)
  — GUARD: ensure any `final` fields remain definitely assigned; skip if a framework selects constructors by signature and could now pick the new no-arg ctor over the intended one.
- Serialization method signatures must be exactly:
  `private void writeObject(ObjectOutputStream oos) throws IOException`
  `private void readObject(ObjectInputStream ois) throws IOException, ClassNotFoundException` (S2061)
  — GUARD: only when the method is genuinely the serialization hook. Skip an ordinary same-named method — "fixing" its signature would silently activate it as a serialization callback.
- `private Object readResolve()` → `protected Object readResolve()` (S2062)
  — GUARD: skip if the class is subclassed and the canonical-instance / singleton logic must not be inherited by subtypes.
- Cloneable missing clone() → add: `@Override public Object clone() { try { return super.clone(); } catch (CloneNotSupportedException e) { throw new AssertionError(); } }` (S2157)
  — GUARD: `super.clone()` is a SHALLOW copy. Skip (and leave a note/TODO) if the class has mutable reference fields that callers would expect to be deep-copied — the generated clone would alias them.
- Remove `synchronized` keyword from readObject() (S2675)
  — GUARD: skip if deserialization relies on that lock for thread-safety.

---

## ANNOTATIONS AND BOILERPLATE

- Add missing @Override on methods overriding or implementing (S1161)
  — GUARD: skip on `-source 5` for INTERFACE implementations — `@Override` on them is illegal before Java 6.
- `public void finalize()` → `protected void finalize()` (S1174)
  — GUARD: skip if `finalize()` is invoked externally or via reflection (narrowing access would break the caller).
- Unwrap @Repeatable container: `@Xs({@X("a"), @X("b")})` → `@X("a") @X("b")` — only when annotation is declared @Repeatable (S1710)
  — GUARD: skip if any reflection reads the container type directly (`getAnnotation(Xs.class)`) — after unwrapping it returns null.
- Child method matches parent signature but missing @Override → add @Override (S2177)
  — GUARD: only for genuine overrides; skip bridge/erasure coincidental matches; same Java-5 interface caveat as S1161.
- Remove `@Nonnull`/`@NonNull` from equals() parameter (S4454)
  — GUARD: skip if a null-analysis tool enforces the annotation in the build (see S4454 above).
- `@CheckForNull`/`@Nullable`/`@NotNull` on primitive type → remove annotation (S4682)
  — GUARD: skip if a code generator or validation tool keys on the annotation's presence.

---

## SPRING

- @RequestMapping method is private → change to public or package-private (S3751)
  — GUARD: skip if widening visibility would activate a previously-inert handler (a new live, possibly unsecured route) — confirm the endpoint is intended to be exposed.
- Single constructor annotated @Autowired → remove @Autowired (Spring injects single constructor automatically) (S6818)
  — GUARD: only on Spring Framework 4.3+ with default single-constructor injection and no custom processor that scans for `@Autowired`. Skip on older Spring or if a second constructor exists.
- @Controller where every declared method has @ResponseBody → replace @Controller with @RestController and remove @ResponseBody from all methods — skip if even one declared method lacks @ResponseBody (S6833)
  — GUARD (extend): "every method" must include INHERITED and interface-default handler methods. Skip if any such method lacks `@ResponseBody` — `@RestController` would force body semantics on it and turn a returned view name into a literal response body.
- Path variable in mapping without @PathVariable: `@GetMapping("/x/{id}") Order get(Long id)` → `Order get(@PathVariable Long id)` — verify param name matches template (S6856)
  — GUARD: skip if the parameter is resolved by another mechanism (custom `HandlerMethodArgumentResolver`, model attribute, request body). Require the param name to equal the template variable, or add an explicit `@PathVariable("id")` — otherwise it throws `MissingPathVariableException` at runtime.

---

## TEST QUALITY

- Assertion inside try-catch(Error) → extract assertion to after the try-catch block (S5779)
  — GUARD: skip if the test intentionally catches its own `AssertionError` (testing failure handling).
- JUnit5 inner test class missing @Nested → add @Nested (S5790)
  — GUARD: only when the inner class actually contains `@Test` methods meant to run. Skip helper/fixture inner classes — `@Nested` would make JUnit execute them.
- JUnit5 test class/method not visible → ensure class public + method public or package-private with @Test (S5810)
  — GUARD: confirm the test is meant to run; skip if it was deliberately made invisible to disable it.
- `.as()` after assertion → move before: `assertThat(x).isEqualTo(y).as("d")` → `assertThat(x).as("d").isEqualTo(y)` (S5833)
  — GUARD: the trailing `.as()` is currently a no-op; moving it makes the description take effect. Skip if a test asserts on the (previously empty) failure-message text.
- `assertThat(x).isEqualTo(x)` same object → remove (always passes) (S5863)
  — GUARD: only when both sides are the SAME symbol/literal. Skip if the expression has side effects (`assertThat(next()).isEqualTo(next())`) — removal would drop the calls.
- `Mockito.when(...)` → static import `when(...)` (S6068)
  — GUARD: skip if `when` already resolves to a different symbol or static import in scope.

---

## SECURITY (MECHANICAL)

- Remove `runFinalizersOnExit()` call (S2151)
  — GUARD: see S2151 above (Java 8 caveat).
- `File.createTempFile(...)` → `Files.createTempFile(...)` — adjust call site if it expects a `File` (S5445)
  — GUARD: it returns `Path`, not `File` (adjust the call site or `.toFile()`). Note the new file gets restrictive 0600 POSIX permissions — skip if another process or user must read the temp file.

---

## STRUCTURE

- compareTo() returns Integer.MIN_VALUE → return -1 (MIN_VALUE negated is still MIN_VALUE, breaks contract) (S2167)
  — GUARD: skip if any code compares the result against the sentinel `Integer.MIN_VALUE`.
- compareTo() overloaded with non-Object param → remove the overload (S4351)
  — GUARD: skip if callers or method references bind to the specific-typed overload (removal would change resolution or fail to compile).
- `Double.longBitsToDouble(intVal)` → `Double.longBitsToDouble((long) intVal)` (S2127)
  — GUARD: the cast is semantics-neutral (the widening already happens). Do NOT treat it as a fix — if the real intent may be `Float.intBitsToFloat`, flag it instead of silently casting.
- Interface method already declared in parent interface → remove redundant declaration (S3038)
  — GUARD: skip if the re-declaration adds anything — a covariant return type, a default body, Javadoc, or annotations (`@Deprecated`, validation).
- Explicit resource.close() inside try-with-resources → remove (closed automatically) (S4087)
  — GUARD: skip if the explicit `close()` is an intentional EARLY release (the resource is used again later in the same block, or a lock/flush must happen before subsequent statements).
- `Class.forName("com.mysql.jdbc.Driver")` → remove entirely (JDBC 4.0+ auto-loads drivers) (S4925)
  — GUARD: skip if the driver's `META-INF/services` auto-registration may be absent — shaded/repackaged/uber-jars can strip it, and removal then yields "No suitable driver" at runtime.
- Static member via instance → via class: `instance.staticField` → `ClassName.staticField` (S2209)
  — GUARD: skip if the instance expression has a side effect (`getThing().STATIC`) — rewriting to `ClassName.STATIC` would drop the call.
- `map.keySet()` when value also needed → use entrySet(): `for (Map.Entry<K,V> e : map.entrySet()) { e.getKey(); e.getValue(); }` (S2864)
  — GUARD: skip lazy/computing/defaulted maps, or loops that mutate the map, where `entry.getValue()` would differ from a fresh `map.get(k)`.
