# RULES REFERENCE

*69 safe, mechanical auto-fix rules. Every rule is applied automatically — no human intervention — and never changes public API, business logic, or compilation. Rules that could only add a `// TODO` flag, or whose fix could change runtime behavior or require guessing intent, were moved to `sonarqube-excluded-rules.md`.*

> **How to read each rule:** `**Sxxxx** — what it does: before → after`, followed by an indented **Guard**.
> The **Guard** is the safety boundary — the one edge case where the fix would compile cleanly yet change
> behavior, fail a test, or fail a CI gate. **Apply the fix only while its Guard holds; if a Guard condition
> is met for an occurrence, SKIP it and note it — do not guess.** The guards are what make the compile-only /
> no-human-review posture actually true. Each category header lists its rule IDs for quick auditing.

---

## NAMING · S117 · S119

- **S117** — Local/param camelCase: `String UserName = ...` → `String userName = ...`
  - **Guard:** rename only LOCAL variables and parameters of NON-public/protected methods that carry no web/binding/serialization annotation (Spring `@RequestParam`/`@PathVariable`, JAX-RS `@PathParam`/`@QueryParam`, Jackson `@JsonProperty`/`@JsonCreator`, MapStruct) — those parameter names are reflectively bound. Skip if the new name shadows a field in scope or collides with an existing local/param.
- **S119** — Type param single uppercase or ends with `T`: `<type>` → `<T>` · `<orderType>` → `<OrderT>`
  - **Guard:** skip if the new name collides with a visible class/type in scope; update any matching `@param <oldName>` Javadoc tag in the same comment.

---

## DEAD CODE · S1128 · S1172 · S1481

- **S1128** — Remove unused imports
  - **Guard:** keep any import still referenced in Javadoc (`{@link}`, `{@linkplain}`, `{@value}`, `@see`, `@throws`) or in a sibling `package-info.java`.
- **S1172** — Remove unused parameters — ONLY in private methods
  - **Guard:** skip if the method is invoked via reflection or used as a method reference / functional-interface target whose arity matters; update every call site in the same compilation unit.
- **S1481** — Remove unused local variables
  - **Guard:** only when the initializer is a pure value (literal, field read, simple expression). Skip if the initializer has a side effect (method call, assignment, `++`/`--`) — removing it would drop the call.

---

## NULL AND BOOLEAN · S1125 · S1126 · S1155

- **S1125** — Remove redundant booleans: `if (x == true)` → `if (x)` · `if (x == false)` → `if (!x)` · `return x == true` → `return x`
  - **Guard:** only when the operand is a primitive `boolean`. Skip a boxed `Boolean` — `x == true` unboxes (NPE on null) while `return x` would return `null`, i.e. the rewrite changes null/unboxing behavior.
- **S1126** — Remove else after jump: `if (x) { return a; } else { b(); }` → `if (x) { return a; } b();`
  - **Guard:** only when the `if` branch ALWAYS exits on every path (return/throw/break/continue). Skip if it can fall through (e.g. a conditional return, or a `throw` inside a try that is caught).
- **S1155** — `isEmpty()` over `size()`: `list.size() == 0` → `list.isEmpty()` · `list.size() > 0` → `!list.isEmpty()`
  - **Guard:** only for `java.util.Collection` / `Map` / `CharSequence`. Skip custom types whose `isEmpty()` may not equal `size() == 0`, and concurrent collections (`ConcurrentLinkedQueue`) where the two are not equivalent.

---

## CODE STYLE · S1110 · S1121 · S1124 · S1192 · S1195 · S1197 · S1219 · S1264 · S1444 · S1596 · S2147 · S2154 · S3252 · S3599 · S3973 · S4165 · S4425 · S4454 · S4719 · S7158

- **S1110** — Remove redundant parens: `return (x + y)` → `return x + y` — keep if clarifying precedence: `(a + b) * c`
  - **Guard:** remove only parens that are redundant by Java precedence AND associativity. Keep any that affect grouping, e.g. `x - (a - b)`, `a / (b * c)`.
- **S1121** — Extract assignment from condition: `if ((x = compute()) != null)` → `x = compute(); if (x != null)`
  - **Guard:** ONLY inside an `if`. NEVER in a `while` / `for` condition — the assignment must re-run each iteration, so hoisting it out turns the loop into an infinite/incorrect loop.
- **S1124** — Canonical modifier order (public/protected/private → abstract → static → final): `final static public int X` → `public static final int X`
  - **Guard:** reorder keyword modifiers only; never move a (type-use) annotation across the type or relative to the modifiers.
- **S1192** — 3+ duplicate string literals → `private static final String CONSTANT_NAME = "value"` (SCREAMING_SNAKE_CASE)
  - **Guard:** skip if the chosen constant name collides with or shadows an existing/inherited field. Only extract occurrences within ONE class; don't reach into other files for a `private` constant.
- **S1195/S1197** — Array type on type not variable: `int a[]` → `int[] a` · `String m()[]` → `String[] m()`
  - **Guard:** skip multi-variable declarations like `int a[], b;` — moving `[]` to the type (`int[] a, b;`) would silently make `b` an array too.
- **S1219** — Remove non-case labels from a switch
  - **Guard:** skip if the label is the target of a `break label;` / `continue label;` anywhere in scope.
- **S1264** — `for`→`while` when loop variable unused in update: `for (; cond;)` → `while (cond)`
  - **Guard:** only when the `for` has an EMPTY init and EMPTY update. Skip if the init declares a variable — converting would relocate/leak its scope.
- **S1444** — `public static` field must be `final` — skip if assigned outside declaration
  - **Guard:** also skip if the field is set via reflection, or is an inter-module constant where a future value change must NOT be inlined into other compilation units.
- **S1596** — Deprecated collection constants: `Collections.EMPTY_LIST` → `Collections.emptyList()` · `EMPTY_MAP` → `emptyMap()` · `EMPTY_SET` → `emptySet()`
  - **Guard:** skip if the raw constant feeds a method overloaded on raw `List` vs `List<T>`, or if a `-Werror` rawtypes build depends on the raw form.
- **S2147** — Merge identical catch bodies: `catch(A e){ log(e); } catch(B e){ log(e); }` → `catch(A|B e){ log(e); }`
  - **Guard:** skip if the bodies differ even slightly; if the caught types are in a subtype relationship (illegal multicatch); or if `e` is passed to a method overloaded on the specific exception types (merge would change overload resolution).
- **S2154** — Dissimilar ternary types → explicit cast: `cond ? intVal : longVal` → `cond ? (long) intVal : longVal`
  - **Guard:** skip if either operand is a boxed wrapper (`Integer`/`Long`/…) — inserting the cast changes unboxing / NPE timing.
- **S3252** — Static via derived type → declaring class: `Child.PARENT_CONSTANT` → `Parent.PARENT_CONSTANT`
  - **Guard:** skip if `Child` hides the member with its own declaration (different value), or if changing the qualifier changes which class's static initializer runs first.
- **S3599** — Double-brace init → explicit `add()`: `new ArrayList<>(){{ add("a"); }}` → `List<String> list = new ArrayList<>(); list.add("a");`
  - **Guard:** skip if the anonymous subtype is observed — `getClass()` checks, serialization (it captures the outer `this`), or the instance's specific type leaks out.
- **S3973** — Single-line `if` → add braces: `if (x) doIt();` → `if (x) { doIt(); }`
  - **Guard:** brace exactly the controlled statement; preserve dangling-`else` association.
- **S4165** — Remove redundant field assignments — skip if class `@Entity`/`@MappedSuperclass`/`@Embeddable` or field `@Column`/`@Id`/`@Transient`
  - **Guard:** also skip if the field is `volatile` (the write may be a memory barrier) or is read via an overridable method called during construction.
- **S4425** — Sign-safe hex formatting: `Integer.toHexString(n)` → `String.format("%x", n)`
  - **Guard:** only for primitive `int`/`long`; preserve width. Skip boxed/nullable operands (`String.format` NPEs on null, `toHexString` wouldn't compile with null) — and note the result is hot-path slower.
- **S4454** — Remove `@Nonnull`/`@NonNull` from `equals()` param: `equals(@Nonnull Object o)` → `equals(Object o)`
  - **Guard:** skip if a null-analysis tool that instruments/enforces the annotation (NullAway, IntelliJ "treat as error") is active in the build.
- **S4719** — String charset → `StandardCharsets`: `"UTF-8"` → `StandardCharsets.UTF_8` · `"ISO-8859-1"` → `StandardCharsets.ISO_8859_1`
  - **Guard:** the `Charset` overload does not throw `UnsupportedEncodingException`. If switching makes an existing `catch (UnsupportedEncodingException)` / `throws` dead, remove it too; if that change cascades to callers, skip.
- **S7158** — `str.length() == 0` → `str.isEmpty()` · `str.length() > 0` → `!str.isEmpty()`
  - **Guard:** `String` is fine on any target. For `StringBuilder`/`StringBuffer`/other `CharSequence`, `isEmpty()` requires Java 15+ — skip on older targets.

---

## STRING · S1858 · S2629

- **S1858** — `str.toString()` on String → `str`
  - **Guard:** only when the receiver's compile-time type is exactly `String` AND it cannot be null at that point — `str.toString()` NPEs on null, `str` does not, so removal would suppress an exception.
- **S2629** — Log string concat → parameterized: `log.debug("v: " + x)` → `log.debug("v: {}", x)`
  - **Guard:** only for SLF4J / Log4j2 parameterized loggers. Skip `java.util.logging` and any logger that does not interpret `{}`. Skip if `x.toString()` has side effects (it now runs only when the level is enabled) or the message already contains a literal `{}`.

---

## LAMBDA AND FUNCTIONAL · S1488 · S1602 · S1611 · S2438 · S4065

- **S1488** — Assign-then-return → direct return: `T r = compute(); return r;` → `return compute();`
  - **Guard:** skip if the variable is used in a `finally` block or try-with-resources, or if it is captured by a lambda/anonymous class created between the assignment and the return.
- **S1602** — Lambda block single return → expression: `x -> { return x.getName(); }` → `x -> x.getName()`
  - **Guard:** skip if it introduces target-type ambiguity between overloads (e.g. a method overloaded on `Function` vs `Consumer`).
- **S1611** — Remove parens around single lambda param: `(x) -> x.getName()` → `x -> x.getName()`
  - **Guard:** only a single param with no explicit type and no annotation (`(@NonNull var x)` / `(int x)` keep their parens).
- **S2438** — Thread wrapping Thread → lambda: `new Thread(myThread)` where `myThread` is a Thread → `new Thread(() -> myThread.run())`
  - **Guard:** skip if `myThread` is reassigned before the new thread starts — the lambda captures the variable, the original passed the value.
- **S4065** — ThreadLocal anonymous class → `ThreadLocal.withInitial(ArrayList::new)`
  - **Guard:** only when the anonymous class overrides ONLY `initialValue()` with a side-effect-free constructor. Skip if it overrides other methods (`childValue`, `get`, `set`) or the initializer does more than `new`.

---

## EXCEPTION HANDLING · S2151

- **S2151** — Remove `runFinalizersOnExit()` call entirely
  - **Guard:** a no-op on Java 11+. On Java 8 skip if anything relied on exit-time finalization.

---

## COLLECTIONS AND LOOPS · S1155 · S3878 · S4838

- **S1155** — `isEmpty()` over `size()`/`length()`: `list.size() == 0` → `list.isEmpty()` · `str.length() == 0` → `str.isEmpty()`
  - **Guard:** standard `Collection`/`Map`/`CharSequence` only; skip custom/concurrent types where `isEmpty()` may differ from `size() == 0`.
- **S3878** — Array created for varargs: `method(new String[]{"a", "b"})` → `method("a", "b")`
  - **Guard:** skip if the target method is overloaded such that spreading changes which overload is selected (`m(String[])` vs `m(Object...)` vs a fixed-arity `m(String, String)`).
- **S4838** — Raw `Map` iteration → add generic type parameter: `Map` → `Map<String, X>`
  - **Guard:** only when the actual key/value types are unambiguous from usage. Skip if the type arguments would have to be guessed — wrong inference fails at the use sites.

---

## CONCURRENCY · S2066 · S3066

- **S2066** — Serializable non-static inner class → add `static` keyword
  - **Guard:** skip if the inner class references any outer-instance member (won't compile), or if instances are serialized and persisted — adding `static` changes the serialized form and breaks deserialization of old data.
- **S3066** — Enum public mutable field → `private final`: `public Status status = ACTIVE` → `private final Status status`
  - **Guard:** skip if the field is reassigned anywhere (final would break it) or read by external callers (`public` → `private` is an API break).

---

## SERIALIZATION · S2060 · S2061 · S2062 · S2157 · S2675

- **S2060** — Externalizable class missing no-args constructor → add `public ClassName() {}`
  - **Guard:** ensure any `final` fields remain definitely assigned; skip if a framework selects constructors by signature and could now pick the new no-arg ctor over the intended one.
- **S2061** — Serialization method signatures must be exactly: `private void writeObject(ObjectOutputStream oos) throws IOException` / `private void readObject(ObjectInputStream ois) throws IOException, ClassNotFoundException`
  - **Guard:** only when the method is genuinely the serialization hook. Skip an ordinary same-named method — "fixing" its signature would silently activate it as a serialization callback.
- **S2062** — `private Object readResolve()` → `protected Object readResolve()`
  - **Guard:** skip if the class is subclassed and the canonical-instance / singleton logic must not be inherited by subtypes.
- **S2157** — Cloneable missing `clone()` → add `@Override public Object clone() { try { return super.clone(); } catch (CloneNotSupportedException e) { throw new AssertionError(); } }`
  - **Guard:** `super.clone()` is a SHALLOW copy. Skip (and leave a note/TODO) if the class has mutable reference fields that callers would expect to be deep-copied — the generated clone would alias them.
- **S2675** — Remove `synchronized` keyword from `readObject()`
  - **Guard:** skip if deserialization relies on that lock for thread-safety.

---

## ANNOTATIONS AND BOILERPLATE · S1161 · S1174 · S1710 · S2177 · S4454 · S4682

- **S1161** — Add missing `@Override` on methods overriding or implementing
  - **Guard:** skip on `-source 5` for INTERFACE implementations — `@Override` on them is illegal before Java 6.
- **S1174** — `public void finalize()` → `protected void finalize()`
  - **Guard:** skip if `finalize()` is invoked externally or via reflection (narrowing access would break the caller).
- **S1710** — Unwrap `@Repeatable` container: `@Xs({@X("a"), @X("b")})` → `@X("a") @X("b")` — only when the annotation is declared `@Repeatable`
  - **Guard:** skip if any reflection reads the container type directly (`getAnnotation(Xs.class)`) — after unwrapping it returns null.
- **S2177** — Child method matches parent signature but missing `@Override` → add `@Override`
  - **Guard:** only for genuine overrides; skip bridge/erasure coincidental matches; same Java-5 interface caveat as S1161.
- **S4454** — Remove `@Nonnull`/`@NonNull` from `equals()` parameter
  - **Guard:** skip if a null-analysis tool enforces the annotation in the build (see S4454 in CODE STYLE).
- **S4682** — `@CheckForNull`/`@Nullable`/`@NotNull` on a primitive type → remove annotation
  - **Guard:** skip if a code generator or validation tool keys on the annotation's presence.

---

## SPRING · S3751 · S6818 · S6833 · S6856

- **S3751** — `@RequestMapping` method is private → change to public or package-private
  - **Guard:** skip if widening visibility would activate a previously-inert handler (a new live, possibly unsecured route) — confirm the endpoint is intended to be exposed.
- **S6818** — Single constructor annotated `@Autowired` → remove `@Autowired` (Spring injects a single constructor automatically)
  - **Guard:** only on Spring Framework 4.3+ with default single-constructor injection and no custom processor that scans for `@Autowired`. Skip on older Spring or if a second constructor exists.
- **S6833** — `@Controller` where every declared method has `@ResponseBody` → replace `@Controller` with `@RestController` and remove `@ResponseBody` from all methods
  - **Guard:** "every method" must include INHERITED and interface-default handler methods. Skip if any such method lacks `@ResponseBody` — `@RestController` would force body semantics on it and turn a returned view name into a literal response body.
- **S6856** — Path variable in mapping without `@PathVariable`: `@GetMapping("/x/{id}") Order get(Long id)` → `Order get(@PathVariable Long id)`
  - **Guard:** skip if the parameter is resolved by another mechanism (custom `HandlerMethodArgumentResolver`, model attribute, request body). Require the param name to equal the template variable, or add an explicit `@PathVariable("id")` — otherwise it throws `MissingPathVariableException` at runtime.

---

## TEST QUALITY · S5779 · S5790 · S5810 · S5833 · S5863 · S6068

- **S5779** — Assertion inside `try`/`catch(Error)` → extract assertion to after the try-catch block
  - **Guard:** skip if the test intentionally catches its own `AssertionError` (testing failure handling).
- **S5790** — JUnit 5 inner test class missing `@Nested` → add `@Nested`
  - **Guard:** only when the inner class actually contains `@Test` methods meant to run. Skip helper/fixture inner classes — `@Nested` would make JUnit execute them.
- **S5810** — JUnit 5 test class/method not visible → make the class public and the method public or package-private with `@Test`
  - **Guard:** confirm the test is meant to run; skip if it was deliberately made invisible to disable it.
- **S5833** — `.as()` after assertion → move before: `assertThat(x).isEqualTo(y).as("d")` → `assertThat(x).as("d").isEqualTo(y)`
  - **Guard:** the trailing `.as()` is currently a no-op; moving it makes the description take effect. Skip if a test asserts on the (previously empty) failure-message text.
- **S5863** — `assertThat(x).isEqualTo(x)` (same object) → remove (always passes)
  - **Guard:** only when both sides are the SAME symbol/literal. Skip if the expression has side effects (`assertThat(next()).isEqualTo(next())`) — removal would drop the calls.
- **S6068** — `Mockito.when(...)` → static-import `when(...)`
  - **Guard:** skip if `when` already resolves to a different symbol or static import in scope.

---

## SECURITY (MECHANICAL) · S2151 · S5445

- **S2151** — Remove `runFinalizersOnExit()` call
  - **Guard:** see S2151 in EXCEPTION HANDLING (Java 8 caveat).
- **S5445** — `File.createTempFile(...)` → `Files.createTempFile(...)`
  - **Guard:** it returns `Path`, not `File` (adjust the call site or `.toFile()`). Note the new file gets restrictive 0600 POSIX permissions — skip if another process or user must read the temp file.

---

## STRUCTURE · S2127 · S2167 · S2209 · S2864 · S3038 · S4087 · S4351 · S4925

- **S2167** — `compareTo()` returns `Integer.MIN_VALUE` → return `-1` (negated `MIN_VALUE` is still `MIN_VALUE`, breaks contract)
  - **Guard:** skip if any code compares the result against the sentinel `Integer.MIN_VALUE`.
- **S4351** — `compareTo()` overloaded with non-`Object` param → remove the overload
  - **Guard:** skip if callers or method references bind to the specific-typed overload (removal would change resolution or fail to compile).
- **S2127** — `Double.longBitsToDouble(intVal)` → `Double.longBitsToDouble((long) intVal)`
  - **Guard:** the cast is semantics-neutral (the widening already happens). Do NOT treat it as a fix — if the real intent may be `Float.intBitsToFloat`, flag it instead of silently casting.
- **S3038** — Interface method already declared in parent interface → remove redundant declaration
  - **Guard:** skip if the re-declaration adds anything — a covariant return type, a default body, Javadoc, or annotations (`@Deprecated`, validation).
- **S4087** — Explicit `resource.close()` inside try-with-resources → remove (closed automatically)
  - **Guard:** skip if the explicit `close()` is an intentional EARLY release (the resource is used again later in the same block, or a lock/flush must happen before subsequent statements).
- **S4925** — `Class.forName("com.mysql.jdbc.Driver")` → remove entirely (JDBC 4.0+ auto-loads drivers)
  - **Guard:** skip if the driver's `META-INF/services` auto-registration may be absent — shaded/repackaged/uber-jars can strip it, and removal then yields "No suitable driver" at runtime.
- **S2209** — Static member via instance → via class: `instance.staticField` → `ClassName.staticField`
  - **Guard:** skip if the instance expression has a side effect (`getThing().STATIC`) — rewriting to `ClassName.STATIC` would drop the call.
- **S2864** — `map.keySet()` when value also needed → use `entrySet()`: `for (Map.Entry<K,V> e : map.entrySet()) { e.getKey(); e.getValue(); }`
  - **Guard:** skip lazy/computing/defaulted maps, or loops that mutate the map, where `entry.getValue()` would differ from a fresh `map.get(k)`.
