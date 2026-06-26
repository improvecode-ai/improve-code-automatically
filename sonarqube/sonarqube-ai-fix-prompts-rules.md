## RULES REFERENCE

### NAMING

\[A] Local/param camelCase: `String UserName = ...` → `userName` (S117)
\[A] Type param single uppercase or ends with T: `<type>` → `<T>` · `<orderType>` → `<OrderT>` (S119)

\---

### DEAD CODE

\[A] Remove unused private fields — skip if @Autowired/@Inject/@Value/@Column (S1068)
\[A] Remove unused imports (S1128)
\[A] Remove unused private methods — skip if @Bean/@EventListener/@Scheduled/@PostConstruct (S1144)
\[A] Remove unused parameters — ONLY in private methods (S1172)
\[A] Remove unused local variables (S1481)

\---

### NULL AND BOOLEAN

\[A] Remove redundant booleans: `if (x == true)` → `if (x)` · `if (x == false)` → `if (!x)` · `return x == true` → `return x` (S1125)
\[A] Remove else after jump: `if (x) { return a; } else { b(); }` → `if (x) { return a; } b();` (S1126)
\[A] isEmpty() over size(): `list.size() == 0` → `list.isEmpty()` · `list.size() > 0` → `!list.isEmpty()` (S1155)
\[F] Always-true/false condition → `// TODO: S2583 verify condition is intentional` — do NOT remove code (S2583)
\[F] Gratuitous boolean → `// TODO: S2589 verify this condition` — do NOT remove code (S2589)
\---

### CODE STYLE

\[A] Remove redundant parens: `return (x + y)` → `return x + y` — keep if clarifying precedence: `(a + b) \\\* c` (S1110)
\[A] Extract assignment from condition: `if ((x = compute()) != null)` → `x = compute(); if (x != null)` (S1121)
\[A] Canonical modifier order public/protected/private → abstract → static → final: `final static public int X` → `public static final int X` (S1124)
\[A] String literal left of equals: `var.equals("LIT")` → `"LIT".equals(var)` — skip if @NotNull (S1132)
\[A] 3+ duplicate string literals → `private static final String CONSTANT\\\_NAME = "value"` (SCREAMING\_SNAKE\_CASE) (S1192)
\[A] Array type on type not variable: `int a\\\[]` → `int\\\[] a` · `String m()\\\[]` → `String\\\[] m()` (S1195, S1197)
\[A] Remove non-case labels from switch (S1219)
\[A] for→while when loop variable unused in update: `for (; cond;)` → `while (cond)` (S1264)
\[A] public static field must be final — skip if assigned outside declaration (S1444)
\[A] Deprecated collection constants: `Collections.EMPTY\\\_LIST` → `Collections.emptyList()` · `EMPTY\\\_MAP` → `emptyMap()` · `EMPTY\\\_SET` → `emptySet()` (S1596)
\[A] Single-line if → add braces: `if (x) doIt();` → `if (x) { doIt(); }` (S3973)
\[A] Remove redundant field assignments — skip if class @Entity/@MappedSuperclass/@Embeddable or field @Column/@Id/@Transient (S4165)
\[A] `Integer.toHexString(n)` → `String.format("%x", n)` (S4425)
\[A] Remove @Nonnull/@NonNull from equals() param: `equals(@Nonnull Object o)` → `equals(Object o)` (S4454)
\[A] String charset → StandardCharsets: `"UTF-8"` → `StandardCharsets.UTF\\\_8` · `"ISO-8859-1"` → `StandardCharsets.ISO\\\_8859\\\_1` (S4719)
\[A] `str.length() == 0` → `str.isEmpty()` · `str.length() > 0` → `!str.isEmpty()` (S7158)
\[F] Identical expressions both sides: `a == a` · `a \\\&\\\& a` → `// TODO: S1764 identical expressions — verify intent` (S1764)
\[F] Identical catch bodies → merge: `catch(A e){} catch(B e){}` → `catch(A|B e){}` — skip if bodies differ even slightly (S2147)
\[F] Dissimilar ternary types → explicit cast: `cond ? intVal : longVal` → `cond ? (long) intVal : longVal` (S2154)
\[F] Useless shift: `x << 0` → `x`; `x << 32` on int → `// TODO: S2183 shift by 32 always 0 for int` (S2183)
\[F] Static via derived type → declaring class: `Child.PARENT\\\_CONSTANT` → `Parent.PARENT\\\_CONSTANT` (S3252)
\[F] Double brace init → explicit add(): `new ArrayList<>(){{ add("a"); }}` → explicit `list.add("a")` calls (S3599)

\---

### STRING

\[A] Remove String.valueOf() in concat: `"x" + String.valueOf(n)` → `"x" + n` (S1153)
\[A] `str.toString()` on String → `str` (S1858)
\[F] `new URL(s).equals(o)` → `// TODO: S2112 URL.equals broken — replace with URI` (S2112)
\[A] compareTo vs literal: `a.compareTo(b) == -1` → `a.compareTo(b) < 0` (S2200)
\[A] Log string concat → parameterized: `log.debug("v: " + x)` → `log.debug("v: {}", x)` (S2629)
\[F] Suspicious regex → `// TODO: S2639 verify regex handles edge cases` (S2639)
\[F] String index may be OOB → `// TODO: S3039 verify index within string bounds` (S3039)
\[A] replaceAll with no regex metacharacters → replace: `str.replaceAll("x", "y")` → `str.replace("x", "y")` — metacharacters are: `. \\\* + ? ^ $ { } \\\[ ] | ( ) \\\\` (S5361)

\---

### LAMBDA AND FUNCTIONAL

\[A] Assign-then-return → direct return: `T r = compute(); return r;` → `return compute();` — skip if variable used in finally or try-with-resources (S1488)
\[A] Lambda block single return → expression: `x -> { return x.getName(); }` → `x -> x.getName()` (S1602)
\[A] Remove parens around single lambda param: `(x) -> x.getName()` → `x -> x.getName()` (S1611)
\[A] Thread wrapping Thread → lambda: `new Thread(myThread)` where myThread is Thread → `new Thread(() -> myThread.run())` (S2438)
\[A] Loop copy → built-in: `for (X x : src) dst.add(x)` → `dst.addAll(src)` · `for (int i=0; i<n; i++) dst\\\[i]=src\\\[i]` → `System.arraycopy(src, 0, dst, 0, n)` (S3012)
\[A] Primitive array simple aggregation → stream: `for (int x : arr) { sum += x; }` → `Arrays.stream(arr).sum()` — only sum/count/average; never apply to loops with complex logic (S3631)
\[F] Stream.peek() modifies elements → `// TODO: S3864 peek must not modify — use map() or forEach()` (S3864)
\[F] Intermediate stream result unused → `// TODO: S3958 add terminal operation (.collect/.forEach/.count)` (S3958)
\[F] Stream consumed twice → `// TODO: S3959 stream already consumed — create a new stream` (S3959)
\[F] Redundant stream ops: `.filter(x -> true)` · `.map(x -> x)` · `.sorted().sorted()` → `// TODO: S4034 simplify stream chain` (S4034)
\[F] ThreadLocal anonymous class → `ThreadLocal.withInitial(ArrayList::new)` (S4065)
\[F] iterator() returns `this` → implement proper Iterator with index field, hasNext(), next() throwing NoSuchElementException when exhausted (S4348)
\[F] Java 16+: `.collect(Collectors.toUnmodifiableList())` → `.toList()` (S6204)
\[F] Enumeration → Iterator — only private/internal; skip if public API (S1150)

\---

### EXCEPTION HANDLING

\[A] Empty catch → add: `log.warn("Ignored {}: {}", e.getClass().getSimpleName(), e.getMessage(), e)` — if no logger exists, add `private static final Logger log = LoggerFactory.getLogger(ClassName.class)` first (S108)
\[F] return/throw/break in finally → `// TODO: S1143 jump in finally masks original exception — review` (S1143)
\[F] Swallowed exception → add `log.warn("Unexpected exception", e)` before existing catch body — always add even if body is non-empty (S1166)
\[F] catch(Throwable) or catch(Error) → `// TODO: S1181 too broad — narrow to specific exception type` (S1181)
\[F] Exception from servlet doGet/doPost → wrap body: `try { ... } catch (Exception e) { log.error("...", e); res.sendError(HttpServletResponse.SC\\\_INTERNAL\\\_SERVER\\\_ERROR); }` (S1989)
\[F] InterruptedException caught → add `Thread.currentThread().interrupt()` inside catch body (S2142)
\[A] Remove `runFinalizersOnExit()` call entirely (S2151)
\[F] catch(IllegalMonitorStateException) → remove catch block if no other checked exceptions in try body; else → `// TODO: S2235 remove only if no other checked exceptions thrown` (S2235)
\[F] Iterator.next() missing exhaustion check → add `if (!hasNext()) throw new NoSuchElementException();` at start of next() (S2272)
\[F] Catch block only rethrows unchecked → remove try/catch; checked → `// TODO: S2737 verify callers handle before removing` (S2737)
\[F] assert with side effects → `// TODO: S3346 move side effect out of assert — asserts may be disabled at runtime` (S3346)

\---

### COLLECTIONS AND LOOPS

\[A] `list.size() == 0` → `list.isEmpty()` · `str.length() == 0` → `str.isEmpty()` (S1155)
\[A] Collection variable → interface type: `ArrayList<X> list` → `List<X> list` · `HashMap<K,V> map` → `Map<K,V> map` (S1319)
\[F] for loop stop condition never changes → `// TODO: S127 stop condition is invariant — verify termination` (S127)
\[F] for loop increment does not modify counter → `// TODO: S1994 increment does not modify loop counter` (S1994)
\[F] Incompatible collection method call (wrong type) → `// TODO: S2175 incompatible types — verify intent` (S2175)
\[F] Infinite loop no exit → `// TODO: S2189 verify loop has reachable exit condition` (S2189)
\[F] Loop counter going wrong direction → `// TODO: S2251 verify loop direction — do not auto-fix` (S2251)
\[F] Loop condition always false → `// TODO: S2252 loop never executes` (S2252)
\[F] Loop array/list copy → see LAMBDA S3012
\[F] `list.toArray()` untyped: `List<String>` → `list.toArray(new String\\\[0])`; raw type → `// TODO: S3020 unknown generic type` (S3020)
\[F] Array created for varargs: `method(new String\\\[]{"a", "b"})` → `method("a", "b")` (S3878)
\[F] All branches identical → `// TODO: S3923 all branches identical — verify intent` — do NOT remove code (S3923)
\[F] `list.size() >= 0` always true → `// TODO: S3981 condition always true` (S3981)
\[F] Raw Map iteration → add generic type parameter: `Map` → `Map<String, X>` (S4838)
\[F] List.remove() in ascending for loop → `// TODO: S5413 use Iterator.remove() or iterate in reverse` (S5413)
\[F] Collection modified during iteration → `// TODO: S6417 causes ConcurrentModificationException` (S6417)
\[F] Array index may be OOB → `// TODO: S6466 verify array bounds before access` (S6466)

\---

### CONCURRENCY

\[A] Serializable non-static inner class → add `static` keyword (S2066)
\[A] enum public mutable field → `private final`: `public Status status = ACTIVE` → `private final Status status` (S3066)
\[F] Double-checked locking without volatile → `// TODO: S2168 double-checked locking requires volatile field` (S2168)
\[F] wait()/notify()/notifyAll() outside synchronized → wrap: `synchronized(obj) { obj.wait(); }` (S2273)
\[F] wait()/await() in if not while → `// TODO: S2274 use while loop not if` (S2274)
\[F] Thread.sleep() inside synchronized block → `// TODO: S2276 replace sleep with wait()` (S2276)
\[F] Synchronized on non-private-final field → `// TODO: S2445 synchronize on a private final lock object` (S2445)
\[F] `notify()` → `notifyAll()` to prevent thread starvation (S2446)
\[F] `new ThreadGroup(...)` → `// TODO: S3014 replace with Executors — choose thread count manually` (S3014)
\[F] `synchronized(this.getClass())` → `synchronized(MyClass.class)` (S3067)
\[F] `volatileField++` → `// TODO: S3078 use AtomicInteger/AtomicLong for compound ops` (S3078)
\[F] ThreadLocal not cleaned → wrap in try/finally: `try { tl.set(v); /\\\* work \\\*/ } finally { tl.remove(); }` (S5164)
\[F] setDaemon()/setPriority()/getThreadGroup() on virtual thread → `// TODO: S6901 no effect on virtual threads` (S6901)

\---

### SERIALIZATION

\[A] Externalizable class missing no-args constructor → add `public ClassName() {}` (S2060)
\[A] Serialization method signatures must be exactly:
`private void writeObject(ObjectOutputStream oos) throws IOException`
`private void readObject(ObjectInputStream ois) throws IOException, ClassNotFoundException` (S2061)
\[A] `private Object readResolve()` → `protected Object readResolve()` (S2062)
\[A] Cloneable missing clone() → add: `@Override public Object clone() { try { return super.clone(); } catch (CloneNotSupportedException e) { throw new AssertionError(); } }` (S2157)
\[A] Remove `synchronized` keyword from readObject() (S2675)
\[F] clone() overridden → `// TODO: S2975 clone() broken by design — use copy constructor` (S2975)
\[F] Record with array fields → override equals() using Arrays.equals() for array fields + Objects.equals() for others; override hashCode() using Arrays.hashCode() for array fields (Java 16+: `instanceof Point p` pattern; Java < 16: cast manually) (S6218)
\---

### ANNOTATIONS AND BOILERPLATE

\[A] Add missing @Override on methods overriding or implementing (S1161)
\[A] `public void finalize()` → `protected void finalize()` (S1174)
\[A] equals() overridden without hashCode() → add: `@Override public int hashCode() { return Objects.hash(sameFieldsUsedInEquals); }` (S1206)
\[F] equals() overridden without Comparable → `// TODO: S1210 implement compareTo() consistent with equals()` (S1210)
\[A] Unwrap @Repeatable container: `@Xs({@X("a"), @X("b")})` → `@X("a") @X("b")` — only when annotation is declared @Repeatable (S1710)
\[F] @Deprecated API used → `// TODO: S1874 deprecated — replace with current alternative` (S1874)
\[A] Child method matches parent signature but missing @Override → add @Override (S2177)
\[F] `assertThat(x)` with no chained assertion → `// TODO: S2970 incomplete assertion — add verification` (S2970)
\[F] `assert param != null` on public method param → `if (param == null) throw new IllegalArgumentException("param must not be null")` (S4274)
\[A] Remove @Nonnull/@NonNull from equals() parameter (S4454)
\[A] @CheckForNull/@Nullable/@NotNull on primitive type → remove annotation (S4682)
\[F] @Deprecated-for-removal API used → `// TODO: S5738 marked for removal — replace before next major version` (S5738)
\[F] @VisibleForTesting member used in production → `// TODO: S5803 test-only — do not use in production` (S5803)
\[F] assert statement in production code → `// TODO: S5960 move assertion to test class` (S5960)

\---

### SPRING

\[A] @RequestMapping method is private → change to public or package-private (S3751)
\[A] Single constructor annotated @Autowired → remove @Autowired (Spring injects single constructor automatically) (S6818)
\[A] @Qualifier on @Bean method → remove (@Bean method name is already the qualifier) (S6831)
\[A] @Controller where every declared method has @ResponseBody → replace @Controller with @RestController and remove @ResponseBody from all methods — skip if even one declared method lacks @ResponseBody (S6833)
\[A] Path variable in mapping without @PathVariable: `@GetMapping("/x/{id}") Order get(Long id)` → `Order get(@PathVariable Long id)` — verify param name matches template (S6856)
\[F] @Bean method called directly in non-proxy @Configuration → `// TODO: S6838 inject as constructor/method parameter` (S6838)

\---

### TEST QUALITY

\[F] Thread.sleep() in test → `// TODO: S2925 use Awaitility.await() or mock time source` (S2925)
\[F] Wrong assertion order (expected, actual swapped): `assertEquals(actual, expected)` → `assertEquals(expected, actual)` (S3415)
\[F] Assertion inside try-catch(Error) → extract assertion to after the try-catch block (S5779)
\[F] JUnit5 inner test class missing @Nested → add @Nested (S5790)
\[F] JUnit5 test class/method not visible → ensure class public + method public or package-private with @Test (S5810)
\[F] SoftAssertions used outside assertSoftly → `SoftAssertions.assertSoftly(s -> { s.assertThat(x).isEqualTo(1); });` (S5831)
\[F] `.as()` after assertion → move before: `assertThat(x).isEqualTo(y).as("d")` → `assertThat(x).as("d").isEqualTo(y)` (S5833)
\[F] Chained: `assertThat(list.size()).isEqualTo(3)` → `assertThat(list).hasSize(3)` · `assertThat(str.contains("x")).isTrue()` → `assertThat(str).contains("x")` (S5838)
\[F] allMatch/doesNotContain without empty check → add `assertThat(list).isNotEmpty()` before (S5841)
\[F] Assertion comparing incompatible types → `// TODO: S5845 types incompatible — assertion always fails` (S5845)
\[F] `assertThat(x).isEqualTo(x)` same object → remove (always passes) (S5863)
\[F] CASE\_INSENSITIVE without UNICODE\_CASE: `Pattern.compile("x", CASE\\\_INSENSITIVE)` → `Pattern.compile("x", CASE\\\_INSENSITIVE | UNICODE\\\_CASE)` (S5866)
\[F] assertThatThrownBy with no chained assertion → add `.isInstanceOf(Exception.class)` + `// TODO: S5958 replace with actual expected exception type` (S5958)
\[F] `Mockito.when(...)` → static import `when(...)` (S6068)
\[F] Consumer argument contains no assertThat → `// TODO: S6103 add assertion inside consumer` (S6103)

\---

### SECURITY

\[A] Remove `runFinalizersOnExit()` call (S2151)
\[A] `request.getRequestedSessionId()` → `request.getSession().getId()` (S2254)
\[A] Remove trust-all TrustManager (accepts all certs) and HostnameVerifier always returning true (S4830)
\[A] `File.createTempFile(...)` → `Files.createTempFile(...)` (S5445)
\[A] Remove `HttpsURLConnection.setDefaultHostnameVerifier(...)` that bypasses hostname verification (S5527)
\[F] Weak cipher DES/RC2 → `// TODO: S5542 weak cipher — migrate to AES/GCM/NoPadding (data migration required)` — do NOT auto-replace (S5542)
\[F] ECB cipher mode → `// TODO: S5547 ECB insecure — migrate to AES/GCM/NoPadding (IV + data migration required)` — do NOT auto-replace (S5547)
\[A] XML parser missing XXE protection → add `factory.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true)` (S2755)
\[A] XML parser missing secure processing → add `factory.setFeature(XMLConstants.FEATURE\\\_SECURE\\\_PROCESSING, true)` (S6373)
\[A] XML parser missing DoS limits → add `factory.setProperty(XMLConstants.ACCESS\\\_EXTERNAL\\\_DTD, "")` and `factory.setProperty(XMLConstants.ACCESS\\\_EXTERNAL\\\_SCHEMA, "")` (S6376)

\---

### STRUCTURE

\[A] Exception created as statement not thrown → add `throw`: `new IllegalArgumentException("msg")` → `throw new IllegalArgumentException("msg")` (S3984)
\[A] compareTo() returns Integer.MIN\_VALUE → return -1 (MIN\_VALUE negated is still MIN\_VALUE, breaks contract) (S2167)
\[A] compareTo() overloaded with non-Object param → remove the overload (S4351)
\[A] `Double.longBitsToDouble(intVal)` → `Double.longBitsToDouble((long) intVal)` (S2127)
\[A] toString()/clone() returns null → toString(): `return ""` · clone(): `return super.clone()` wrapped in try-catch AssertionError (S2225)
\[F] `Math.abs(MIN\\\_VALUE)` → `// TODO: S2676 Math.abs(MIN\\\_VALUE) returns MIN\\\_VALUE — add bounds check` (S2676)
\[A] Math.clamp() args clearly inverted: `Math.clamp(val, max, min)` → `Math.clamp(val, min, max)` (S6913)
\[A] `stream.read()` result ignored → assign to variable and check: `int n = stream.read();` (S2677)
\[A] `obj.getClass().getName().equals("com.Foo")` → `obj instanceof com.Foo` or `obj.getClass() == com.Foo.class` (S1872)
\[F] String operation index may be OOB → `// TODO: S3039 verify index within string bounds` (S3039)
\[A] Interface method already declared in parent interface → remove redundant declaration (S3038)
\[A] Explicit resource.close() inside try-with-resources → remove (closed automatically) (S4087)
\[A] `return buf\\\[pos]` in InputStream.read() → `return buf\\\[pos] \\\& 0xFF` (signed byte fix) (S4517)
\[A] `Class.forName("com.mysql.jdbc.Driver")` → remove entirely (JDBC 4.0+ auto-loads drivers) (S4925)
\[A] Static member via instance → via class: `instance.staticField` → `ClassName.staticField` (S2209)
\[F] private method used only by inner class → `// TODO: S3398 consider moving to inner class` (S3398)
\[F] `ResultSet.isLast()` unreliable → `// TODO: S2232 not portable — use cursor position tracking` (S2232)
\[F] ObjectOutputStream in append mode → `// TODO: S2689 corrupts stream — open in overwrite mode` (S2689)
\[F] `map.keySet()` when value also needed → use entrySet(): `for (Map.Entry<K,V> e : map.entrySet()) { e.getKey(); e.getValue(); }` (S2864)
\[F] Async method non-void/Future → `// TODO: S6810 async method should return void or Future` (S6810)

