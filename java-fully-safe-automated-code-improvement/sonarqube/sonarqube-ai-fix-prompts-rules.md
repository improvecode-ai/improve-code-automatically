# RULES REFERENCE

*76 safe, mechanical auto-fix rules. Every rule is applied automatically — no human intervention — and never changes public API, business logic, or compilation. Rules that could only add a `// TODO` flag, or whose fix could change runtime behavior or require guessing intent, were moved to `sonarqube-excluded-rules.md`.*

---

## NAMING

- Local/param camelCase: `String UserName = ...` → `userName` (S117)
- Type param single uppercase or ends with T: `<type>` → `<T>` · `<orderType>` → `<OrderT>` (S119)

---

## DEAD CODE

- Remove unused imports (S1128)
- Remove unused parameters — ONLY in private methods (S1172)
- Remove unused local variables (S1481)

---

## NULL AND BOOLEAN

- Remove redundant booleans: `if (x == true)` → `if (x)` · `if (x == false)` → `if (!x)` · `return x == true` → `return x` (S1125)
- Remove else after jump: `if (x) { return a; } else { b(); }` → `if (x) { return a; } b();` (S1126)
- isEmpty() over size(): `list.size() == 0` → `list.isEmpty()` · `list.size() > 0` → `!list.isEmpty()` (S1155)

---

## CODE STYLE

- Remove redundant parens: `return (x + y)` → `return x + y` — keep if clarifying precedence: `(a + b) * c` (S1110)
- Extract assignment from condition: `if ((x = compute()) != null)` → `x = compute(); if (x != null)` (S1121)
- Canonical modifier order public/protected/private → abstract → static → final: `final static public int X` → `public static final int X` (S1124)
- 3+ duplicate string literals → `private static final String CONSTANT_NAME = "value"` (SCREAMING_SNAKE_CASE) (S1192)
- Array type on type not variable: `int a[]` → `int[] a` · `String m()[]` → `String[] m()` (S1195, S1197)
- Remove non-case labels from switch (S1219)
- for→while when loop variable unused in update: `for (; cond;)` → `while (cond)` (S1264)
- public static field must be final — skip if assigned outside declaration (S1444)
- Deprecated collection constants: `Collections.EMPTY_LIST` → `Collections.emptyList()` · `EMPTY_MAP` → `emptyMap()` · `EMPTY_SET` → `emptySet()` (S1596)
- Merge identical catch bodies: `catch(A e){ log(e); } catch(B e){ log(e); }` → `catch(A|B e){ log(e); }` — skip if bodies differ even slightly (S2147)
- Dissimilar ternary types → explicit cast: `cond ? intVal : longVal` → `cond ? (long) intVal : longVal` (S2154)
- Static via derived type → declaring class: `Child.PARENT_CONSTANT` → `Parent.PARENT_CONSTANT` (S3252)
- Double brace init → explicit add(): `new ArrayList<>(){{ add("a"); }}` → `List<String> list = new ArrayList<>(); list.add("a");` (S3599)
- Single-line if → add braces: `if (x) doIt();` → `if (x) { doIt(); }` (S3973)
- Remove redundant field assignments — skip if class `@Entity`/`@MappedSuperclass`/`@Embeddable` or field `@Column`/`@Id`/`@Transient` (S4165)
- `Integer.toHexString(n)` → `String.format("%x", n)` (S4425)
- Remove `@Nonnull`/`@NonNull` from equals() param: `equals(@Nonnull Object o)` → `equals(Object o)` (S4454)
- String charset → StandardCharsets: `"UTF-8"` → `StandardCharsets.UTF_8` · `"ISO-8859-1"` → `StandardCharsets.ISO_8859_1` (S4719)
- `str.length() == 0` → `str.isEmpty()` · `str.length() > 0` → `!str.isEmpty()` (S7158)

---

## STRING

- `str.toString()` on String → `str` (S1858)
- compareTo vs literal: `a.compareTo(b) == -1` → `a.compareTo(b) < 0` (S2200)
- Log string concat → parameterized: `log.debug("v: " + x)` → `log.debug("v: {}", x)` (S2629)

---

## LAMBDA AND FUNCTIONAL

- Assign-then-return → direct return: `T r = compute(); return r;` → `return compute();` — skip if variable used in finally or try-with-resources (S1488)
- Lambda block single return → expression: `x -> { return x.getName(); }` → `x -> x.getName()` (S1602)
- Remove parens around single lambda param: `(x) -> x.getName()` → `x -> x.getName()` (S1611)
- Thread wrapping Thread → lambda: `new Thread(myThread)` where myThread is Thread → `new Thread(() -> myThread.run())` (S2438)
- Loop copy → built-in: `for (X x : src) dst.add(x)` → `dst.addAll(src)` · `for (int i=0; i<n; i++) dst[i]=src[i]` → `System.arraycopy(src, 0, dst, 0, n)` (S3012)
- Primitive array simple aggregation → stream: `for (int x : arr) { sum += x; }` → `Arrays.stream(arr).sum()` — only sum/count/average; never apply to loops with complex logic (S3631)
- ThreadLocal anonymous class → `ThreadLocal.withInitial(ArrayList::new)` (S4065)

---

## EXCEPTION HANDLING

- Empty catch → add: `log.warn("Ignored {}: {}", e.getClass().getSimpleName(), e.getMessage(), e)` — if no logger exists, add `private static final Logger log = LoggerFactory.getLogger(ClassName.class)` first (S108)
- Remove `runFinalizersOnExit()` call entirely (S2151)

---

## COLLECTIONS AND LOOPS

- `list.size() == 0` → `list.isEmpty()` · `str.length() == 0` → `str.isEmpty()` (S1155)
- Collection variable → interface type: `ArrayList<X> list` → `List<X> list` · `HashMap<K,V> map` → `Map<K,V> map` (S1319)
- Loop array/list copy → use built-in (see LAMBDA AND FUNCTIONAL S3012) (S3012)
- Array created for varargs: `method(new String[]{"a", "b"})` → `method("a", "b")` (S3878)
- Raw Map iteration → add generic type parameter: `Map` → `Map<String, X>` (S4838)

---

## CONCURRENCY

- Serializable non-static inner class → add `static` keyword (S2066)
- enum public mutable field → `private final`: `public Status status = ACTIVE` → `private final Status status` (S3066)

---

## SERIALIZATION

- Externalizable class missing no-args constructor → add `public ClassName() {}` (S2060)
- Serialization method signatures must be exactly:
  `private void writeObject(ObjectOutputStream oos) throws IOException`
  `private void readObject(ObjectInputStream ois) throws IOException, ClassNotFoundException` (S2061)
- `private Object readResolve()` → `protected Object readResolve()` (S2062)
- Cloneable missing clone() → add: `@Override public Object clone() { try { return super.clone(); } catch (CloneNotSupportedException e) { throw new AssertionError(); } }` (S2157)
- Remove `synchronized` keyword from readObject() (S2675)

---

## ANNOTATIONS AND BOILERPLATE

- Add missing @Override on methods overriding or implementing (S1161)
- `public void finalize()` → `protected void finalize()` (S1174)
- Unwrap @Repeatable container: `@Xs({@X("a"), @X("b")})` → `@X("a") @X("b")` — only when annotation is declared @Repeatable (S1710)
- Child method matches parent signature but missing @Override → add @Override (S2177)
- Remove `@Nonnull`/`@NonNull` from equals() parameter (S4454)
- `@CheckForNull`/`@Nullable`/`@NotNull` on primitive type → remove annotation (S4682)

---

## SPRING

- @RequestMapping method is private → change to public or package-private (S3751)
- Single constructor annotated @Autowired → remove @Autowired (Spring injects single constructor automatically) (S6818)
- @Controller where every declared method has @ResponseBody → replace @Controller with @RestController and remove @ResponseBody from all methods — skip if even one declared method lacks @ResponseBody (S6833)
- Path variable in mapping without @PathVariable: `@GetMapping("/x/{id}") Order get(Long id)` → `Order get(@PathVariable Long id)` — verify param name matches template (S6856)

---

## TEST QUALITY

- Assertion inside try-catch(Error) → extract assertion to after the try-catch block (S5779)
- JUnit5 inner test class missing @Nested → add @Nested (S5790)
- JUnit5 test class/method not visible → ensure class public + method public or package-private with @Test (S5810)
- `.as()` after assertion → move before: `assertThat(x).isEqualTo(y).as("d")` → `assertThat(x).as("d").isEqualTo(y)` (S5833)
- allMatch/doesNotContain without empty check → add `assertThat(list).isNotEmpty()` before (S5841)
- `assertThat(x).isEqualTo(x)` same object → remove (always passes) (S5863)
- `Mockito.when(...)` → static import `when(...)` (S6068)

---

## SECURITY (MECHANICAL)

- Remove `runFinalizersOnExit()` call (S2151)
- `File.createTempFile(...)` → `Files.createTempFile(...)` — adjust call site if it expects a `File` (S5445)

---

## STRUCTURE

- compareTo() returns Integer.MIN_VALUE → return -1 (MIN_VALUE negated is still MIN_VALUE, breaks contract) (S2167)
- compareTo() overloaded with non-Object param → remove the overload (S4351)
- `Double.longBitsToDouble(intVal)` → `Double.longBitsToDouble((long) intVal)` (S2127)
- Interface method already declared in parent interface → remove redundant declaration (S3038)
- Explicit resource.close() inside try-with-resources → remove (closed automatically) (S4087)
- `return buf[pos]` in InputStream.read() → `return buf[pos] & 0xFF` (signed byte fix) (S4517)
- `Class.forName("com.mysql.jdbc.Driver")` → remove entirely (JDBC 4.0+ auto-loads drivers) (S4925)
- Static member via instance → via class: `instance.staticField` → `ClassName.staticField` (S2209)
- `map.keySet()` when value also needed → use entrySet(): `for (Map.Entry<K,V> e : map.entrySet()) { e.getKey(); e.getValue(); }` (S2864)
