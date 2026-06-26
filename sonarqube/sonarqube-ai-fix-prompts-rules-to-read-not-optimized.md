## 📖 RULES REFERENCE

*All prompts above apply these rules. One canonical list — no repetition.*

\---

### NAMING

*(S117, S119)*

* Local variable and parameter names must be camelCase
Example: `String UserName = ...` → `String userName = ...` (S117)
* Type parameter names: single uppercase letter or end with T
Example: `<type>` → `<T>`, `<orderType>` → `<OrderT>` (S119)

\---

### DEAD CODE

*(S1068, S1128, S1144, S1172, S1481)*

* Remove unused private fields
Skip if annotated with: @Autowired, @Inject, @Value, @Column (S1068)
* Remove unused imports (S1128)
* Remove unused private methods
Skip if annotated with: @Bean, @EventListener, @Scheduled, @PostConstruct (S1144)
* Remove unused method parameters — ONLY for private methods (S1172)
* Remove unused local variables (S1481)

\---

### NULL AND BOOLEAN

*(S1125, S1126, S1155, S2583, S2589)*

**Auto-fix:**

* Remove redundant boolean literals
`if (x == true)` → `if (x)`, `if (x == false)` → `if (!x)`, `return x == true` → `return x` (S1125)
* Remove unnecessary else after jump statement
`if (x) { return a; } else { b(); }` → `if (x) { return a; } b();` (S1126)
* Use isEmpty() instead of size() comparisons
`list.size() == 0` → `list.isEmpty()`, `list.size() > 0` → `!list.isEmpty()` (S1155)
**Flag only — adds TODO comment, does not auto-fix:**
* Always-true or always-false conditions → add `// TODO: S2583 verify condition is intentional` — do NOT remove automatically (S2583)
* Gratuitous boolean expressions → add `// TODO: S2589 verify this condition` — do NOT remove automatically (S2589)

\---

### CODE STYLE

*(S1110, S1121, S1124, S1132, S1192, S1195, S1197, S1219, S1264, S1444, S1596, S1764, S2147, S2154, S2183, S3252, S3599, S3973, S4165, S4425, S4454, S4719, S7158)*

**Auto-fix:**

* Remove redundant parentheses that add no meaning
`return (x + y)` → `return x + y`
Skip if parens clarify operator precedence: `(a + b) \\\* c` — keep (S1110)
* Extract assignments from sub-expressions to separate statements
`if ((x = compute()) != null)` → `x = compute(); if (x != null)` (S1121)
* Reorder modifiers to canonical Java order: public/protected/private → abstract → static → final
Example: `final static public int X` → `public static final int X` (S1124)
* Flip string literal to left side of equals to prevent NPE
`variable.equals("LITERAL")` → `"LITERAL".equals(variable)`
Skip if variable is @NotNull or provably non-null (S1132)
* Extract duplicate string literals (3+ occurrences) to named constant
Name the constant using the string value in SCREAMING\_SNAKE\_CASE
Example: `"ERROR"` → `private static final String ERROR = "ERROR"`
Example: `"order.created"` → `private static final String ORDER\\\_CREATED = "order.created"` (S1192)
* Array designator must be on type, not variable
`int a\\\[]` → `int\\\[] a`, `String method()\\\[]` → `String\\\[] method()` (S1195, S1197)
* Remove non-case labels from switch blocks (S1219)
* Convert for loop to while when index not used in update
`for (; condition;)` → `while (condition)`
Only when loop variable is not used in the update clause (S1264)
* public static field must be final — skip if field has any assignment outside its declaration (S1444)
* Replace deprecated empty collection constants
`Collections.EMPTY\\\_LIST` → `Collections.emptyList()`
`Collections.EMPTY\\\_MAP` → `Collections.emptyMap()`
`Collections.EMPTY\\\_SET` → `Collections.emptySet()` (S1596)
**Flag only — adds TODO comment, does not auto-fix:**
* Identical expressions on both sides of operator → flag
`a == a`, `a \\\&\\\& a`, `a || a` → add `// TODO: S1764 identical expressions — verify intent` (S1764)
* Merge compatible catch clauses with identical bodies
`catch (A e) { log(e); } catch (B e) { log(e); }` → `catch (A | B e) { log(e); }`
Skip if catch bodies differ even slightly (S2147)
* Dissimilar wrapper types in ternary → add explicit cast
`condition ? intVal : longVal` → `condition ? (long) intVal : longVal` (S2154)
* Remove useless bit shifts (shift by 0 or by >= number of bits)
`x << 0` → `x`
`x << 32` on int → add `// TODO: S2183 shift by 32 always gives 0 for int — verify intent` (S2183)
* Static member accessed via derived type → access via declaring class
`Child.PARENT\\\_CONSTANT` → `Parent.PARENT\\\_CONSTANT` (S3252)
* Remove Double Brace Initialization → replace with explicit add() calls
`new ArrayList<>() {{ add("a"); add("b"); }}` → `List<String> list = new ArrayList<>(); list.add("a"); list.add("b");` (S3599)
* Single-line conditional without braces → add braces
`if (x) doIt();` → `if (x) { doIt(); }` (S3973)
* Remove redundant assignments
Skip if class is annotated with: @Entity, @MappedSuperclass, @Embeddable
Skip if field is annotated with: @Column, @Id, @Transient (S4165)
* Integer.toHexString for sign-safe hex → String.format
`Integer.toHexString(n)` → `String.format("%x", n)` (S4425)
* Remove @Nonnull/@NonNull annotation from equals() parameter
`equals(@Nonnull Object obj)` → `equals(Object obj)` (S4454)
* Replace string charset with StandardCharsets constant
`"UTF-8"` → `StandardCharsets.UTF\\\_8`, `"ISO-8859-1"` → `StandardCharsets.ISO\\\_8859\\\_1` (S4719)
* String.length() == 0 → String.isEmpty()
`str.length() == 0` → `str.isEmpty()`, `str.length() > 0` → `!str.isEmpty()` (S7158)

\---

### STRING

*(S1153, S1858, S2112, S2200, S2629, S2639, S3039, S5361)*

* Remove String.valueOf() when appending to String
`"prefix" + String.valueOf(x)` → `"prefix" + x` (S1153)
* Inappropriate regex pattern — flag known problematic patterns
Add `// TODO: S2639 verify this regex is correct and handles edge cases` (S2639)
* String operation index must be within string bounds — flag
Add `// TODO: S3039 verify this index is within string bounds` (S3039)
* toString() called on a String → remove the call
`str.toString()` → `str` (S1858)
* URL.hashCode/equals is broken for URLs → use URI instead
`new URL(str).equals(other)` → wrap in try-catch URISyntaxException or add
`// TODO: S2112 URL.equals is broken — replace with URI` (S2112)
* compareTo result must be compared with 0 not specific values
`a.compareTo(b) == -1` → `a.compareTo(b) < 0` (S2200)
* Logging/Preconditions arguments must not require evaluation at call site
`log.debug("Value: " + value)` → `log.debug("Value: {}", value)` (S2629)
* String.replace preferred over replaceAll when pattern has no regex metacharacters
`str.replaceAll(".", "x")` → `str.replace(".", "x")`
Only apply when the pattern string contains no regex metacharacters: . \* + ? ^ $ { } \[ ] | ( ) \\ (S5361)

\---

### LAMBDA AND FUNCTIONAL

*(S1150, S1488, S1602, S1611, S2438, S3012, S3631, S3864, S3958, S3959, S4034, S4065, S4348, S6204)*

**Auto-fix:**

* Return expression directly instead of assign-then-return
`String result = compute(); return result;` → `return compute();`
Skip if the variable is used in a finally block or try-with-resources (S1488)
* Lambda block with single return statement → expression form
`x -> { return x.getName(); }` → `x -> x.getName()` (S1602)
* Remove unnecessary parentheses around single lambda parameter
`(x) -> x.getName()` → `x -> x.getName()` (S1611)
* Thread where Runnable is expected → extract Runnable
`new Thread(myThread)` where myThread is a Thread →
`new Thread(() -> myThread.run())` (S2438)
* Arrays/lists copied with loops → use built-in methods
`for (int i=0; i<src.length; i++) dst\\\[i] = src\\\[i]` → `System.arraycopy(src, 0, dst, 0, src.length)`
`for (X x : src) dst.add(x)` → `dst.addAll(src)` (S3012)
* Use Arrays.stream() for primitive arrays for simple aggregations only
Applies to int\[], long\[], double\[] arrays
`for (int x : arr) { sum += x; }` → `int sum = Arrays.stream(arr).sum()`
`for (int x : arr) { count++; }` → `long count = Arrays.stream(arr).count()`
Only apply for sum, count, average — do NOT convert loops with complex logic to streams (S3631)
**Flag only — adds TODO comment, does not auto-fix:**
* Stream.peek() used to modify elements → flag
Add `// TODO: S3864 peek should not modify elements — use map() or forEach()` (S3864)
* Intermediate stream method result unused → add terminal operation
`list.stream().filter(x -> x > 0)` → add `.collect(Collectors.toList())` or `.forEach(...)` or `.count()` (S3958)
* Consumed stream pipeline reused → flag
Add `// TODO: S3959 stream already consumed — create a new stream` (S3959)
* Simplify stream chains:
`.filter(x -> true)` → remove filter
`.map(x -> x)` → remove map
`.sorted().sorted()` → one `.sorted()` (S4034)
* ThreadLocal → use ThreadLocal.withInitial()
`new ThreadLocal<List>() { protected List initialValue() { return new ArrayList<>(); } }`
→ `ThreadLocal.withInitial(ArrayList::new)` (S4065)
* iterator() must not return `this` → create a proper Iterator implementation
Before: `return this;`
After — anonymous Iterator inside the class:

```java
  return new Iterator<T>() {
      int index = 0;
      public boolean hasNext() { return index < size; }
      public T next() {
          if (!hasNext()) throw new NoSuchElementException();
          return data\\\[index++];
      }
  };
  ```

(S4348)

* Stream.toList() over Collectors.toUnmodifiableList() — only Java 16+
Check Java version in pom.xml first. If Java 16+:
`.collect(Collectors.toUnmodifiableList())` → `.toList()` (S6204)
* Enumeration not implemented → replace with Iterator
Only for private/internal usage — skip if method is public API (S1150)

  \---

  ### EXCEPTION HANDLING

  *(S108, S1143, S1166, S1181, S1989, S2142, S2151, S2235, S2272, S2737, S3346)*

  **Auto-fix:**

* Empty catch block → add logging
If logger exists: `log.warn("Ignored {}: {}", e.getClass().getSimpleName(), e.getMessage(), e)`
If no logger: add SLF4J logger declaration first, then add warn line (S108)
**Flag only — adds TODO comment, does not auto-fix:**
* Jump statement (return/throw/break) in finally block → flag
Add `// TODO: S1143 jump in finally masks original exception — review` (S1143)
* Swallowed exception (caught but not logged or rethrown) → add logging
Add `log.warn("Unexpected exception", e)` before the existing catch body
Apply regardless of whether catch body is empty or has code — always add the log line (S1166)
* catch(Throwable) or catch(Error) → flag
Add `// TODO: S1181 too broad catch — narrow to specific exception type` (S1181)
* Exception thrown from servlet methods → wrap in try-catch, log, send error response
Example:

  ```java
// before

  // before
public void doGet(HttpServletRequest req, HttpServletResponse res) throws IOException {
process(req); // may throw
}
// after
public void doGet(HttpServletRequest req, HttpServletResponse res) {
try {
process(req);
} catch (Exception e) {
log.error("Request processing failed", e);
res.sendError(HttpServletResponse.SC\_INTERNAL\_SERVER\_ERROR);
}
}

  ```

  (S1989)

\* InterruptedException → restore interrupt flag
Add `Thread.currentThread().interrupt()` before or after existing catch body (S2142)
\* runFinalizersOnExit() → remove the call entirely (S2151)
\* catch(IllegalMonitorStateException) → remove catch block
Inspect all method calls inside the try block.
If none declare checked exceptions other than IllegalMonitorStateException → remove the catch block safely.
If any method call declares other checked exceptions → skip and add:
`// TODO: S2235 remove this catch only if no other checked exceptions are thrown in this try block` (S2235)
\* Iterator.next() must throw NoSuchElementException when exhausted
Add: `if (!hasNext()) throw new NoSuchElementException();` at start of next() method (S2272)
\* catch block that only rethrows → remove try/catch
Only for unchecked exceptions. For checked exceptions: add `// TODO: S2737 verify callers handle this checked exception before removing` (S2737)
\* assert expression with side effects → flag
Add `// TODO: S3346 move side effect out of assert — asserts may be disabled at runtime` (S3346)

  \\---

  ### COLLECTIONS AND LOOPS

  \*(S127, S1155, S1319, S1994, S2175, S2189, S2251, S2252, S3012, S3020, S3878, S3923, S3981, S4838, S5413, S6417, S6466)\*

  \*\*Auto-fix:\*\*

\* Use isEmpty() instead of size() comparisons
`list.size() == 0` → `list.isEmpty()`, `str.length() == 0` → `str.isEmpty()` (S1155)
\* for loop stop condition must not be invariant (never changes during loop execution)
Add `// TODO: S127 this stop condition never changes — verify loop termination` (S127)
\* for loop increment clause must modify the loop counter variable
Add `// TODO: S1994 for loop increment does not modify the loop counter` (S1994)
\* Collection must not be modified while being iterated — flag
Add `// TODO: S6417 modifying collection during iteration causes ConcurrentModificationException` (S6417)
\* Array index access that may be out of bounds — flag
Add `// TODO: S6466 verify array bounds before access` (S6466)
\* Declare collection variables using interface type
`ArrayList<Order> list = new ArrayList<>()` → `List<Order> list = new ArrayList<>()`
`HashMap<K,V> map = new HashMap<>()` → `Map<K,V> map = new HashMap<>()` (S1319)
\*\*Flag only — adds TODO comment, does not auto-fix:\*\*
\* Inappropriate Collection method call → flag
Example: `set.contains(differentTypeList)` when types are incompatible →
Add `// TODO: S2175 incompatible types in collection call — verify intent` (S2175)
\* Infinite loop with no exit condition → flag
Add `// TODO: S2189 verify this loop has a reachable exit condition` (S2189)
\* for loop counter going in wrong direction → flag only
Add `// TODO: S2251 verify loop direction — do not auto-fix, semantics may be intentional` (S2251)
\* Loop condition is always false → flag
Add `// TODO: S2252 loop condition is always false — this loop never executes` (S2252)
\* Arrays/lists not copied with loops → use built-in (see LAMBDA AND FUNCTIONAL S3012)
\* Collection.toArray() with correct typed array
If list has generic type `List<String>`: `list.toArray()` → `list.toArray(new String\\\[0])`
If list is raw type: add `// TODO: S3020 add typed toArray — generic type unknown` (S3020)
\* Arrays must not be created for varargs parameters
`method(new String\\\[]{"a", "b"})` → `method("a", "b")` (S3878)
\* All branches in conditional have identical implementation → flag
Add `// TODO: S3923 all branches identical — verify this is intentional` — do NOT remove automatically (S3923)
\* Collection size comparisons that are always true/false → flag
`list.size() >= 0` is always true → add `// TODO: S3981 this condition is always true` (S3981)
\* Iteration must be on the correct generic type
Iterating `Map<String,X>` as raw `Map` → add generic type parameter (S4838)
\* List.remove() in ascending for loop removes wrong element → flag
Add `// TODO: S5413 use Iterator.remove() or iterate in reverse` (S5413)

  \\---

  ### CONCURRENCY

  \*(S2066, S2168, S2273, S2274, S2276, S2445, S2446, S3014, S3066, S3067, S3078, S5164, S6901)\*

  \*\*Auto-fix:\*\*

\* Serializable inner class must be static → add `static` keyword (S2066)
\* enum fields must not be publicly mutable — add final or reduce visibility
`public Status status = ACTIVE` → `private final Status status` (S3066)
\*\*Flag only — adds TODO comment, does not auto-fix:\*\*
\* Double-checked locking without volatile → flag
Add `// TODO: S2168 double-checked locking requires volatile field to be safe` (S2168)
\* wait()/notify()/notifyAll() must only be called from synchronized code
Example:

  ```java
// before (missing sync)
object.wait();
// after
synchronized (object) { object.wait(); }
```

  (S2273)

* wait()/await() must be inside a while loop, not an if
`if (!condition) wait()` → `while (!condition) wait()` (S2274)
* Thread.sleep() when a lock is held → use wait()
Replace `Thread.sleep(n)` inside synchronized block with `wait(n)` (S2276)
* Synchronize only on private final fields
If sync target is not private final → add `// TODO: S2445 synchronize on a private final lock object` (S2445)
* notifyAll() preferred over notify() to avoid thread starvation
`notify()` → `notifyAll()` (S2446)
* ThreadGroup → replace with Executor
`new ThreadGroup("workers")` → add `// TODO: S3014 replace ThreadGroup with Executors.newCachedThreadPool() or choose appropriate thread count`
Do NOT auto-choose thread count — flag for developer decision (S3014)
* getClass() must not be used for synchronization → use class literal
`synchronized(this.getClass())` → `synchronized(MyClass.class)` (S3067)
* volatile field with compound operator → flag
`volatileField++` → add `// TODO: S3078 use AtomicInteger/AtomicLong for thread-safe compound operations` (S3078)
* ThreadLocal variables must be cleaned up → add remove() in finally

  ```java
try {

  try {
threadLocal.set(value);
// ... work ...
} finally {
threadLocal.remove();
}

  ```

  (S5164)

\* setDaemon()/setPriority()/getThreadGroup() must not be called on virtual threads → flag
Add `// TODO: S6901 these methods have no effect on virtual threads` (S6901)

  \\---

  ### SERIALIZATION

  \*(S2060, S2061, S2062, S2157, S2675, S2975, S6218)\*

  \*\*Auto-fix:\*\*

\* Externalizable class must have no-args constructor → generate
Add `public ClassName() {}` constructor (S2060)
\* Custom serialization methods must have correct signatures:
`private void writeObject(ObjectOutputStream oos) throws IOException`
`private void readObject(ObjectInputStream ois) throws IOException, ClassNotFoundException`
Fix any deviation from these exact signatures (S2061)
\* readResolve() must be inheritable → change from private to protected
`private Object readResolve()` → `protected Object readResolve()` (S2062)
\* Cloneable class must implement clone() → generate method

  ```java
@Override
public Object clone() {
    try { return super.clone(); }
    catch (CloneNotSupportedException e) { throw new AssertionError(); }
}
```

  (S2157)

* readObject() must not be synchronized → remove synchronized keyword (S2675)
**Flag only — adds TODO comment, does not auto-fix:**
* clone() should not be overridden → flag
Add `// TODO: S2975 clone() is broken by design — consider copy constructor instead` (S2975)
* equals() must be overridden in records containing array fields
Use Arrays.equals() for array fields, Objects.equals() for others
Example (Java 16+ pattern matching syntax — check Java version in pom.xml first):

  ```java
  record Point(int\\\[] coords, String name) {
      @Override public boolean equals(Object o) {
          if (!(o instanceof Point p)) return false;
          return Arrays.equals(coords, p.coords) \\\&\\\& Objects.equals(name, p.name);
      }
      @Override public int hashCode() {
          return Objects.hash(Arrays.hashCode(coords), name);
      }
  }
  ```

  If Java < 16: use `if (!(o instanceof Point)) return false; Point p = (Point) o;` instead (S6218)

  \---

  ### ANNOTATIONS AND BOILERPLATE

  *(S1161, S1174, S1206, S1210, S1710, S1874, S2177, S2970, S4274, S4454, S4682, S5738, S5803, S5960)*

  **Auto-fix:**

* Add missing @Override to methods overriding or implementing (S1161)
* Flag usage of @Deprecated code with a comment
Add `// TODO: S1874 this API is deprecated — replace with current alternative` (S1874)
* When equals() is overridden, hashCode() must also be overridden — generate hashCode()
Use Objects.hash() with the same fields used in equals():

  ```java
@Override public int hashCode() {

  @Override public int hashCode() {
return Objects.hash(field1, field2);
}

  ```

  (S1206)

\* When equals() is overridden, implement Comparable and add compareTo() — generate stub
Add `// TODO: S1210 implement compareTo() consistent with equals()` if fields not obvious (S1210)
\* Unwrap repeated annotation containers to individual repeated annotations
`@SomeAnnotations({@SomeAnnotation("a"), @SomeAnnotation("b")})` →
`@SomeAnnotation("a") @SomeAnnotation("b")` — only when annotation is declared @Repeatable (S1710)
\* finalize() must be protected, not public
`public void finalize()` → `protected void finalize()` (S1174)
\* Child method named like parent method but missing @Override → add @Override (S2177)
\*\*Flag only — adds TODO comment, does not auto-fix:\*\*
\* Incomplete assertions → flag incomplete assertion
`assertThat(x)` with no chained verification → add `// TODO: S2970 incomplete assertion — add .isNotNull() or appropriate verification` (S2970)
\* assert statements must not check public method parameters → replace with if+throw
`assert param != null` → `if (param == null) throw new IllegalArgumentException("param must not be null")` (S4274)
\* Remove @Nonnull/@NonNull from equals() parameter
`equals(@Nonnull Object obj)` → `equals(Object obj)` (S4454)
\* Remove @CheckForNull/@Nullable from primitive type fields/params
`@Nullable int count` → `int count` — primitives cannot be null (S4682)
\* Flag usage of @Deprecated-for-removal APIs
Add `// TODO: S5738 this API is marked for removal — replace before next major version` (S5738)
\* @VisibleForTesting members must not be accessed from production code → flag
Add `// TODO: S5803 this member is test-only — do not use in production code` (S5803)
\* Assertion statements must not appear in production code → flag
Add `// TODO: S5960 move this assertion to a test class` (S5960)

  \\---

  ### SPRING

  \*(S3751, S6818, S6831, S6833, S6838, S6856)\*

  \*\*Auto-fix:\*\*

\* @RequestMapping methods must not be private → change to public or package-private (S3751)
\* Single constructor must not use @Autowired → remove @Autowired annotation (S6818)
\* Remove @Qualifier from @Bean methods — @Bean name is the qualifier (S6831)
\* @Controller where all declared methods have @ResponseBody → replace with @RestController
Check only methods declared in this class (not inherited).
If every declared method has @ResponseBody: replace @Controller with @RestController and remove @ResponseBody from each method.
If even one declared method lacks @ResponseBody → skip (S6833)
\* Add @PathVariable when path variable used in mapping
`@GetMapping("/orders/{id}") public Order get(Long id)` →
`public Order get(@PathVariable Long id)` — verify variable name matches path template (S6856)

  \*\*Flag only — adds TODO comment, does not auto-fix:\*\*

\* @Bean method in non-proxy @Configuration invoked directly → flag
Add `// TODO: S6838 do not invoke @Bean method directly — inject as constructor/method parameter` (S6838)

  \\---

  ### TEST QUALITY

  \*(S2925, S3415, S5779, S5790, S5810, S5831, S5833, S5838, S5841, S5845, S5863, S5866, S5958, S6068, S6103)\*

  \*\*Auto-fix:\*\*

  \*\*Flag only — adds TODO comment, does not auto-fix:\*\*

\* Thread.sleep() in tests → flag
Add `// TODO: S2925 replace with Awaitility.await() or mock the time source` (S2925)
\* Assertion arguments must be in correct order: expected value first, actual value second
`assertEquals(actual, expected)` → `assertEquals(expected, actual)`
Example: `assertEquals(user.getName(), "John")` → `assertEquals("John", user.getName())` (S3415)
\* Assertions must not be inside try-catch catching Error → move outside
Extract assertion to after the try-catch block (S5779)
\* JUnit5 inner test classes must be annotated with @Nested → add annotation (S5790)
\* JUnit5 test class or method silently ignored → fix visibility
Ensure test class is public and test method is public or package-private with @Test (S5810)
\* AssertJ SoftAssertions must be configured → use assertSoftly or @ExtendWith(SoftAssertionsExtension.class)
Example: `SoftAssertions.assertSoftly(softly -> { softly.assertThat(x).isEqualTo(1); });` (S5831)
\* AssertJ context-setting method must come before assertion
`assertThat(x).isEqualTo(y).as("description")` → `assertThat(x).as("description").isEqualTo(y)` (S5833)
\* Chained AssertJ assertions → use dedicated assertion method
`assertThat(list.size()).isEqualTo(3)` → `assertThat(list).hasSize(3)`
`assertThat(str.contains("x")).isTrue()` → `assertThat(str).contains("x")` (S5838)
\* AssertJ allMatch/doesNotContain → first assert not empty
Add `assertThat(list).isNotEmpty()` before `assertThat(list).allMatch(...)` (S5841)
\* Assertions comparing incompatible types → flag
Add `// TODO: S5845 types are incompatible — this assertion will always fail` (S5845)
\* Assertion comparing object to itself → remove
`assertThat(x).isEqualTo(x)` → remove, always passes (S5863)
\* Case-insensitive regex must use UNICODE\\\_CASE flag alongside CASE\\\_INSENSITIVE
`Pattern.compile("abc", CASE\\\_INSENSITIVE)` →
`Pattern.compile("abc", CASE\\\_INSENSITIVE | UNICODE\\\_CASE)` (S5866)
\* AssertJ assertThatThrownBy must have a following assertion
Add `.isInstanceOf(Exception.class)` as a safe placeholder:
`assertThatThrownBy(() -> method())` →
`assertThatThrownBy(() -> method()).isInstanceOf(Exception.class)`
Add `// TODO: S5958 replace Exception.class with the actual expected exception type` (S5958)
\* Mockito verify/when/given calls → use static imports for readability
`Mockito.when(mock.method()).thenReturn(x)` → `when(mock.method()).thenReturn(x)` with static import (S6068)
\* AssertJ Consumer arguments must contain an assertion inside
If Consumer lambda has no assertThat call → add `// TODO: S6103 add assertion inside this consumer lambda`
Example: `assertThat(list).allSatisfy(item -> { assertThat(item).isNotNull(); })` (S6103)

  \\---

  ### SECURITY (MECHANICAL)

  \*(S2151, S2254, S4830, S5445, S5527, S5542, S5547, S6373, S6376, S2755)\*

  \*\*Auto-fix:\*\*

\* runFinalizersOnExit() → remove the call entirely (S2151)
\* HttpServletRequest.getRequestedSessionId() → replace with session ID from session object
`request.getRequestedSessionId()` → `request.getSession().getId()` (S2254)
\* SSL certificate verification disabled → remove trust-all implementation
Remove custom TrustManager that accepts all certs, remove setHostnameVerifier that returns true always (S4830)
\* Insecure temporary file creation → Files.createTempFile()
`File.createTempFile(...)` → `Files.createTempFile(...)` (S5445)
\* SSL hostname verification disabled → remove
Remove `HttpsURLConnection.setDefaultHostnameVerifier(...)` that bypasses verification (S5527)
\*\*Flag only — changing cipher breaks encrypted data, requires manual migration:\*\*
\* Weak cipher algorithm → flag for manual migration
`Cipher.getInstance("DES")` or `Cipher.getInstance("RC2")` →
Add `// TODO: S5542 weak cipher — migrate to AES/GCM/NoPadding (requires data migration plan)`
Do NOT auto-replace — changing cipher breaks all previously encrypted data (S5542)
\* ECB cipher mode → flag for manual migration
`Cipher.getInstance("AES/ECB/...")` →
Add `// TODO: S5547 ECB mode is insecure — migrate to AES/GCM/NoPadding (requires IV management and data migration)`
Do NOT auto-replace — changing mode breaks all previously encrypted data (S5547)
\* XML external entity inclusion → enable secure processing
Apply to: DocumentBuilderFactory, SAXParserFactory, XMLInputFactory
Example:

  ```java
DocumentBuilderFactory factory = DocumentBuilderFactory.newInstance();
factory.setFeature(XMLConstants.FEATURE\\\_SECURE\\\_PROCESSING, true);
```

  (S6373)

* XML parser DoS limits → set restrictive properties

  ```java
factory.setProperty(XMLConstants.ACCESS\\\_EXTERNAL\\\_DTD, "");

  factory.setProperty(XMLConstants.ACCESS\_EXTERNAL\_DTD, "");
factory.setProperty(XMLConstants.ACCESS\_EXTERNAL\_SCHEMA, "");

  ```

  (S6376)

\* XXE vulnerability → disable doctype declarations
`factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)` (S2755)

  \\---

  ### STRUCTURE

  \*(S1872, S2127, S2167, S2209, S2225, S2232, S2676, S2677, S2689, S2864, S3038, S3398, S3984, S4087, S4351, S4517, S4925, S6810, S6913)\*

  \*\*Auto-fix:\*\*

\* Exception created but not thrown → add throw keyword
`new IllegalArgumentException("msg")` as statement → `throw new IllegalArgumentException("msg")` (S3984)
\* compareTo() must not return Integer.MIN\\\_VALUE — return -1 instead
`return Integer.MIN\\\_VALUE` inside compareTo() → `return -1`
MIN\\\_VALUE negated is still MIN\\\_VALUE, which breaks contracts (S2167)
\* compareTo() must not be overloaded with a non-Object parameter
`compareTo(MyClass other)` alongside `compareTo(Object o)` → remove the overloaded version (S4351)
\* Double.longBitsToDouble() requires a long argument — add explicit cast
`Double.longBitsToDouble(intValue)` → `Double.longBitsToDouble((long) intValue)` (S2127)
\* toString() and clone() must not return null
`return null` in toString() → `return ""` or meaningful string
`return null` in clone() → `return super.clone()` wrapped in try-catch (S2225)
\* Math.abs() must not be called on values that could be Integer.MIN\\\_VALUE or Long.MIN\\\_VALUE
Add `// TODO: S2676 Math.abs(MIN\\\_VALUE) returns MIN\\\_VALUE — add bounds check` (S2676)
\* Math.clamp() must be called with min <= max — flag if constants are wrong order
`Math.clamp(value, max, min)` → `Math.clamp(value, min, max)` — swap if clearly inverted (S6913)
\* read() and readLine() return values must not be ignored
`stream.read()` as statement → `int bytesRead = stream.read()` and check value (S2677)
\* Class instances must not be compared by class name
`obj.getClass().getName().equals("com.example.Foo")` →
`obj instanceof com.example.Foo` or `obj.getClass() == com.example.Foo.class` (S1872)
\* String operation index out of bounds — flag
Add `// TODO: S3039 verify this index is within string bounds at runtime` (S3039)
\* Abstract method that is redundant → remove
Interface method already declared in parent interface → remove from child interface (S3038)
\* Redundant close() inside try-with-resources → remove explicit close() call (S4087)
\* InputStream.read() returns signed byte → fix with bitwise AND
`return buf\\\[pos]` in read() → `return buf\\\[pos] \\\& 0xFF` (S4517)
\* Class.forName() for JDBC 4.0+ drivers → remove the call
`Class.forName("com.mysql.jdbc.Driver")` → remove entirely (S4925)
\* private method only called from inner class → flag
Add `// TODO: S3398 consider moving this method to the inner class that uses it` (S3398)
\* Static members accessed via instance → access via class name
`instance.staticField` → `ClassName.staticField` (S2209)
\*\*Flag only — adds TODO comment, does not auto-fix:\*\*
\* ResultSet.isLast() is unreliable → flag
Add `// TODO: S2232 ResultSet.isLast() is not portable — use cursor position tracking instead` (S2232)
\* ObjectOutputStream opened in append mode → flag
Add `// TODO: S2689 ObjectOutputStream in append mode corrupts the stream — open in overwrite mode` (S2689)
\* Map.keySet() used when value also needed → use entrySet()
`for (String key : map.keySet()) { Obj v = map.get(key); }` →
`for (Map.Entry<String,Obj> e : map.entrySet()) { String key = e.getKey(); Obj v = e.getValue(); }` (S2864)
\* Async methods must return void or Future → flag non-compliant
Add `// TODO: S6810 async method should return void or Future` (S6810)


