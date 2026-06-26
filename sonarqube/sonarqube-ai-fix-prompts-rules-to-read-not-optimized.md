# 📖 RULES REFERENCE — human-readable form

*The same 165 rules as `sonarqube-ai-fix-prompts-rules.md`, expanded with fuller descriptions and examples.*
*All prompts apply these rules. Each rule is tagged **Auto-fix** (applied directly) or **Flag only** (adds a `// TODO` comment, never changes behavior).*

---

## NAMING

*(S117, S119)*

* Local variable and parameter names must be camelCase
  `String UserName = ...` → `String userName = ...` (S117)
* Type parameter names: a single uppercase letter, or a name ending in `T`
  `<type>` → `<T>`, `<orderType>` → `<OrderT>` (S119)

---

## DEAD CODE

*(S1068, S1128, S1144, S1172, S1481)*

* Remove unused private fields
  Skip if annotated with `@Autowired`, `@Inject`, `@Value`, or `@Column` (S1068)
* Remove unused imports (S1128)
* Remove unused private methods
  Skip if annotated with `@Bean`, `@EventListener`, `@Scheduled`, or `@PostConstruct` (S1144)
* Remove unused method parameters — **only** for private methods (S1172)
* Remove unused local variables (S1481)

---

## NULL AND BOOLEAN

*(S1125, S1126, S1155, S2583, S2589)*

**Auto-fix:**

* Remove redundant boolean literals
  `if (x == true)` → `if (x)`, `if (x == false)` → `if (!x)`, `return x == true` → `return x` (S1125)
* Remove the unnecessary `else` after a jump statement
  `if (x) { return a; } else { b(); }` → `if (x) { return a; } b();` (S1126)
* Use `isEmpty()` instead of `size()` comparisons
  `list.size() == 0` → `list.isEmpty()`, `list.size() > 0` → `!list.isEmpty()` (S1155)

**Flag only — adds TODO comment, does not auto-fix:**

* Always-true or always-false condition → add `// TODO: S2583 verify condition is intentional` — do NOT remove code (S2583)
* Gratuitous boolean expression → add `// TODO: S2589 verify this condition` — do NOT remove code (S2589)

---

## CODE STYLE

*(S1110, S1121, S1124, S1132, S1192, S1195, S1197, S1219, S1264, S1444, S1596, S3973, S4165, S4425, S4454, S4719, S7158, S1764, S2147, S2154, S2183, S3252, S3599)*

**Auto-fix:**

* Remove redundant parentheses that add no meaning
  `return (x + y)` → `return x + y` — keep parens that clarify precedence: `(a + b) * c` (S1110)
* Extract an assignment out of a sub-expression into its own statement
  `if ((x = compute()) != null)` → `x = compute(); if (x != null)` (S1121)
* Reorder modifiers to canonical Java order: public/protected/private → abstract → static → final
  `final static public int X` → `public static final int X` (S1124)
* Flip a string literal to the left side of `equals` to prevent NPE
  `variable.equals("LITERAL")` → `"LITERAL".equals(variable)` — skip if the variable is `@NotNull` or provably non-null (S1132)
* Extract a duplicated string literal (3+ occurrences) into a named constant in `SCREAMING_SNAKE_CASE`
  `"order.created"` (used 3×) → `private static final String ORDER_CREATED = "order.created"` (S1192)
* Array designator must be on the type, not the variable
  `int a[]` → `int[] a`, `String method()[]` → `String[] method()` (S1195, S1197)
* Remove non-`case` labels from a switch block (S1219)
* Convert a `for` loop to `while` when the loop variable is not used in the update clause
  `for (; condition;)` → `while (condition)` (S1264)
* A `public static` field must be `final` — skip if it is assigned anywhere outside its declaration (S1444)
* Replace deprecated empty-collection constants
  `Collections.EMPTY_LIST` → `Collections.emptyList()`, `EMPTY_MAP` → `emptyMap()`, `EMPTY_SET` → `emptySet()` (S1596)
* Single-line conditional without braces → add braces
  `if (x) doIt();` → `if (x) { doIt(); }` (S3973)
* Remove redundant field assignments
  Skip if the class is `@Entity`/`@MappedSuperclass`/`@Embeddable`, or the field is `@Column`/`@Id`/`@Transient` (S4165)
* Sign-safe hex formatting
  `Integer.toHexString(n)` → `String.format("%x", n)` (S4425)
* Remove `@Nonnull`/`@NonNull` from an `equals()` parameter
  `equals(@Nonnull Object obj)` → `equals(Object obj)` (S4454)
* Replace a string charset name with a `StandardCharsets` constant
  `"UTF-8"` → `StandardCharsets.UTF_8`, `"ISO-8859-1"` → `StandardCharsets.ISO_8859_1` (S4719)
* `str.length() == 0` → `str.isEmpty()`, `str.length() > 0` → `!str.isEmpty()` (S7158)

**Flag only — adds TODO comment, does not auto-fix:**

* Identical expressions on both sides of an operator
  `a == a`, `a && a`, `a || a` → add `// TODO: S1764 identical expressions — verify intent` (S1764)
* Merge compatible catch clauses with identical bodies
  `catch (A e) { log(e); } catch (B e) { log(e); }` → `catch (A | B e) { log(e); }` — skip if the bodies differ even slightly (S2147)
* Dissimilar wrapper types in a ternary → add an explicit cast
  `condition ? intVal : longVal` → `condition ? (long) intVal : longVal` (S2154)
* Useless bit shift (shift by 0, or by ≥ the number of bits)
  `x << 0` → `x`; `x << 32` on an int → add `// TODO: S2183 shift by 32 is always 0 for int — verify intent` (S2183)
* Static member accessed via a derived type → access via the declaring class
  `Child.PARENT_CONSTANT` → `Parent.PARENT_CONSTANT` (S3252)
* Double-brace initialization → explicit `add()` calls
  `new ArrayList<>() {{ add("a"); add("b"); }}` → `List<String> list = new ArrayList<>(); list.add("a"); list.add("b");` (S3599)

---

## STRING

*(S1153, S1858, S2200, S2629, S5361, S2112, S2639, S3039)*

**Auto-fix:**

* Remove `String.valueOf()` when appending to a String
  `"prefix" + String.valueOf(x)` → `"prefix" + x` (S1153)
* `toString()` called on a String → remove the call
  `str.toString()` → `str` (S1858)
* A `compareTo` result must be compared with 0, not a specific value
  `a.compareTo(b) == -1` → `a.compareTo(b) < 0` (S2200)
* Logging/Preconditions arguments must not require concatenation at the call site
  `log.debug("Value: " + value)` → `log.debug("Value: {}", value)` (S2629)
* Prefer `replace` over `replaceAll` when the pattern has no regex metacharacters
  `str.replaceAll("x", "y")` → `str.replace("x", "y")`
  Metacharacters to watch for: `. * + ? ^ $ { } [ ] | ( ) \` (S5361)

**Flag only — adds TODO comment, does not auto-fix:**

* `URL.equals`/`hashCode` is broken (does a blocking DNS lookup) → use `URI`
  `new URL(str).equals(other)` → add `// TODO: S2112 URL.equals is broken — replace with URI` (S2112)
* Suspicious regex pattern → add `// TODO: S2639 verify this regex is correct and handles edge cases` (S2639)
* String operation index may be out of bounds → add `// TODO: S3039 verify this index is within string bounds` (S3039)

---

## LAMBDA AND FUNCTIONAL

*(S1488, S1602, S1611, S2438, S3012, S3631, S3864, S3958, S3959, S4034, S4065, S4348, S6204, S1150)*

**Auto-fix:**

* Return the expression directly instead of assign-then-return
  `String result = compute(); return result;` → `return compute();` — skip if the variable is used in a `finally` block or try-with-resources (S1488)
* Lambda block with a single return → expression form
  `x -> { return x.getName(); }` → `x -> x.getName()` (S1602)
* Remove unnecessary parentheses around a single lambda parameter
  `(x) -> x.getName()` → `x -> x.getName()` (S1611)
* A `Thread` wrapping a `Thread` (where a `Runnable` is expected) → use a lambda
  `new Thread(myThread)` where `myThread` is a Thread → `new Thread(() -> myThread.run())` (S2438)
* Replace loop copies with built-in methods
  `for (X x : src) dst.add(x)` → `dst.addAll(src)`
  `for (int i=0; i<n; i++) dst[i] = src[i]` → `System.arraycopy(src, 0, dst, 0, n)` (S3012)
* Use `Arrays.stream()` for simple primitive-array aggregations only (`int[]`, `long[]`, `double[]`)
  `for (int x : arr) { sum += x; }` → `int sum = Arrays.stream(arr).sum()`
  Only for sum/count/average — never convert loops with complex logic (S3631)

**Flag only — adds TODO comment, does not auto-fix:**

* `Stream.peek()` used to modify elements → add `// TODO: S3864 peek must not modify — use map() or forEach()` (S3864)
* Intermediate stream result unused → add `// TODO: S3958 add a terminal operation (.collect/.forEach/.count)` (S3958)
* Stream consumed twice → add `// TODO: S3959 stream already consumed — create a new stream` (S3959)
* Redundant stream operations (`.filter(x -> true)`, `.map(x -> x)`, `.sorted().sorted()`) → add `// TODO: S4034 simplify stream chain` (S4034)
* `ThreadLocal` anonymous subclass → `ThreadLocal.withInitial(ArrayList::new)` (S4065)
* `iterator()` returns `this` → implement a proper `Iterator` (index field, `hasNext()`, `next()` throwing `NoSuchElementException` when exhausted) (S4348)
* Java 16+: `.collect(Collectors.toUnmodifiableList())` → `.toList()` — check the Java version in `pom.xml` first (S6204)
* `Enumeration` → `Iterator` — only for private/internal usage; skip if the method is public API (S1150)

---

## EXCEPTION HANDLING

*(S108, S2151, S1143, S1166, S1181, S1989, S2142, S2235, S2272, S2737, S3346)*

**Auto-fix:**

* Empty catch block → add logging
  `log.warn("Ignored {}: {}", e.getClass().getSimpleName(), e.getMessage(), e)`
  If no logger exists, add `private static final Logger log = LoggerFactory.getLogger(ClassName.class)` first (S108)
* Remove the `runFinalizersOnExit()` call entirely (S2151)

**Flag only — adds TODO comment, does not auto-fix:**

* `return`/`throw`/`break` in a `finally` block → add `// TODO: S1143 jump in finally masks original exception — review` (S1143)
* Swallowed exception → add `log.warn("Unexpected exception", e)` before the existing catch body — always add it, even if the body is non-empty (S1166)
* `catch(Throwable)` or `catch(Error)` → add `// TODO: S1181 too broad — narrow to a specific exception type` (S1181)
* Exception escaping a servlet `doGet`/`doPost` → wrap the body
  `try { ... } catch (Exception e) { log.error("...", e); res.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR); }` (S1989)
* `InterruptedException` caught → add `Thread.currentThread().interrupt()` inside the catch body (S2142)
* `catch(IllegalMonitorStateException)` → remove the catch block if no other checked exceptions are thrown in the try body; otherwise add `// TODO: S2235 remove only if no other checked exceptions are thrown` (S2235)
* `Iterator.next()` missing an exhaustion check → add `if (!hasNext()) throw new NoSuchElementException();` at the start of `next()` (S2272)
* Catch block that only rethrows → remove the try/catch for unchecked exceptions; for checked add `// TODO: S2737 verify callers handle this before removing` (S2737)
* `assert` with side effects → add `// TODO: S3346 move the side effect out of assert — asserts may be disabled at runtime` (S3346)

---

## COLLECTIONS AND LOOPS

*(S1155, S1319, S127, S1994, S2175, S2189, S2251, S2252, S3012, S3020, S3878, S3923, S3981, S4838, S5413, S6417, S6466)*

**Auto-fix:**

* Use `isEmpty()` instead of `size()`/`length()` comparisons
  `list.size() == 0` → `list.isEmpty()`, `str.length() == 0` → `str.isEmpty()` (S1155)
* Declare collection variables using the interface type
  `ArrayList<Order> list` → `List<Order> list`, `HashMap<K,V> map` → `Map<K,V> map` (S1319)

**Flag only — adds TODO comment, does not auto-fix:**

* `for` loop stop condition never changes → add `// TODO: S127 stop condition is invariant — verify termination` (S127)
* `for` loop increment does not modify the loop counter → add `// TODO: S1994 increment does not modify loop counter` (S1994)
* Incompatible collection method call (wrong type) → add `// TODO: S2175 incompatible types — verify intent` (S2175)
* Infinite loop with no exit → add `// TODO: S2189 verify this loop has a reachable exit condition` (S2189)
* Loop counter going the wrong direction → add `// TODO: S2251 verify loop direction — do not auto-fix` (S2251)
* Loop condition always false → add `// TODO: S2252 loop never executes` (S2252)
* Array/list copied with a loop → use a built-in (see LAMBDA AND FUNCTIONAL S3012) (S3012)
* `list.toArray()` untyped → `list.toArray(new String[0])` for `List<String>`; for a raw type add `// TODO: S3020 add typed toArray — generic type unknown` (S3020)
* Array created for a varargs call → `method(new String[]{"a", "b"})` → `method("a", "b")` (S3878)
* All branches identical → add `// TODO: S3923 all branches identical — verify intent` — do NOT remove code (S3923)
* `list.size() >= 0` is always true → add `// TODO: S3981 this condition is always true` (S3981)
* Raw `Map` iteration → add the generic type parameter: `Map` → `Map<String, X>` (S4838)
* `List.remove()` in an ascending `for` loop removes the wrong element → add `// TODO: S5413 use Iterator.remove() or iterate in reverse` (S5413)
* Collection modified during iteration → add `// TODO: S6417 modifying collection during iteration causes ConcurrentModificationException` (S6417)
* Array index access that may be out of bounds → add `// TODO: S6466 verify array bounds before access` (S6466)

---

## CONCURRENCY

*(S2066, S3066, S2168, S2273, S2274, S2276, S2445, S2446, S3014, S3067, S3078, S5164, S6901)*

**Auto-fix:**

* Serializable non-static inner class → add the `static` keyword (S2066)
* Enum field that is publicly mutable → make it `private final`
  `public Status status = ACTIVE` → `private final Status status` (S3066)

**Flag only — adds TODO comment, does not auto-fix:**

* Double-checked locking without a volatile field → add `// TODO: S2168 double-checked locking requires a volatile field` (S2168)
* `wait()`/`notify()`/`notifyAll()` outside synchronized code → wrap it: `synchronized (obj) { obj.wait(); }` (S2273)
* `wait()`/`await()` in an `if` instead of a `while` → add `// TODO: S2274 use a while loop, not if` (S2274)
* `Thread.sleep()` inside a synchronized block → add `// TODO: S2276 replace sleep with wait()` (S2276)
* Synchronizing on a non-private-final field → add `// TODO: S2445 synchronize on a private final lock object` (S2445)
* `notify()` → `notifyAll()` to avoid thread starvation (S2446)
* `new ThreadGroup(...)` → add `// TODO: S3014 replace with an Executor — choose the thread count manually` (S3014)
* `synchronized(this.getClass())` → `synchronized(MyClass.class)` (S3067)
* `volatileField++` (compound op on a volatile) → add `// TODO: S3078 use AtomicInteger/AtomicLong for compound operations` (S3078)
* `ThreadLocal` not cleaned up → wrap in try/finally: `try { tl.set(v); /* work */ } finally { tl.remove(); }` (S5164)
* `setDaemon()`/`setPriority()`/`getThreadGroup()` on a virtual thread → add `// TODO: S6901 no effect on virtual threads` (S6901)

---

## SERIALIZATION

*(S2060, S2061, S2062, S2157, S2675, S2975, S6218)*

**Auto-fix:**

* `Externalizable` class missing a no-args constructor → add `public ClassName() {}` (S2060)
* Custom serialization methods must have exactly these signatures:
  `private void writeObject(ObjectOutputStream oos) throws IOException`
  `private void readObject(ObjectInputStream ois) throws IOException, ClassNotFoundException` (S2061)
* `private Object readResolve()` → `protected Object readResolve()` (so it is inheritable) (S2062)
* `Cloneable` class missing `clone()` → generate it:

  ```java
  @Override
  public Object clone() {
      try { return super.clone(); }
      catch (CloneNotSupportedException e) { throw new AssertionError(); }
  }
  ```

  (S2157)
* Remove the `synchronized` keyword from `readObject()` (S2675)

**Flag only — adds TODO comment, does not auto-fix:**

* `clone()` overridden → add `// TODO: S2975 clone() is broken by design — use a copy constructor` (S2975)
* Record with array fields → override `equals()` (using `Arrays.equals()` for array fields, `Objects.equals()` for others) and `hashCode()` (using `Arrays.hashCode()` for array fields)

  ```java
  record Point(int[] coords, String name) {
      @Override public boolean equals(Object o) {        // Java 16+ pattern syntax
          if (!(o instanceof Point p)) return false;
          return Arrays.equals(coords, p.coords) && Objects.equals(name, p.name);
      }
      @Override public int hashCode() {
          return Objects.hash(Arrays.hashCode(coords), name);
      }
  }
  ```

  For Java < 16 use `if (!(o instanceof Point)) return false; Point p = (Point) o;` (S6218)

---

## ANNOTATIONS AND BOILERPLATE

*(S1161, S1174, S1206, S1710, S2177, S4454, S4682, S1210, S1874, S2970, S4274, S5738, S5803, S5960)*

**Auto-fix:**

* Add a missing `@Override` to methods that override or implement (S1161)
* `public void finalize()` → `protected void finalize()` (S1174)
* `equals()` overridden without `hashCode()` → add `@Override public int hashCode() { return Objects.hash(sameFieldsUsedInEquals); }` (S1206)
* Unwrap a `@Repeatable` container annotation
  `@Xs({@X("a"), @X("b")})` → `@X("a") @X("b")` — only when the annotation is declared `@Repeatable` (S1710)
* Child method matching the parent signature but missing `@Override` → add `@Override` (S2177)
* Remove `@Nonnull`/`@NonNull` from an `equals()` parameter (S4454)
* Remove `@CheckForNull`/`@Nullable`/`@NotNull` from a primitive type — primitives cannot be null (S4682)

**Flag only — adds TODO comment, does not auto-fix:**

* `equals()` overridden without `Comparable` → add `// TODO: S1210 implement compareTo() consistent with equals()` (S1210)
* `@Deprecated` API used → add `// TODO: S1874 deprecated — replace with current alternative` (S1874)
* `assertThat(x)` with no chained assertion → add `// TODO: S2970 incomplete assertion — add verification` (S2970)
* `assert param != null` on a public method parameter → `if (param == null) throw new IllegalArgumentException("param must not be null")` (S4274)
* `@Deprecated`-for-removal API used → add `// TODO: S5738 marked for removal — replace before next major version` (S5738)
* `@VisibleForTesting` member used in production → add `// TODO: S5803 test-only — do not use in production` (S5803)
* `assert` statement in production code → add `// TODO: S5960 move this assertion to a test class` (S5960)

---

## SPRING

*(S3751, S6818, S6831, S6833, S6856, S6838)*

**Auto-fix:**

* `@RequestMapping` method is private → change it to public or package-private (S3751)
* Single constructor annotated `@Autowired` → remove `@Autowired` (Spring injects a single constructor automatically) (S6818)
* `@Qualifier` on a `@Bean` method → remove it (the `@Bean` method name is already the qualifier) (S6831)
* `@Controller` where **every** declared method has `@ResponseBody` → replace `@Controller` with `@RestController` and remove `@ResponseBody` from each method — skip if even one declared method lacks `@ResponseBody` (S6833)
* Path variable in the mapping without `@PathVariable`
  `@GetMapping("/x/{id}") Order get(Long id)` → `Order get(@PathVariable Long id)` — verify the parameter name matches the template (S6856)

**Flag only — adds TODO comment, does not auto-fix:**

* `@Bean` method called directly in a non-proxy `@Configuration` → add `// TODO: S6838 inject as a constructor/method parameter instead of calling directly` (S6838)

---

## TEST QUALITY

*(S2925, S3415, S5779, S5790, S5810, S5831, S5833, S5838, S5841, S5845, S5863, S5866, S5958, S6068, S6103)*

**Flag only — adds TODO comment, does not auto-fix:**

* `Thread.sleep()` in a test → add `// TODO: S2925 use Awaitility.await() or mock the time source` (S2925)
* Wrong assertion order (expected/actual swapped)
  `assertEquals(actual, expected)` → `assertEquals(expected, actual)`, e.g. `assertEquals(user.getName(), "John")` → `assertEquals("John", user.getName())` (S3415)
* Assertion inside a `try`/`catch(Error)` → move it after the try-catch block (S5779)
* JUnit 5 inner test class missing `@Nested` → add `@Nested` (S5790)
* JUnit 5 test class/method not visible → make the class public and the method public or package-private with `@Test` (S5810)
* `SoftAssertions` used outside `assertSoftly` → `SoftAssertions.assertSoftly(s -> { s.assertThat(x).isEqualTo(1); });` (S5831)
* `.as()` placed after the assertion → move it before
  `assertThat(x).isEqualTo(y).as("d")` → `assertThat(x).as("d").isEqualTo(y)` (S5833)
* Chained AssertJ assertion → use the dedicated method
  `assertThat(list.size()).isEqualTo(3)` → `assertThat(list).hasSize(3)`
  `assertThat(str.contains("x")).isTrue()` → `assertThat(str).contains("x")` (S5838)
* `allMatch`/`doesNotContain` without an emptiness check → add `assertThat(list).isNotEmpty()` first (S5841)
* Assertion comparing incompatible types → add `// TODO: S5845 types are incompatible — this assertion always fails` (S5845)
* `assertThat(x).isEqualTo(x)` (same object) → remove it (always passes) (S5863)
* `CASE_INSENSITIVE` without `UNICODE_CASE`
  `Pattern.compile("x", CASE_INSENSITIVE)` → `Pattern.compile("x", CASE_INSENSITIVE | UNICODE_CASE)` (S5866)
* `assertThatThrownBy` with no chained assertion → add `.isInstanceOf(Exception.class)` and `// TODO: S5958 replace with the actual expected exception type` (S5958)
* `Mockito.when(...)` → static-import `when(...)` for readability (S6068)
* Consumer argument with no `assertThat` inside → add `// TODO: S6103 add an assertion inside this consumer lambda` (S6103)

---

## SECURITY (MECHANICAL)

*(S2151, S2254, S4830, S5445, S5527, S2755, S6373, S6376, S5542, S5547)*

**Auto-fix:**

* Remove the `runFinalizersOnExit()` call entirely (S2151)
* `request.getRequestedSessionId()` → `request.getSession().getId()` (S2254)
* Remove a trust-all `TrustManager` (accepts all certs) and any `HostnameVerifier` that always returns true (S4830)
* `File.createTempFile(...)` → `Files.createTempFile(...)` (S5445)
* Remove `HttpsURLConnection.setDefaultHostnameVerifier(...)` that bypasses hostname verification (S5527)
* XML parser missing XXE protection → add `factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)` (S2755)
* XML parser missing secure processing → add `factory.setFeature(XMLConstants.FEATURE_SECURE_PROCESSING, true)` (S6373)
* XML parser missing DoS limits → add `factory.setProperty(XMLConstants.ACCESS_EXTERNAL_DTD, "")` and `factory.setProperty(XMLConstants.ACCESS_EXTERNAL_SCHEMA, "")` (S6376)

**Flag only — changing a cipher breaks encrypted data, requires manual migration:**

* Weak cipher (DES/RC2) → add `// TODO: S5542 weak cipher — migrate to AES/GCM/NoPadding (data migration required)` — do NOT auto-replace (S5542)
* ECB cipher mode → add `// TODO: S5547 ECB is insecure — migrate to AES/GCM/NoPadding (IV + data migration required)` — do NOT auto-replace (S5547)

---

## STRUCTURE

*(S3984, S2167, S4351, S2127, S2225, S6913, S2677, S1872, S3038, S4087, S4517, S4925, S2209, S2676, S3039, S3398, S2232, S2689, S2864, S6810)*

**Auto-fix:**

* Exception created as a statement but never thrown → add `throw`
  `new IllegalArgumentException("msg")` → `throw new IllegalArgumentException("msg")` (S3984)
* `compareTo()` returns `Integer.MIN_VALUE` → return `-1` (negated `MIN_VALUE` is still `MIN_VALUE`, breaking the contract) (S2167)
* `compareTo()` overloaded with a non-`Object` parameter → remove the overload (S4351)
* `Double.longBitsToDouble(intVal)` → `Double.longBitsToDouble((long) intVal)` (S2127)
* `toString()`/`clone()` returning null → `toString()`: `return ""`; `clone()`: `return super.clone()` wrapped in try-catch `AssertionError` (S2225)
* `Math.clamp()` args clearly inverted → `Math.clamp(val, max, min)` → `Math.clamp(val, min, max)` (S6913)
* `stream.read()` result ignored → assign and check it: `int n = stream.read();` (S2677)
* Comparing a class by name → use `instanceof` or a class literal
  `obj.getClass().getName().equals("com.Foo")` → `obj instanceof com.Foo` or `obj.getClass() == com.Foo.class` (S1872)
* Interface method already declared in a parent interface → remove the redundant declaration (S3038)
* Explicit `resource.close()` inside try-with-resources → remove it (closed automatically) (S4087)
* `return buf[pos]` in `InputStream.read()` → `return buf[pos] & 0xFF` (signed-byte fix) (S4517)
* `Class.forName("com.mysql.jdbc.Driver")` → remove entirely (JDBC 4.0+ auto-loads drivers) (S4925)
* Static member accessed via an instance → access via the class: `instance.staticField` → `ClassName.staticField` (S2209)

**Flag only — adds TODO comment, does not auto-fix:**

* `Math.abs(MIN_VALUE)` → add `// TODO: S2676 Math.abs(MIN_VALUE) returns MIN_VALUE — add a bounds check` (S2676)
* String operation index may be out of bounds → add `// TODO: S3039 verify this index is within string bounds` (S3039)
* Private method used only by an inner class → add `// TODO: S3398 consider moving this method to the inner class` (S3398)
* `ResultSet.isLast()` is unreliable → add `// TODO: S2232 not portable — use cursor position tracking` (S2232)
* `ObjectOutputStream` opened in append mode → add `// TODO: S2689 append mode corrupts the stream — open in overwrite mode` (S2689)
* `map.keySet()` when the value is also needed → use `entrySet()`
  `for (Map.Entry<K,V> e : map.entrySet()) { e.getKey(); e.getValue(); }` (S2864)
* Async method returning something other than void/`Future` → add `// TODO: S6810 async method should return void or Future` (S6810)
