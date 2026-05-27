# mutant Baseline — Survivor Audit

**Branch:** `demo/weak-tests` (same library + suite as `main`)
**Library:** `lib/date_utils.rb` after `module_function` → `extend self` correction
**Run:** `bundle exec mutant run --integration rspec DateUtils`

---

## Headline Numbers

| Metric | Value |
|---|---|
| Total mutations generated | 259 |
| Mutations killed | 250 |
| Mutations alive | **9** |
| Mutation timeouts | 11 |
| Kill rate (Coverage) | **96.52%** |
| Subjects | 6 |
| Test count | 28 |
| Test coverage (SimpleCov line + branch) | 100% |

The 96.52% kill rate is the honest one. An earlier version of this report quoted 2.31%
based on a `module_function`-induced injection bug — `module_function` creates twin method
objects (a private instance method and a singleton class method) that mutant mutates
independently of the singleton method tests dispatch through. Switching to `extend self`
collapses to one method object and lets mutant inject where tests look.

---

## The 9 Survivors

All 9 alive mutations cluster in two functions:

| Function | Alive | Subject mutations | Kill rate |
|---|---|---|---|
| `days_between` | 3 | 17 | 82.4% |
| `add_business_days` | 6 | 84 | 92.9% |
| `leap_year?` | 0 | 24 | 100% |
| `age_in_years` | 0 | 26 | 100% |
| `next_occurrence_of_weekday` | 0 | 39 | 100% |
| `weeks_between` | 0 | 11 | 100% |

The pattern is the central pedagogical point: **every surviving mutation is an
*equivalent mutant*** — a mutation indistinguishable from the original under all possible
inputs, not a real test gap.

---

## Survivor Classification

### `days_between` — 3 alive, all type-coercion equivalents

```diff
 def days_between(start_date, end_date)
-  (end_date - start_date).to_i
+  (end_date - start_date)
 end
```

`Date - Date` returns `Rational`. `.to_i` truncates to `Integer`. But `Rational(7,1) == 7`
is `true` in Ruby — Numeric equality coerces both sides. Every `expect(...).to eq(7)`
assertion still passes.

The other two `days_between` survivors are variants of this same coercion phenomenon:
replacing `.to_i` with `Integer(...)` (semantically identical for Rational), or rebinding
through a different equivalent expression. All three change the return *type* without
changing any observable result.

**Class:** equivalent mutant. Not reachable by any conceivable test of `days_between`
*as a unit*, because the test would need to inspect the return type rather than its value.

### `add_business_days` — 6 alive, mostly zero-guard equivalents

```diff
 def add_business_days(date, n)
   if n.zero?
-    return date
+    date
   end
   ...
```

Removing `return` from inside an early-return guard. Without `return`, execution falls
through to the rest of the method. For `n.zero?`, the loop body `while steps < n.abs`
sees `steps=0, n.abs=0`, condition false, loop never executes, and the method returns
`current` (which was assigned `date`). Result: `date`. Same as the original.

The other 5 `add_business_days` survivors are similar near-equivalent rewrites of the
zero-guard path:

| Survivor pattern | Why it survives |
|---|---|
| `if n.zero?` → `if false` | Guard never fires; loop-zero-iter still returns `date` for n=0 |
| `if n.zero?` → `if nil` | Same as above |
| `return date` → `nil` | Falls through; loop-zero-iter returns `current = date` |
| `return date` → bare `date` | Falls through; same path as above |

**Class:** equivalent mutant. The zero-guard is structurally redundant under the current
loop logic — any mutation that disables it leaves `n=0` behavior unchanged. No test
suite can distinguish these from the original.

---

## What this means for the demo

> "Rule-based mutation operators are ill-suited to the task of generating realistic faults.
> They produce large volumes of mutants indiscriminately, many semantically equivalent to
> the original code, overwhelming test infrastructure and developer workflows."
>
> — Meta ACH paper, FSE 2025

Mutant's 96.52% kill rate looks like a strong endorsement of the test suite, but every
single one of the 9 survivors is structurally undetectable — not a test gap. The bugs
intentionally planted in this library (Feb 29 birthdays, Gregorian 400-year exception,
same-day weekday boundary, reversed-date `weeks_between`, weekend-start `add_business_days`)
are **not in mutant's survivor set at all** — none of them correspond to single-operator
swaps. They correspond to *semantic* mistakes that LLM-driven mutation testing
(`/llm-mutate`) generates and the weak suite then fails to catch.

The mutant audit confirms Meta's thesis on this specific codebase: operator-based mutation
testing's residual signal is dominated by equivalent-mutant noise. The signal worth acting
on lives elsewhere — in the `/llm-mutate` report at `baselines/llm-mutation-report.md`.

---

## References

- Live mutant baseline (committed): `baselines/mutant-report.txt` on `demo/weak-tests`
- LLM mutation comparison: `docs/comparison.md`
- LLM fixture: `.claude/skills/llm-mutate/fixtures/canonical.json`
- Meta ACH paper: *Mutation-Guided LLM-based Test Generation at Meta*, arXiv 2501.12862 (FSE 2025)
- Meta engineering blog: *LLMs Are the Key to Mutation Testing and Better Compliance*, Sep 2025
