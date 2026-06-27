# 📖 RULES REFERENCE — human-readable form

*The same 69 rules as `sonarqube-ai-fix-prompts-rules.md`, expanded with fuller descriptions and examples.*
*Every rule is a safe, mechanical auto-fix applied without human intervention. Rules that could only flag a `// TODO`, or whose fix could change behavior or require guessing intent, live in `sonarqube-excluded-rules.md`.*

> **GUARD convention.** Each rule carries a **GUARD** — the one edge case where the fix would compile cleanly yet change behavior, fail a test, or fail a CI gate. The fix is "safe, fully automatic" *only while its GUARD holds*. If a GUARD condition is met for a given occurrence, **SKIP it and note it — do not guess.** The guards are what make the no-human-review posture actually true.

---

## NAMING

*(S117, S119)*

* Local variable and parameter names must be camelCase
  `String UserName = ...` → `String userName = ...` (S117)
  **GUARD:** rename only local variables and parameters of methods that are NOT public/protected and carry no web/binding/serialization annotation (Spring `@RequestParam`/`@PathVariable`, JAX-RS `@PathParam`/`@QueryParam`, Jackson `@JsonProperty`/`@JsonCreator`, MapStruct) — those parameter names are reflectively bound, so renaming them silently changes request/JSON mapping. Skip if the new name shadows a field or collides with an existing local/param.
* Type parameter names: a single uppercase letter, or a name ending in `T`
  `<type>` → `<T>`, `<orderType>` → `<OrderT>` (S119)
  **GUARD:** skip if the new name collides with a visible class/type in scope; update any matching `@param <oldName>` Javadoc tag.

---

## DEAD CODE

*(S1128, S1172, S1481)*

* Remove unused imports (S1128)
  **GUARD:** keep any import still referenced in Javadoc (`{@link}`, `{@linkplain}`, `{@value}`, `@see`, `@throws`) or in a sibling `package-info.java`.
* Remove unused method parameters — **only** for private methods (S1172)
  **GUARD:** skip if the method is invoked via reflection or used as a method reference whose arity matters; update every call site in the file.
* Remove unused local variables (S1481)
  **GUARD:** only when the initializer is a pure value. Skip if it has a side effect (`var x = service.computeAndCache();`) — removing the variable would drop the call.

---

## NULL AND BOOLEAN

*(S1125, S1126, S1155)*

* Remove redundant boolean literals
  `if (x == true)` → `if (x)`, `if (x == false)` → `if (!x)`, `return x == true` → `return x` (S1125)
  **GUARD:** only when the operand is a primitive `boolean`. Skip a boxed `Boolean` — `== true` unboxes (NPE on null) while `return x` would hand back `null`.
* Remove the unnecessary `else` after a jump statement
  `if (x) { return a; } else { b(); }` → `if (x) { return a; } b();` (S1126)
  **GUARD:** only when the `if` branch always exits on every path (return/throw/break/continue). Skip if it can fall through.
* Use `isEmpty()` instead of `size()` comparisons
  `list.size() == 0` → `list.isEmpty()`, `list.size() > 0` → `!list.isEmpty()` (S1155)
  **GUARD:** standard `Collection`/`Map`/`CharSequence` only. Skip custom types whose `isEmpty()` may not equal `size() == 0`, and concurrent collections where the two differ.

---

## CODE STYLE

*(S1110, S1121, S1124, S1192, S1195, S1197, S1219, S1264, S1444, S1596, S2147, S2154, S3252, S3599, S3973, S4165, S4425, S4454, S4719, S7158)*

* Remove redundant parentheses that add no meaning
  `return (x + y)` → `return x + y` — keep parens that clarify precedence: `(a + b) * c` (S1110)
  **GUARD:** remove only parens redundant by precedence AND associativity. Keep grouping ones like `x - (a - b)`.
* Extract an assignment out of a sub-expression into its own statement
  `if ((x = compute()) != null)` → `x = compute(); if (x != null)` (S1121)
  **GUARD:** ONLY inside an `if`. NEVER in a `while`/`for` condition — the assignment must re-run each iteration, so hoisting it produces an infinite/incorrect loop.
* Reorder modifiers to canonical Java order: public/protected/private → abstract → static → final
  `final static public int X` → `public static final int X` (S1124)
  **GUARD:** reorder keyword modifiers only; never move a (type-use) annotation relative to the type.
* Extract a duplicated string literal (3+ occurrences) into a named constant in `SCREAMING_SNAKE_CASE`
  `"order.created"` (used 3×) → `private static final String ORDER_CREATED = "order.created"` (S1192)
  **GUARD:** skip if the constant name collides with/shadows an existing or inherited field; extract only within one class.
* Array designator must be on the type, not the variable
  `int a[]` → `int[] a`, `String method()[]` → `String[] method()` (S1195, S1197)
  **GUARD:** skip multi-variable declarations like `int a[], b;` — moving `[]` to the type would make `b` an array too.
* Remove non-`case` labels from a switch block (S1219)
  **GUARD:** skip if the label is the target of a `break label;`/`continue label;`.
* Convert a `for` loop to `while` when the loop variable is not used in the update clause
  `for (; condition;)` → `while (condition)` (S1264)
  **GUARD:** only when init AND update are empty. Skip if the `for` init declares a variable (conversion would relocate its scope).
* A `public static` field must be `final` — skip if it is assigned anywhere outside its declaration (S1444)
  **GUARD:** also skip if it is set via reflection, or is an inter-module constant whose value might change in a later build (it would be inlined into other compilation units).
* Replace deprecated empty-collection constants
  `Collections.EMPTY_LIST` → `Collections.emptyList()`, `EMPTY_MAP` → `emptyMap()`, `EMPTY_SET` → `emptySet()` (S1596)
  **GUARD:** skip if the raw constant feeds a method overloaded on raw `List` vs `List<T>`, or a `-Werror` rawtypes build relies on the raw form.
* Merge catch clauses with **identical** bodies into a multi-catch
  `catch (A e) { log(e); } catch (B e) { log(e); }` → `catch (A | B e) { log(e); }` — skip if the bodies differ even slightly (S2147)
  **GUARD:** also skip if the caught types are in a subtype relationship (illegal multicatch), or if `e` is passed to a method overloaded on the specific types (overload resolution would change).
* Dissimilar wrapper types in a ternary → add an explicit cast
  `condition ? intVal : longVal` → `condition ? (long) intVal : longVal` (S2154)
  **GUARD:** skip if either operand is a boxed wrapper — the cast changes unboxing / NPE timing.
* Static member accessed via a derived type → access via the declaring class
  `Child.PARENT_CONSTANT` → `Parent.PARENT_CONSTANT` (S3252)
  **GUARD:** skip if the derived type hides the member (different value), or if the swap changes which class's static initializer runs first.
* Double-brace initialization → explicit `add()` calls
  `new ArrayList<>() {{ add("a"); add("b"); }}` → `List<String> list = new ArrayList<>(); list.add("a"); list.add("b");` (S3599)
  **GUARD:** skip if the anonymous subtype is observed — `getClass()` checks, serialization (captures outer `this`), or the type leaks out.
* Single-line conditional without braces → add braces
  `if (x) doIt();` → `if (x) { doIt(); }` (S3973)
  **GUARD:** brace exactly the controlled statement; preserve dangling-`else` association.
* Remove redundant field assignments
  Skip if the class is `@Entity`/`@MappedSuperclass`/`@Embeddable`, or the field is `@Column`/`@Id`/`@Transient` (S4165)
  **GUARD:** also skip if the field is `volatile`, or is read via an overridable method called during construction.
* Sign-safe hex formatting
  `Integer.toHexString(n)` → `String.format("%x", n)` (S4425)
  **GUARD:** primitive `int`/`long` only; preserve width; skip boxed/nullable operands (`format` NPEs on null). Note it is hot-path slower.
* Remove `@Nonnull`/`@NonNull` from an `equals()` parameter
  `equals(@Nonnull Object obj)` → `equals(Object obj)` (S4454)
  **GUARD:** skip if a null-analysis tool that enforces/instruments the annotation (NullAway, IDEA "as error") is active in the build.
* Replace a string charset name with a `StandardCharsets` constant
  `"UTF-8"` → `StandardCharsets.UTF_8`, `"ISO-8859-1"` → `StandardCharsets.ISO_8859_1` (S4719)
  **GUARD:** the `Charset` overload does not throw `UnsupportedEncodingException` — remove the now-dead `catch`/`throws` too, or skip if that cascades to callers.
* `str.length() == 0` → `str.isEmpty()`, `str.length() > 0` → `!str.isEmpty()` (S7158)
  **GUARD:** `String` is fine on any target. For `StringBuilder`/other `CharSequence`, `isEmpty()` needs Java 15+ — skip on older targets.

---

## STRING

*(S1858, S2629)*

* `toString()` called on a String → remove the call
  `str.toString()` → `str` (S1858)
  **GUARD:** only when the compile-time type is exactly `String` AND the receiver cannot be null at that point — `str.toString()` NPEs on null, `str` does not.
* Logging/Preconditions arguments must not require concatenation at the call site
  `log.debug("Value: " + value)` → `log.debug("Value: {}", value)` (S2629)
  **GUARD:** only for SLF4J / Log4j2 parameterized loggers. Skip `java.util.logging` and any logger that does not interpret `{}`. Skip if `value.toString()` has side effects, or the message already contains a literal `{}`.

---

## LAMBDA AND FUNCTIONAL

*(S1488, S1602, S1611, S2438, S4065)*

* Return the expression directly instead of assign-then-return
  `String result = compute(); return result;` → `return compute();` — skip if the variable is used in a `finally` block or try-with-resources (S1488)
  **GUARD:** also skip if the variable is captured by a lambda/anonymous class created between the assignment and the return.
* Lambda block with a single return → expression form
  `x -> { return x.getName(); }` → `x -> x.getName()` (S1602)
  **GUARD:** skip if it introduces target-type ambiguity between overloads (e.g. `Function` vs `Consumer`).
* Remove unnecessary parentheses around a single lambda parameter
  `(x) -> x.getName()` → `x -> x.getName()` (S1611)
  **GUARD:** only a single param with no explicit type and no annotation.
* A `Thread` wrapping a `Thread` (where a `Runnable` is expected) → use a lambda
  `new Thread(myThread)` where `myThread` is a Thread → `new Thread(() -> myThread.run())` (S2438)
  **GUARD:** skip if `myThread` is reassigned before the new thread starts — the lambda captures the variable, not the value.
* `ThreadLocal` anonymous subclass → `ThreadLocal.withInitial(ArrayList::new)` (S4065)
  **GUARD:** only when the anonymous class overrides ONLY `initialValue()` with a side-effect-free constructor. Skip if it overrides other methods (`childValue`, `get`, `set`).

---

## EXCEPTION HANDLING

*(S2151)*

* Remove the `runFinalizersOnExit()` call entirely (S2151)
  **GUARD:** a no-op on Java 11+. On Java 8 skip if anything relied on exit-time finalization.

---

## COLLECTIONS AND LOOPS

*(S1155, S3878, S4838)*

* Use `isEmpty()` instead of `size()`/`length()` comparisons
  `list.size() == 0` → `list.isEmpty()`, `str.length() == 0` → `str.isEmpty()` (S1155)
  **GUARD:** see S1155 above — standard `Collection`/`Map`/`CharSequence` only; skip custom/concurrent types.
* Array created for a varargs call → `method(new String[]{"a", "b"})` → `method("a", "b")` (S3878)
  **GUARD:** skip if the target method is overloaded such that spreading changes which overload is selected (`m(String[])` vs `m(Object...)` vs fixed-arity).
* Raw `Map` iteration → add the generic type parameter: `Map` → `Map<String, X>` (S4838)
  **GUARD:** only when the actual key/value types are unambiguous from usage; skip if they would have to be guessed.

---

## CONCURRENCY

*(S2066, S3066)*

* Serializable non-static inner class → add the `static` keyword (S2066)
  **GUARD:** skip if the inner class references any outer-instance member (won't compile), or if instances are serialized and persisted — `static` changes the serialized form and breaks deserialization of old data.
* Enum field that is publicly mutable → make it `private final`
  `public Status status = ACTIVE` → `private final Status status` (S3066)
  **GUARD:** skip if the field is reassigned anywhere (final breaks it) or read by external callers (`public`→`private` is an API break).

---

## SERIALIZATION

*(S2060, S2061, S2062, S2157, S2675)*

* `Externalizable` class missing a no-args constructor → add `public ClassName() {}` (S2060)
  **GUARD:** ensure `final` fields stay definitely assigned; skip if a framework selects constructors by signature and could pick the new no-arg ctor.
* Custom serialization methods must have exactly these signatures:
  `private void writeObject(ObjectOutputStream oos) throws IOException`
  `private void readObject(ObjectInputStream ois) throws IOException, ClassNotFoundException` (S2061)
  **GUARD:** only when the method is genuinely the serialization hook. Skip an ordinary same-named method — fixing its signature would silently activate it as a serialization callback.
* `private Object readResolve()` → `protected Object readResolve()` (so it is inheritable) (S2062)
  **GUARD:** skip if the class is subclassed and the canonical-instance / singleton logic must not be inherited.
* `Cloneable` class missing `clone()` → generate it:

  ```java
  @Override
  public Object clone() {
      try { return super.clone(); }
      catch (CloneNotSupportedException e) { throw new AssertionError(); }
  }
  ```

  (S2157)
  **GUARD:** `super.clone()` is a SHALLOW copy. Skip (leave a note) if the class has mutable reference fields callers would expect deep-copied — the generated clone would alias them.
* Remove the `synchronized` keyword from `readObject()` (S2675)
  **GUARD:** skip if deserialization relies on the lock for thread-safety.

---

## ANNOTATIONS AND BOILERPLATE

*(S1161, S1174, S1710, S2177, S4454, S4682)*

* Add a missing `@Override` to methods that override or implement (S1161)
  **GUARD:** skip on `-source 5` for INTERFACE implementations — `@Override` on them is illegal before Java 6.
* `public void finalize()` → `protected void finalize()` (S1174)
  **GUARD:** skip if `finalize()` is invoked externally or via reflection.
* Unwrap a `@Repeatable` container annotation
  `@Xs({@X("a"), @X("b")})` → `@X("a") @X("b")` — only when the annotation is declared `@Repeatable` (S1710)
  **GUARD:** skip if any reflection reads the container type directly (`getAnnotation(Xs.class)`) — after unwrapping it returns null.
* Child method matching the parent signature but missing `@Override` → add `@Override` (S2177)
  **GUARD:** only genuine overrides; skip bridge/erasure coincidental matches; same Java-5 interface caveat as S1161.
* Remove `@Nonnull`/`@NonNull` from an `equals()` parameter (S4454)
  **GUARD:** skip if a null-analysis tool enforces the annotation in the build.
* Remove `@CheckForNull`/`@Nullable`/`@NotNull` from a primitive type — primitives cannot be null (S4682)
  **GUARD:** skip if a code generator or validation tool keys on the annotation's presence.

---

## SPRING

*(S3751, S6818, S6833, S6856)*

* `@RequestMapping` method is private → change it to public or package-private (S3751)
  **GUARD:** skip if widening visibility would activate a previously-inert handler (a new live, possibly unsecured route) — confirm the endpoint is meant to be exposed.
* Single constructor annotated `@Autowired` → remove `@Autowired` (Spring injects a single constructor automatically) (S6818)
  **GUARD:** only on Spring Framework 4.3+ with default single-constructor injection and no custom processor that scans for `@Autowired`. Skip on older Spring or if a second constructor exists.
* `@Controller` where **every** declared method has `@ResponseBody` → replace `@Controller` with `@RestController` and remove `@ResponseBody` from each method — skip if even one declared method lacks `@ResponseBody` (S6833)
  **GUARD:** "every method" must include INHERITED and interface-default handler methods. Skip if any such method lacks `@ResponseBody` — `@RestController` would turn its returned view name into a literal response body.
* Path variable in the mapping without `@PathVariable`
  `@GetMapping("/x/{id}") Order get(Long id)` → `Order get(@PathVariable Long id)` — verify the parameter name matches the template (S6856)
  **GUARD:** skip if the parameter is resolved another way (custom `HandlerMethodArgumentResolver`, model attribute, request body). Require name == template variable, or add an explicit `@PathVariable("id")` — otherwise it throws `MissingPathVariableException` at runtime.

---

## TEST QUALITY

*(S5779, S5790, S5810, S5833, S5863, S6068)*

* Assertion inside a `try`/`catch(Error)` → move it after the try-catch block (S5779)
  **GUARD:** skip if the test intentionally catches its own `AssertionError` (testing failure handling).
* JUnit 5 inner test class missing `@Nested` → add `@Nested` (S5790)
  **GUARD:** only when the inner class actually contains `@Test` methods meant to run. Skip helper/fixture inner classes — `@Nested` would make JUnit execute them.
* JUnit 5 test class/method not visible → make the class public and the method public or package-private with `@Test` (S5810)
  **GUARD:** confirm the test is meant to run; skip if it was deliberately made invisible to disable it.
* `.as()` placed after the assertion → move it before
  `assertThat(x).isEqualTo(y).as("d")` → `assertThat(x).as("d").isEqualTo(y)` (S5833)
  **GUARD:** the trailing `.as()` is currently a no-op; moving it makes the description take effect. Skip if a test asserts on the (previously empty) failure-message text.
* `assertThat(x).isEqualTo(x)` (same object) → remove it (always passes) (S5863)
  **GUARD:** only when both sides are the same symbol/literal. Skip if the expression has side effects (`assertThat(next()).isEqualTo(next())`) — removal would drop the calls.
* `Mockito.when(...)` → static-import `when(...)` for readability (S6068)
  **GUARD:** skip if `when` already resolves to a different symbol or static import in scope.

---

## SECURITY (MECHANICAL)

*(S2151, S5445)*

* Remove the `runFinalizersOnExit()` call entirely (S2151)
  **GUARD:** see S2151 above (Java 8 caveat).
* `File.createTempFile(...)` → `Files.createTempFile(...)` — adjust the call site if it expects a `File` rather than a `Path` (S5445)
  **GUARD:** it returns `Path`, not `File`. Note the new file gets restrictive 0600 POSIX permissions — skip if another process or user must read the temp file.

---

## STRUCTURE

*(S2127, S2167, S2209, S2864, S3038, S4087, S4351, S4925)*

* `compareTo()` returns `Integer.MIN_VALUE` → return `-1` (negated `MIN_VALUE` is still `MIN_VALUE`, breaking the contract) (S2167)
  **GUARD:** skip if any code compares the result against the sentinel `Integer.MIN_VALUE`.
* `compareTo()` overloaded with a non-`Object` parameter → remove the overload (S4351)
  **GUARD:** skip if callers or method references bind to the specific-typed overload.
* `Double.longBitsToDouble(intVal)` → `Double.longBitsToDouble((long) intVal)` (S2127)
  **GUARD:** the cast is semantics-neutral (widening already happens). Do NOT treat it as a fix — if the real intent may be `Float.intBitsToFloat`, flag it instead of silently casting.
* Interface method already declared in a parent interface → remove the redundant declaration (S3038)
  **GUARD:** skip if the re-declaration adds anything — a covariant return, a default body, Javadoc, or annotations.
* Explicit `resource.close()` inside try-with-resources → remove it (closed automatically) (S4087)
  **GUARD:** skip if the explicit `close()` is an intentional EARLY release (the resource is used again later in the same block, or a lock/flush must precede subsequent statements).
* `Class.forName("com.mysql.jdbc.Driver")` → remove entirely (JDBC 4.0+ auto-loads drivers) (S4925)
  **GUARD:** skip if the driver's `META-INF/services` auto-registration may be absent — shaded/repackaged/uber-jars can strip it, and removal then yields "No suitable driver" at runtime.
* Static member accessed via an instance → access via the class: `instance.staticField` → `ClassName.staticField` (S2209)
  **GUARD:** skip if the instance expression has a side effect (`getThing().STATIC`) — rewriting to `ClassName.STATIC` would drop the call.
* `map.keySet()` when the value is also needed → use `entrySet()`
  `for (Map.Entry<K,V> e : map.entrySet()) { e.getKey(); e.getValue(); }` (S2864)
  **GUARD:** skip lazy/computing/defaulted maps, or loops that mutate the map, where `entry.getValue()` would differ from a fresh `map.get(k)`.
