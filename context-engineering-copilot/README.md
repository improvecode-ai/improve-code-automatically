# context-engineering-copilot

Zestaw custom instructions dla GitHub Copilot (i innych asystentów AI), które mają za zadanie
ograniczyć zużycie tokenów i kosztów przy pracy z modelami — poprzez wymuszenie świadomego
wyboru modelu, zwięzłości odpowiedzi i higieny kontekstu.

---

## Co jest w środku

### [copilot-instructions.md](./copilot-instructions.md)

Gotowy plik custom instructions do wklejenia w ustawieniach Copilota (lub innego asystenta).
Zawiera:

- **RULE #0** — blok deklaracji modelu, który asystent musi wypisać przed każdą odpowiedzią
  (typ zadania, model, powód, decyzja, informacja o higienie kontekstu).
- **Model Selection Decision Tree** — drzewo decyzyjne Haiku / Sonnet / Opus w zależności od
  złożoności zadania.
- **Context Engineering Rules** — reguły takie jak Conciseness, Caveman Style (dla prostych
  zadań), Session Hygiene, Think in Code, Targeted References, CLI over MCP, Input Efficiency.
- **Task Classification Guide** — tabela przykładowych zadań z przypisanym modelem.

### [context-engineering-rules-explained.md](./context-engineering-rules-explained.md)

Analiza każdej reguły z `copilot-instructions.md` pod kątem tego, czy model faktycznie jest w
stanie ją zrealizować. Każda reguła oznaczona jest jako:

- ✅ **DZIAŁA** — czysta generacja tekstu/decyzji, w pełni w zasięgu modelu
- ⚠️ **CZĘŚCIOWO** — zależy od trybu (chat vs agent) lub precyzji modelu
- ❌ **WĄTPLIWE** — model nie ma dostępu do potrzebnych danych (np. realny % zużycia kontekstu,
  timestampy) — reguły te zostały świadomie zdegradowane do formy informacyjnej (ℹ️), żeby nie
  udawać pomiaru, którego model nie może wykonać

Dla każdej reguły opisany jest mechanizm działania, szacowany wpływ na tokeny, wpływ na
doświadczenie developera oraz sposób przetestowania jej w praktyce.

### [prompt-quality-evaluator-summary.md](./prompt-quality-evaluator-summary.md)

Osobny system prompt (Prompt Quality Evaluator v2.2) do wklejenia na początku konwersacji lub w
Custom Instructions. Zanim model wykona zadanie, ocenia jakość promptu pod kątem 6 najczęstszych
błędów (brak kontekstu, brak perspektywy, brak przykładów, ryzyko halucynacji, sprzeczne
instrukcje, brak formatu wyjścia) i zwraca ocenę ✅ / ⚠️ / ❌ wraz z sugerowaną poprawioną
wersją promptu, gdy jest to potrzebne.

---

## Jak używać

1. Skopiuj zawartość [copilot-instructions.md](./copilot-instructions.md) do pliku
   `.github/copilot-instructions.md` w swoim repozytorium (lub do Custom Instructions w
   Claude/ChatGPT/Gemini).
2. Opcjonalnie dołóż [prompt-quality-evaluator-summary.md](./prompt-quality-evaluator-summary.md),
   jeśli zależy Ci też na kontroli jakości samych promptów, nie tylko doboru modelu.
3. Przeczytaj [context-engineering-rules-explained.md](./context-engineering-rules-explained.md),
   żeby wiedzieć, na których regułach faktycznie można polegać, a które są jedynie
   best-effort/informacyjne — i odpowiednio kalibrować oczekiwania.

---

*Część [improve-code-automatically](../README.md) — improvecode.ai*
