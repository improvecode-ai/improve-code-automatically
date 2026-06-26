# AI-Safe Refactoring Rules — Master Reference

Kompletna dokumentacja reguł bezpiecznych do automatycznej refaktoryzacji przez AI.
Zawiera informacje potrzebne do aktualizacji reguł i porównania z innymi promptami.

---

## 📊 Podsumowanie statystyk

| | Liczba |
|---|---|
| Reguły w SonarQube AI Fix Prompts | **209** |
| Reguły w Code Quality Refactoring Prompts | **~55** (osobny plik) |
| Twój eksport SonarQube (3 pliki JSON) | **254** (100 BUG + 100 CODE_SMELL + 54 VULN) |
| Reguły z eksportu pokryte w promptach | **153 / 254** |
| Reguły w promptach potwierdzone publicznie | **209 / 209 ✅** |
| Reguły celowo wykluczone (wymagają kontekstu) | **~65** |

---

## 📁 Pliki

| Plik | Zawartość |
|---|---|
| `sonarqube-ai-fix-prompts.md` | Prompty SonarQube — 4 warianty + 209 reguł w RULES REFERENCE |
| `claude-code-refactor-prompts.md` | Prompty do ogólnej refaktoryzacji kodu — 11 kategorii |
| `refactor-map-prompt.md` | Prompt do skanowania pakietu i tworzenia mapy refaktoryzacji |
| `sonar-vs-ai-prompts-comparison.md` | Porównanie pokrycia: nasze prompty vs SonarQube |

---

## 🏗️ Struktura SonarQube AI Fix Prompts

### 4 prompty (jak używać)

| Prompt | Kiedy używać |
|---|---|
| **FIX ALL** | Napraw wszystko w pliku lub pakiecie |
| **CATEGORY PROMPTS** | Napraw jeden typ problemu naraz |
| **PR PROMPT** | Napraw tylko nowy/zmieniony kod w bieżącym branchu — `git diff main...HEAD` |
| **SONAR REPORT PROMPT** | Napraw konkretną listę problemów z eksportu SonarQube |

### Ważne zasady stosowania
- Kolejność kategorii ma znaczenie: **DEAD CODE → NAMING → ... → STRUCTURE**
- Każda kategoria: najpierw **Auto-fix**, potem **Flag-only** (dodaje TODO)
- Po S1604 (anon→lambda) od razu sprawdź S1612 (lambda→method ref)
- Po wszystkich zmianach: ponów DEAD CODE (inne zmiany mogą tworzyć nowe unused imports)
- Przed uruchomieniem: odczytaj `pom.xml` — potrzebna wersja Java i obecność Lombok

### 15 kategorii z liczbą reguł

| Kategoria | Reguł | Typ |
|---|---|---|
| NAMING | 7 | CODE_SMELL |
| DEAD CODE | 5 | CODE_SMELL |
| NULL AND BOOLEAN | 9 | BUG + CODE_SMELL |
| CODE STYLE | 29 | CODE_SMELL |
| STRING | 15 | BUG + CODE_SMELL |
| LAMBDA AND FUNCTIONAL | 16 | CODE_SMELL |
| EXCEPTION HANDLING | 11 | BUG + CODE_SMELL |
| COLLECTIONS AND LOOPS | 20 | BUG + CODE_SMELL |
| CONCURRENCY | 19 | BUG |
| SERIALIZATION | 8 | BUG + CODE_SMELL |
| ANNOTATIONS AND BOILERPLATE | 16 | CODE_SMELL |
| SPRING | 10 | BUG + CODE_SMELL |
| TEST QUALITY | 15 | CODE_SMELL |
| SECURITY (MECHANICAL) | 11 | VULNERABILITY |
| STRUCTURE | 24 | BUG + CODE_SMELL |

---

## 🆚 Porównanie: SonarQube prompts vs Code Quality prompts

### Kategorie wspólne (obie listy pokrywają)
- Naming / Nazewnictwo
- Exception Handling / Wyjątki
- Collections & Loops / Pętle i kolekcje
- Lambda & Functional / Lambda i funkcyjne
- Comments / Komentarze (tylko Code Quality)
- Tests / Testy

### Tylko w SonarQube prompts
- Spring (S6813, S6833, S3751, S6831...)
- Security/Mechanical (S4830, S5445, S2755, S6373...)
- Concurrency (S2273, S2446, S5164, S2119...)
- Serialization (S2060, S2061, S2157...)
- String operations (S2111, S5917, S2695, S2695...)

### Tylko w Code Quality prompts
- Guard clauses / early return
- `@NotNull` / `@Nullable` adnotacje
- `final` na lokalnych zmiennych i parametrach
- `Boolean` → `boolean` (wrapper → primitive)
- Formatowanie — puste linie jako separatory
- Ujednolicenie loggerów do SLF4J
- Generyczne nazwy metod (process, handle, doWork)
- Spójność w obrębie klasy

### Kluczowa różnica filozoficzna
**SonarQube prompts** = naprawia to, co CI pipeline oznaczy jako błąd
**Code Quality prompts** = poprawia to, czego CI pipeline w ogóle nie widzi

---

## 🔄 Jak aktualizować reguły SonarQube

### Kiedy aktualizować
- Po aktualizacji SonarQube do nowej wersji
- Po zmianie Quality Profile w projekcie
- Po dodaniu nowych pluginów (np. sonar-java nowa wersja)

### Proces aktualizacji

**Krok 1 — eksportuj aktualne reguły z instancji:**
```bash
# Pobierz klucz profilu
curl -u [TOKEN]: "https://[SONAR_HOST]/api/qualityprofiles/search?language=java"

# Eksportuj reguły (po 100, zmieniaj p=1,2,3...)
curl -u [TOKEN]: "https://[SONAR_HOST]/api/rules/search\
?languages=java\
&qprofile=[PROFILE_KEY]\
&activation=true\
&types=BUG,CODE_SMELL,VULNERABILITY\
&ps=100&p=1\
&f=key,name,type,severity,tags" > rules-page1.json
```

**Krok 2 — porównaj z naszym plikiem:**
```python
import json, re

# Reguły z nowego eksportu
with open('rules-new.json') as f:
    new_rules = {r['key'].split(':')[-1] for r in json.load(f)['rules']}

# Reguły w naszych promptach
with open('sonarqube-ai-fix-prompts.md') as f:
    content = f.read()
our_rules = set(re.findall(r'S\d{3,4}', content[content.find('RULES REFERENCE'):]))

new_to_add = new_rules - our_rules
removed    = our_rules - new_rules

print(f"Nowe reguły do oceny: {sorted(new_to_add)}")
print(f"Usunięte reguły: {sorted(removed)}")
```

**Krok 3 — oceń nowe reguły wg kryteriów:**

| Kryterium | Pytanie |
|---|---|
| **Mechaniczne** | Czy fix jest zawsze taki sam, niezależnie od kontekstu? |
| **Bezpieczne** | Czy nie zepsuje kompilacji ani runtime? |
| **Zakres** | Czy wystarczy analiza jednego pliku? |

**Krok 4 — dodaj do właściwej kategorii w RULES REFERENCE**
- Auto-fix → przed `**Flag only**` sekcją
- Flag-only → po `**Flag only**` sekcją
- Zaktualizuj listę ID w nagłówku kategorii `*(S..., S...)*`

---

## ❌ Reguły celowo wykluczone (nie dodawać)

### Security injections — wymagają przebudowy logiki
`S3649` SQL, `S2076` OS command, `S5131` XSS, `S2078` LDAP, `S2091` XPath,
`S5135` Deserialization, `S5144` SSRF, `S5147` NoSQL, `S5334` Dynamic code,
`S5496` Template, `S6173` Reflection, `S6398` JSON, `S6399` XML

### Crypto — wymagają wiedzy kryptograficznej
`S2053` Password salt, `S5344` Password hashing, `S3329` CBC IV,
`S5659` JWT, `S6432` Counter mode IV, `S6377` XML signature

### Architektoniczne — wymagają wiedzy domenowej
`S7027` Circular deps in package, `S7091` Circular deps across packages,
`S7134` Architectural constraints, `S4601` HttpSecurity ordering,
`S4602` ComponentScan, `S4684` Persistent entity

### Platformowe / framework-specific
`S5301` ActiveMQ, `S5679` OpenSAML, `S6301` Mobile DB,
`S6384` Android intent, `S3753` SessionStatus Spring,
`S5876` Session creation, `S4433` LDAP auth

### Wymagają analizy przepływu danych
`S2222` Lock release, `S2886` Sync getter/setter pairs,
`S3046` Multiple locks wait, `S3064` Double-checked locking,
`S2134` Thread.run behavior, `S2390` Class init order

---

## ⚠️ Reguły z warunkiem (rozważyć w przyszłości)

| Reguła | Warunek | Rekomendacja |
|---|---|---|
| S2637 | `@NonNull` set to null | Flag only — fix wymaga kontekstu |
| S4275 | Getter/setter wrong field | AI może wywnioskować, ryzyko błędu |
| S4423 | Weak SSL/TLS | Flag only — breaking change |
| S4426 | Weak crypto key size | Flag only — wymaga wyboru rozmiaru |
| S6437 | Hardcoded credentials | AI nie zna nazwy env var |
| S1301 | Switch < 3 cases → if | Structural change, judgment needed |

---

## 🔍 Publiczne źródła reguł SonarQube Java

| Źródło | URL | Uwagi |
|---|---|---|
| SonarQube Docs | `docs.sonarsource.com/sonarqube-server/latest` | Ogólna dokumentacja |
| GitHub sonar-java | `github.com/SonarSource/sonar-java` | Kod źródłowy wszystkich reguł |
| Twoja instancja | `[SONAR_HOST]/api/rules/search` | Najdokładniejsze dla Twojego projektu |
| SonarCloud public API | `sonarcloud.io/api/rules/show?key=java:S{N}` | Publiczne reguły (może wymagać auth) |

### Potwierdzenie: wszystkie nasze reguły są publiczne
- 153 reguły — potwierdzone w Twoim eksporcie SonarQube ✅
- 56 reguł — potwierdzone w oficjalnej dokumentacji SonarSource ✅
- 0 reguł firmowych / customowych ✅

---

## 📋 Pełna lista reguł w promptach (209 reguł)

### NAMING (7)
S100, S101, S115, S116, S117, S119, S120

### DEAD CODE (5)
S1068, S1128, S1144, S1172, S1481

### NULL AND BOOLEAN (9)
S1125, S1126, S1155, S1168, S1940, S2447, S2583, S2589, S2789

### CODE STYLE (29)
S1110, S1121, S1124, S1132, S1192, S1195, S1197, S1219, S1264, S1444,
S1596, S1700, S1764, S2147, S2154, S2183, S2387, S2692, S3252, S3599,
S3973, S4165, S4425, S4454, S4524, S4719, S5411, S6219, S7158

### STRING (15)
S1153, S1157, S1317, S1858, S2111, S2112, S2200, S2629, S2639, S2718,
S3039, S5361, S5850, S5917, S6915

### LAMBDA AND FUNCTIONAL (16)
S1150, S1488, S1602, S1604, S1611, S1612, S2438, S3012, S3631, S3864,
S3958, S3959, S4034, S4065, S4348, S6204

### EXCEPTION HANDLING (11)
S108, S1143, S1166, S1181, S1989, S2142, S2151, S2235, S2272, S2737, S3346

### COLLECTIONS AND LOOPS (20)
S127, S1155, S1319, S1751, S1849, S1994, S2114, S2175, S2189, S2251,
S2252, S3012, S3020, S3878, S3923, S3981, S4838, S5413, S6417, S6466

### CONCURRENCY (19)
S1217, S1844, S2066, S2116, S2119, S2122, S2168, S2204, S2273, S2274,
S2276, S2445, S2446, S3014, S3066, S3067, S3078, S5164, S6901

### SERIALIZATION (8)
S2060, S2061, S2062, S2157, S2675, S2975, S6218, S6219

### ANNOTATIONS AND BOILERPLATE (16)
S1161, S1174, S1201, S1206, S1210, S1710, S1874, S2097, S2177, S2970,
S4274, S4454, S4682, S5738, S5803, S5960

### SPRING (10)
S3751, S6813, S6818, S6829, S6831, S6833, S6830, S6838, S6856, S6862

### TEST QUALITY (15)
S2925, S3415, S5779, S5790, S5810, S5831, S5833, S5838, S5841, S5845,
S5863, S5866, S5958, S6068, S6103

### SECURITY MECHANICAL (11)
S2151, S2254, S2755, S4347, S4830, S5445, S5527, S5542, S5547, S6373, S6376

### STRUCTURE (24)
S1872, S2110, S2127, S2167, S2209, S2225, S2232, S2676, S2677, S2689,
S2695, S2864, S3038, S3398, S3824, S3984, S4042, S4087, S4351, S4517,
S4925, S5413, S6810, S6913

---

*Ostatnia aktualizacja: maj 2026 · improvecode.ai*
