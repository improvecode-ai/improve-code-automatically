# Dokumentacja reguł — copilot-instructions.md

Legenda aktywacji:
- ✅ **DZIAŁA** — model może to realnie wykonać (czysta generacja tekstu/decyzji)
- ⚠️ **CZĘŚCIOWO** — zależy od mode (chat vs agent) lub od precyzji modelu
- ❌ **WĄTPLIWE** — model nie ma dostępu do potrzebnych danych (metryki runtime, timestampy)

---

## 1. RULE #0 — Model Declaration Block

**Aktywacja:** ✅ DZIAŁA
Czysto tekstowa instrukcja "wypisz blok przed odpowiedzią" — model generuje tekst, więc to w pełni w jego zasięgu.

**Jak działa / dlaczego:**
Wymusza samoocenę przed wykonaniem zadania: typ zadania, model, powód, decyzja, oraz linia INFO (best-effort przypomnienie context-hygiene lub "-"). To realizacja zasady "Declare" — model musi *powiedzieć na głos* swoją kalibrację, zamiast po cichu działać dalej. Linia INFO jest miejscem, gdzie pojawiają się miękkie przypomnienia z reguł informacyjnych (#6 i #7).

**Wpływ na tokeny:**
Mały narzut bezpośredni (~20–30 tokenów output na request). Potencjalnie duży zysk pośredni — jeśli zapobiegnie użyciu Opus na prosty task, różnica cenowa między tierami jest kilkukrotna do kilkudziesięciokrotnej.

**Wpływ na developera:**
Dodatkowa linijka do przeczytania na początku każdej odpowiedzi. Z czasem buduje świadomość "ile to kosztuje" — ale przy bardzo prostych pytaniach może być odczuwane jako szum.

**Kiedy zadziała / test:**
Wybierz Opus, zadaj proste pytanie ("dodaj getter") → sprawdź czy PROCEED = ⚠️. Wybierz Haiku, zadaj złożone pytanie architektoniczne → sprawdź czy poleci switch na Opus.

---

## 2. Model Selection Decision Tree

**Aktywacja:** ✅ DZIAŁA
To "baza wiedzy" wykorzystywana przy wypełnianiu RULE #0 — nie jest osobną akcją, ale daje konkretne kryteria.

**Jak działa / dlaczego:**
Eliminuje subiektywność klasyfikacji. Bez tego model mógłby różnie oceniać to samo zadanie w różnych momentach.

**Wpływ na tokeny:**
Brak bezpośredniego wpływu — to tabela referencyjna w pliku instrukcji (sam plik jest cache'owany przez prompt caching, więc koszt jego "wczytania" jest amortyzowany).

**Wpływ na developera:**
Edukacyjny — pokazuje *dlaczego* dany model jest rekomendowany, nie tylko "co".

**Kiedy zadziała / test:**
Zadaj 5 różnych zadań z różnych kategorii (CRUD, debug, architektura) → sprawdź czy klasyfikacja jest konsekwentna przy powtórzeniu tego samego promptu.

---

## 3. Conciseness

**Aktywacja:** ✅ DZIAŁA (z furtką)
Czysta instrukcja stylu — model może to realizować. Fraza "unless relevant" daje subiektywną furtkę, więc nie jest 100% deterministyczne.

**Jak działa / dlaczego:**
Output tokens kosztują 3–5x więcej niż input. Usunięcie "fluffu" (notes, tips, podsumowania) to czysta redukcja kosztu bez utraty wartości merytorycznej.

**Wpływ na tokeny:**
**Wysoki** — dokument mówi o 60–80% redukcji output tokens dla typowych zadań.

**Wpływ na developera:**
Odpowiedzi bardziej "to the point". Dobre dla doświadczonych użytkowników; może być frustrujące jeśli ktoś szuka wyjaśnień i musi dopytywać (co generuje dodatkowe rundy).

**Kiedy zadziała / test:**
Poproś "wygeneruj funkcję X" → sprawdź czy odpowiedź to tylko kod, bez "Here's the function that... Let me know if...".

---

## 4. Caveman Style (SIMPLE tasks only)

**Aktywacja:** ✅ DZIAŁA WARUNKOWO
Zależy od poprawnej klasyfikacji w RULE #0. Jeśli #0 źle oceni task jako "simple", caveman włączy się niepotrzebnie (i odwrotnie).

**Jak działa / dlaczego:**
Ekstremalna kompresja gramatyczna — usuwa wszystko co nie jest niezbędną informacją (`keyword: value`, `action -> result`).

**Wpływ na tokeny:**
**Wysoki dla zadań simple** — szacunkowo dodatkowe 30–50% redukcji *poza* bazową conciseness. Całościowy wpływ zależy od tego, jak często w Twojej pracy trafiają się "simple" taski.

**Wpływ na developera:**
Trudniejsze do czytania przy pierwszym kontakcie (brak gramatyki). Dla rutynowych zadań — szybkie skanowanie. Ryzyko: jeśli model błędnie sklasyfikuje niuansowe zadanie jako "simple", utracisz potrzebny kontekst.

**Kiedy zadziała / test:**
Porównaj odpowiedź na "dodaj getter dla pola name" (powinno być caveman) vs "zaprojektuj cache layer" (powinno być normalnym językiem).

---

## 5. Session Hygiene (/compact po ~10 turach)

**Aktywacja:** ⚠️ CZĘŚCIOWO
Model widzi historię konwersacji, więc teoretycznie może "policzyć" tury. Ale jeśli wcześniejsza historia była już skracana/obcinana przez klienta, liczenie będzie niedokładne.

**Jak działa / dlaczego:**
Po przekroczeniu progu, model przypomina o `/compact` — zanim "context debt" zacznie degradować jakość.

**Wpływ na tokeny:**
**Średni pośrednio** — samo przypomnienie nie redukuje tokenów, ale prowadzi do akcji (`/compact`), która może znacząco skrócić historię.

**Wpływ na developera:**
Przy krótkich, ale licznych wymianach (np. szybkie pytania co minutę) przypomnienie może być za częste i irytujące.

**Kiedy zadziała / test:**
Przeprowadź 10+ wymian w jednej sesji → sprawdź czy w 11. odpowiedzi pojawia się przypomnienie o `/compact`.

---

## 6. Context Window Monitor ℹ️ INFORMATIONAL ONLY

**Aktywacja:** ❌ WĄTPLIWE → świadomie zdegradowane do **informacyjnej**
Model **nie ma dostępu do realnej metryki "% zużycia context window"**. Z tego powodu sztywne progi 50%/60% zostały **usunięte** z reguły. Zamiast nich zostaje miękkie przypomnienie oparte na wrażeniu "sesja wydaje się długa" (liczba tur / dużo wklejonej treści), wypisywane w linii INFO bloku RULE #0.

**Jak działa / dlaczego:**
Świadomie NIE udaje pomiaru. Daje tylko miękki sygnał ("ℹ️ Long session — consider /compact"), gdy historia wygląda na rozbudowaną. Cel: nie tworzyć fałszywego poczucia precyzji.

**Wpływ na tokeny:**
Bezpośrednio **znikomy** (sam tekst INFO). Pośrednio zależny od tego, czy przypomnienie skłoni Cię do `/compact`. Traktować jako "nudge", nie mechanizm.

**Wpływ na developera:**
Niski i nieinwazyjny. Brak fałszywych twardych alarmów — ale też brak gwarancji, że ostrzeże w odpowiednim momencie.

**Kiedy zadziała / test:**
Prowadź długą sesję z dużą ilością wklejonej treści → sprawdź czy w linii INFO pojawia się przypomnienie o `/compact`. Pamiętaj: brak przypomnienia ≠ kontekst jest OK (to tylko zgadywanie modelu).

---

## 7. Stale Session Tax ℹ️ INFORMATIONAL ONLY

**Aktywacja:** ❌ WĄTPLIWE → świadomie zdegradowane do **informacyjnej**
Model nie ma dostępu do timestampów między wiadomościami, więc **nie potrafi wykryć przerwy**. Dlatego reguła przestała być warunkowa ("po wykryciu przerwy"). Zamiast tego jest **bezwarunkowym, okazjonalnym przypomnieniem** w linii INFO — pojawiającym się czasem, gdy nie ma innej treści INFO.

**Jak działa / dlaczego:**
Nie próbuje wykrywać przerwy. Po prostu od czasu do czasu przypomina ogólną zasadę: po dłuższych przerwach cache wygasa, więc `/clear` + świeża sesja bywa tańsza niż kontynuacja starej.

**Wpływ na tokeny:**
Bezpośrednio znikomy. Pośrednio potencjalnie wysoki (cache ~90% rabatu) — ale tylko jeśli przypomnienie trafi w moment, gdy faktycznie wróciłeś po przerwie (czego reguła nie wie).

**Wpływ na developera:**
Niski. Czysto edukacyjne przypomnienie. Ryzyko: może pojawić się gdy nie jest potrzebne (bo nie zna kontekstu czasowego).

**Kiedy zadziała / test:**
Nie da się przetestować "wykrycia przerwy", bo reguła tego nie robi. Można jedynie sprawdzić, czy ogólne przypomnienie pojawia się okazjonalnie w linii INFO. Realny pomiar przerwy wymagałby pluginu wstrzykującego timestamp.

---

## 8. Think in Code

**Aktywacja:** ✅ DZIAŁA (w agent mode)
Jeśli Copilot ma dostęp do terminala/plików (agent mode w IntelliJ), może *zdecydować* napisać skrypt filtrujący zamiast przetwarzać surowe dane. W czystym chat mode zależy też od tego, co user wklei.

**Jak działa / dlaczego:**
Zamiast `cat duzy_log.txt` → `grep ERROR log.txt | tail -20` i tylko wynik trafia do kontekstu.

**Wpływ na tokeny:**
**Bardzo wysoki** — do 98% redukcji input tokens przy dużych logach/plikach (wg dokumentu).

**Wpływ na developera:**
Wymaga zmiany przyzwyczajeń: zamiast "wklej cały plik", lepiej "pokaż mi fragment z błędem". Czasem dodatkowa iteracja (najpierw filtr, potem analiza) — ale netto taniej.

**Kiedy zadziała / test:**
Wklej log >50 linii → sprawdź czy Copilot proponuje filtrowanie/skrypt *przed* analizą, czy po prostu przetwarza wszystko surowo.

---

## 9. Targeted References (`@file:funkcja` vs `@file`)

**Aktywacja:** ⚠️ CZĘŚCIOWO
To głównie instrukcja **dla użytkownika** (jak pisać referencje w promptach) — Copilot sam tego nie wymusza na Twoich `@` mentionach. Ale w *swoich* odpowiedziach/sugestiach może wskazywać konkretne funkcje/linie zamiast całych plików.

**Jak działa / dlaczego:**
`@UserService.java:getUserById()` zamiast `@UserService.java` — wczytuje tylko fragment, nie cały plik.

**Wpływ na tokeny:**
**Średni–wysoki**, zależny od rozmiaru pliku (plik 1000 linii vs funkcja 20 linii = radykalna różnica).

**Wpływ na developera:**
Wymaga większej precyzji przy formułowaniu promptów — dodatkowy "mental overhead" na starcie, ale wyrabia dobry zwyczaj.

**Kiedy zadziała / test:**
Jeśli IDE pokazuje licznik tokenów kontekstu — porównaj `@CałyPlik` vs `@Plik:konkretna_funkcja` dla tego samego pytania.

---

## 10. CLI over MCP

**Aktywacja:** ✅ DZIAŁA (w agent mode, jeśli jest wybór)
Jeśli Copilot ma dostęp i do terminala (`gh`, `git`), i do MCP serwerów — ta reguła wpływa na to, **które narzędzie agent wybierze**.

**Jak działa / dlaczego:**
Zamiast wywołać MCP tool zwracający pełny JSON (dziesiątki pól), użyj `gh issue view 123 --json title,body` — selektywne pola.

**Wpływ na tokeny:**
**Średni–wysoki**, zależny od narzędzia — MCP payloady bywają bardzo verbose.

**Wpływ na developera:**
Zwykle niewidoczne — to wybór "pod maską" agenta. Może wystąpić konflikt, jeśli explicite poprosisz o użycie konkretnego MCP, a reguła próbuje przekierować na CLI.

**Kiedy zadziała / test:**
Poproś "sprawdź status PR #X" mając dostępne i `gh` CLI, i GitHub MCP → jeśli IntelliJ pokazuje tool calls, sprawdź które narzędzie zostało wybrane.

---

## 11. Input Efficiency (reguła "umbrella")

**Aktywacja:** ⚠️ CZĘŚCIOWO (w agent mode)
Agent z dostępem do plików może odczytać tylko fragment (np. konkretny zakres linii) zamiast całego pliku. To w dużej mierze podsumowanie reguł #8 i #9.

**Jak działa / dlaczego:**
Generalna zasada: czytaj minimum potrzebne do wykonania zadania.

**Wpływ na tokeny:**
Skumulowany z #8 i #9 — trudny do policzenia osobno, bo to "zasada-rodzic" dla pozostałych.

**Wpływ na developera:**
Czasem Copilot zapyta "która funkcja/plik?" zamiast zgadywać po całym repo — dodatkowa runda pytanie/odpowiedź, ale precyzyjniejszy wynik (mniej poprawek później).

**Kiedy zadziała / test:**
Poproś o zmianę w dużym pliku **bez** wskazania lokalizacji → sprawdź czy Copilot pyta o szczegóły, czy wczytuje cały plik "na pewniaka".

---

## Podsumowanie — realna skuteczność

| Reguła | Aktywacja |
|---|---|
| RULE #0 (deklaracja modelu) | ✅ |
| Decision Tree | ✅ |
| Conciseness | ✅ |
| Caveman Style | ✅ (warunkowo) |
| Session Hygiene | ⚠️ |
| Context Window Monitor | ❌ → ℹ️ informacyjna |
| Stale Session Tax | ❌ → ℹ️ informacyjna |
| Think in Code | ✅ (agent mode) |
| Targeted References | ⚠️ |
| CLI over MCP | ✅ (agent mode) |
| Input Efficiency | ⚠️ |

**Wniosek:** reguły czysto "tekstowe/decyzyjne" (1–4) działają najbardziej pewnie. Reguły wymagające dostępu do metryk runtime (6, 7) są w najlepszym razie symboliczne. Reguły 8–11 zależą od **agent mode** — bez niego (czysty chat) ich skuteczność spada.
