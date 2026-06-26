# 📖 RULES REFERENCE — human-readable form

*The same 76 rules as `sonarqube-ai-fix-prompts-rules.md`, expanded with fuller descriptions and examples.*
*Every rule is a safe, mechanical auto-fix applied without human intervention. Rules that could only flag a `// TODO`, or whose fix could change behavior or require guessing intent, live in `sonarqube-excluded-rules.md`.*

---

## NAMING

*(S117, S119)*

* Local variable and parameter names must be camelCase
  `String UserName = ...` → `String userName = ...` (S117)
* Type parameter names: a single uppercase letter, or a name ending in `T`
  `<type>` → `<T>`, `<orderType>` → `<OrderT>` (S119)

---

## DEAD CODE

*(S1128, S1172, S1481)*

* Remove unused imports (S1128)
* Remove unused method parameters — **only** for private methods (S1172)
* Remove unused local variables (S1481)

---

## NULL AND BOOLEAN

*(S1125, S1126, S1155)*

* Remove redundant boolean literals
  `if (x == true)` → `if (x)`, `if (x == false)` → `if (!x)`, `return x == true` → `return x` (S1125)
* Remove the unnecessary `else` after a jump statement
  `if (x) { return a; } else { b(); }` → `if (x) { return a; } b();` (S1126)
* Use `isEmpty()` instead of `size()` comparisons
  `list.size() == 0` → `list.isEmpty()`, `list.size() > 0` → `!list.isEmpty()` (S1155)

---

## CODE STYLE

*(S1110, S1121, S1124, S1192, S1195, S1197, S1219, S1264, S1444, S1596, S2147, S2154, S3252, S3599, S3973, S4165, S4425, S4454, S4719, S7158)*

* Remove redundant parentheses that add no meaning
  `return (x + y)` → `return x + y` — keep parens that clarify precedence: `(a + b) * c` (S1110)
* Extract an assignment out of a sub-expression into its own statement
  `if ((x = compute()) != null)` → `x = compute(); if (x != null)` (S1121)
* Reorder modifiers to canonical Java order: public/protected/private → abstract → static → final
  `final static public int X` → `public static final int X` (S1124)
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
* Merge catch clauses with **identical** bodies into a multi-catch
  `catch (A e) { log(e); } catch (B e) { log(e); }` → `catch (A | B e) { log(e); }` — skip if the bodies differ even slightly (S2147)
* Dissimilar wrapper types in a ternary → add an explicit cast
  `condition ? intVal : longVal` → `condition ? (long) intVal : longVal` (S2154)
* Static member accessed via a derived type → access via the declaring class
  `Child.PARENT_CONSTANT` → `Parent.PARENT_CONSTANT` (S3252)
* Double-brace initialization → explicit `add()` calls
  `new ArrayList<>() {{ add("a"); add("b"); }}` → `List<String> list = new ArrayList<>(); list.add("a"); list.add("b");` (S3599)
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

---

## STRING

*(S1858, S2200, S2629)*

* `toString()` called on a String → remove the call
  `str.toString()` → `str` (S1858)
* A `compareTo` result must be compared with 0, not a specific value
  `a.compareTo(b) == -1` → `a.compareTo(b) < 0` (S2200)
* Logging/Preconditions arguments must not require concatenation at the call site
  `log.debug("Value: " + value)` → `log.debug("Value: {}", value)` (S2629)

---

## LAMBDA AND FUNCTIONAL

*(S1488, S1602, S1611, S2438, S3012, S3631, S4065)*

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
* `ThreadLocal` anonymous subclass → `ThreadLocal.withInitial(ArrayList::new)` (S4065)

---

## EXCEPTION HANDLING

*(S108, S2151)*

* Empty catch block → add logging
  `log.warn("Ignored {}: {}", e.getClass().getSimpleName(), e.getMessage(), e)`
  If no logger exists, add `private static final Logger log = LoggerFactory.getLogger(ClassName.class)` first (S108)
* Remove the `runFinalizersOnExit()` call entirely (S2151)

---

## COLLECTIONS AND LOOPS

*(S1155, S1319, S3012, S3878, S4838)*

* Use `isEmpty()` instead of `size()`/`length()` comparisons
  `list.size() == 0` → `list.isEmpty()`, `str.length() == 0` → `str.isEmpty()` (S1155)
* Declare collection variables using the interface type
  `ArrayList<Order> list` → `List<Order> list`, `HashMap<K,V> map` → `Map<K,V> map` (S1319)
* Array/list copied with a loop → use a built-in (see LAMBDA AND FUNCTIONAL S3012) (S3012)
* Array created for a varargs call → `method(new String[]{"a", "b"})` → `method("a", "b")` (S3878)
* Raw `Map` iteration → add the generic type parameter: `Map` → `Map<String, X>` (S4838)

---

## CONCURRENCY

*(S2066, S3066)*

* Serializable non-static inner class → add the `static` keyword (S2066)
* Enum field that is publicly mutable → make it `private final`
  `public Status status = ACTIVE` → `private final Status status` (S3066)

---

## SERIALIZATION

*(S2060, S2061, S2062, S2157, S2675)*

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

---

## ANNOTATIONS AND BOILERPLATE

*(S1161, S1174, S1710, S2177, S4454, S4682)*

* Add a missing `@Override` to methods that override or implement (S1161)
* `public void finalize()` → `protected void finalize()` (S1174)
* Unwrap a `@Repeatable` container annotation
  `@Xs({@X("a"), @X("b")})` → `@X("a") @X("b")` — only when the annotation is declared `@Repeatable` (S1710)
* Child method matching the parent signature but missing `@Override` → add `@Override` (S2177)
* Remove `@Nonnull`/`@NonNull` from an `equals()` parameter (S4454)
* Remove `@CheckForNull`/`@Nullable`/`@NotNull` from a primitive type — primitives cannot be null (S4682)

---

## SPRING

*(S3751, S6818, S6833, S6856)*

* `@RequestMapping` method is private → change it to public or package-private (S3751)
* Single constructor annotated `@Autowired` → remove `@Autowired` (Spring injects a single constructor automatically) (S6818)
* `@Controller` where **every** declared method has `@ResponseBody` → replace `@Controller` with `@RestController` and remove `@ResponseBody` from each method — skip if even one declared method lacks `@ResponseBody` (S6833)
* Path variable in the mapping without `@PathVariable`
  `@GetMapping("/x/{id}") Order get(Long id)` → `Order get(@PathVariable Long id)` — verify the parameter name matches the template (S6856)

---

## TEST QUALITY

*(S5779, S5790, S5810, S5833, S5841, S5863, S6068)*

* Assertion inside a `try`/`catch(Error)` → move it after the try-catch block (S5779)
* JUnit 5 inner test class missing `@Nested` → add `@Nested` (S5790)
* JUnit 5 test class/method not visible → make the class public and the method public or package-private with `@Test` (S5810)
* `.as()` placed after the assertion → move it before
  `assertThat(x).isEqualTo(y).as("d")` → `assertThat(x).as("d").isEqualTo(y)` (S5833)
* `allMatch`/`doesNotContain` without an emptiness check → add `assertThat(list).isNotEmpty()` first (S5841)
* `assertThat(x).isEqualTo(x)` (same object) → remove it (always passes) (S5863)
* `Mockito.when(...)` → static-import `when(...)` for readability (S6068)

---

## SECURITY (MECHANICAL)

*(S2151, S5445)*

* Remove the `runFinalizersOnExit()` call entirely (S2151)
* `File.createTempFile(...)` → `Files.createTempFile(...)` — adjust the call site if it expects a `File` rather than a `Path` (S5445)

---

## STRUCTURE

*(S2127, S2167, S2209, S2864, S3038, S4087, S4351, S4517, S4925)*

* `compareTo()` returns `Integer.MIN_VALUE` → return `-1` (negated `MIN_VALUE` is still `MIN_VALUE`, breaking the contract) (S2167)
* `compareTo()` overloaded with a non-`Object` parameter → remove the overload (S4351)
* `Double.longBitsToDouble(intVal)` → `Double.longBitsToDouble((long) intVal)` (S2127)
* Interface method already declared in a parent interface → remove the redundant declaration (S3038)
* Explicit `resource.close()` inside try-with-resources → remove it (closed automatically) (S4087)
* `return buf[pos]` in `InputStream.read()` → `return buf[pos] & 0xFF` (signed-byte fix) (S4517)
* `Class.forName("com.mysql.jdbc.Driver")` → remove entirely (JDBC 4.0+ auto-loads drivers) (S4925)
* Static member accessed via an instance → access via the class: `instance.staticField` → `ClassName.staticField` (S2209)
* `map.keySet()` when the value is also needed → use `entrySet()`
  `for (Map.Entry<K,V> e : map.entrySet()) { e.getKey(); e.getValue(); }` (S2864)
