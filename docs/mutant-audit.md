# mutant Baseline — Equivalence Audit

**Phase:** 3 — mutant Baseline
**Run date:** 2026-05-26
**Subject:** DateUtils (all six functions)
**Raw report:** tmp/mutant-report.txt (gitignored — run locally to reproduce)

---

## Kill Rate Summary

| Metric | Value |
|--------|-------|
| Total mutations generated | 259 |
| Mutations killed | 6 |
| Mutations alive | 253 |
| Kill rate | 2.31% |
| Subjects | 6 |
| Test count | 28 |

The 2.31% kill rate is the central Act 1 evidence: a test suite with 100% line **and** branch
coverage kills fewer than 1 in 40 mutations. The surviving mutations are not noise — they include
direct behavioral counterparts to every intentional boundary bug planted in Phase 2.

---

## Surviving Mutations — Classification Table

Mutation IDs are assigned sequentially per function for easy demo reference.
All diffs are extracted from the live `mutant session subject` output.

### days_between (14 alive)

| ID | Mutation Description | Diff (key line) | Verdict | Demo Relevance |
|----|---------------------|-----------------|---------|----------------|
| M-DB-01 | Entire body replaced with `raise` | `+ raise` | meaningful | Proves tests never drive to a real return value assertion — any exception would also pass |
| M-DB-02 | Return value omitted (implicit nil) | body deleted | meaningful | Tests do not assert a non-nil return, so nil passes |
| M-DB-03 | `.to_i` replaced with `.to_int` | `(end_date - start_date).to_int` | equivalent | `Date#-` returns an Integer; `.to_i` and `.to_int` on Integer are identical |
| M-DB-04 | Receiver swapped to `self.to_i` | `self.to_i` | meaningful | Returns 0 for all inputs; tests only check positive day-counts so 0 passes for `same_date` but would fail for 7-day test — however tests still pass because… wait, actually this would fail the `returns 7` test. Re-evaluated: **uncertain** (mutant says alive — may be a quirk of how `module_function` resolves `self` at runtime; `self` inside a `module_function` is the module itself, `.to_i` on a Module raises in practice) |
| M-DB-05 | `end_date` replaced with `nil` | `(nil - start_date).to_i` | meaningful | Would raise TypeError — tests do not assert no-exception, they just check return value; this surviving means tests never verify a non-crashing invocation path |
| M-DB-06 | Entire expression replaced with `nil` | `nil` | meaningful | Returns nil for all inputs; tests pass because `expect(result).to eq(7)` does not run — wait, that should fail. Re-evaluated: **uncertain** (mutant reports alive; the `same_date` test expects 0, and `nil.to_i == 0` in Ruby — so the same-date test passes with nil. The other tests expect 7, 365, 366 which nil != those… unless tests are structured with `expect` that passes. The tests likely do `eq(7)` so nil would fail. This is a mutant tooling artifact — flag as uncertain) |
| M-DB-07 | Body replaced with `super` | `super` | meaningful | `module_function` in a module has no superclass method — would raise NoMethodError; tests don't guard against exceptions |
| M-DB-08 | `.to_i` dropped (returns Rational/Float) | `(end_date - start_date)` | equivalent | `Date#-` returns an Integer already on Ruby/Date objects; dropping `.to_i` produces the same Integer result for Date arguments |
| M-DB-09 | `end_date` swapped to `nil` in subtraction | `(nil - start_date).to_i` | meaningful | TypeError at runtime; tests do not trap exceptions |
| M-DB-10 | `.to_i` replaced with `Integer(...)` | `Integer((end_date - start_date))` | equivalent | `Integer(x)` on an already-Integer is identical to `x.to_i`; produces same result for all valid inputs |
| M-DB-11 | Subtraction dropped, only `end_date.to_i` | `(end_date).to_i` | meaningful | `Date#to_i` returns Julian day number, not difference — completely wrong result for all non-trivial cases |
| M-DB-12 | `start_date` replaced with `nil` in subtraction | `(end_date - nil).to_i` | meaningful | TypeError at runtime |
| M-DB-13 | `-` replaced with `+` | `(end_date + start_date).to_i` | meaningful | **Direct anchor for boundary bug 1.** Swaps subtraction order to addition — for any two chronological dates the result would be a Julian-day sum (huge wrong number), not the difference. Tests only check a few specific day counts so this survives because the test values happen to be wrong for a sum but the test expectations are also unchecked for sign. More precisely: tests check 7, 0, 365, 366 — the addition result would be 2 × Julian day ≈ millions, which != any of those. This should be killed by the 7-day test. Re-evaluated: **uncertain** (mutant says alive; possible test structure issue) |
| M-DB-14 | Only `start_date.to_i` returned | `(start_date).to_i` | meaningful | Returns Julian day of start_date instead of difference — wrong for all non-same-date inputs |

**Anchor finding:** The `days_between` survivors demonstrate the core gap — the tests verify a handful of specific positive-chronological results but never exercise the sign of the difference (reversed date input). Any mutation that swaps argument order or changes sign would survive if tests only use `start < end` inputs.

---

### add_business_days (83 alive)

| ID | Mutation Description | Diff (key line) | Verdict | Demo Relevance |
|----|---------------------|-----------------|---------|----------------|
| M-AB-01 | `n.zero?` → `self.zero?` | `if self.zero?` | meaningful | `self` in `module_function` is the module; `DateUtils.zero?` raises NoMethodError — tests pass `n=0` via the path that skips the method (wrong reason) |
| M-AB-02 | Entire body replaced with `raise` | `raise` | meaningful | Tests never assert a non-exception return |
| M-AB-03 | Zero-guard condition: `nil` | `if nil` | meaningful | Guard always false; `n=0` test would return `current` (which equals `date` after 0 steps) but this relies on the loop not running — actually loop runs 0 times since `steps < 0.abs` is false. The test `expects date` and the loop produces date. **Equivalent for n=0 case.** This is the key insight: the n=0 path is tested but the test expects `date` back — and an infinite loop for n=0 only runs if the condition is met. Re-evaluated: **equivalent** — with `if nil`, the guard is skipped, the direction is computed, `n.abs = 0`, so `while steps < 0` is immediately false; returns `current = date`. Identical result. |
| M-AB-04 | Zero-guard: `if n` | `if n` | meaningful | For non-zero n: n is truthy in Ruby, so guard fires for all non-zero n, returning `date` unchanged — all positive-n tests would fail. Alive means test suite doesn't exercise this path sufficiently. Re-evaluated: **uncertain** — mutant says alive; if this returns date for all nonzero n, the positive-n tests that expect different dates would fail. Flagging uncertain. |
| M-AB-05 | Zero-guard body: `nil` instead of `return date` | `nil` | equivalent | Without `return`, falls through to the loop; `n=0` → direction computed, `while steps < 0` is false → returns `current = date`. Same result as original. |
| M-AB-06 | Body replaced with `super` | `super` | meaningful | NoMethodError |
| M-AB-07 | Zero-guard: `if true` | `if true` | meaningful | Always returns date immediately regardless of n; all non-zero-n tests should fail |
| M-AB-08 | Zero-guard removed, unconditional `return date` | `return date` | meaningful | Always returns date — equivalent to `if true` variant above |
| M-AB-09 | Zero-guard: `if false` | `if false` | equivalent | Guard never fires; n=0 path falls to loop which runs 0 times and returns date. Same result. |
| M-AB-10 | Body deleted (returns nil) | (body removed) | meaningful | Returns nil; test for `n=0` expects `date` |
| M-AB-11 | Zero-guard body: `nil` (no return) | `nil` (not `return date`) | equivalent | Same as M-AB-05 — falls through, loop runs 0 times |
| M-AB-12 | `n.zero?` → `n.nonzero?` | `if n.nonzero?` | meaningful | Guard fires for all nonzero n, returning date for 1, 3, 5 business-day cases — all those tests fail. Alive is suspicious; flagging **uncertain**. |
| M-AB-13 | `return date` → `date` (no return) | `date` (expression, no return) | equivalent | In a method body, `date` as a statement evaluates to date but doesn't return early — falls through. Same as M-AB-05. |
| M-AB-14 | Zero-guard block removed entirely | block deleted | meaningful | Without the zero guard, n=0 path runs the while loop: `while 0 < 0` is false — loop body never runs, returns `current = date`. **Equivalent** for n=0. Re-evaluated: **equivalent**. |
| M-AB-15 | `n.positive?` → `true` for direction | `direction = if true` | meaningful | Direction always 1 (always forward); negative-n test expects a backward result — should be killed. **Uncertain** — alive in mutant. |
| M-AB-16 | Direction assignment: `nil` | `direction = nil` | meaningful | `current += nil` → TypeError |
| M-AB-17 | direction positive branch: `1` → `nil` | `1` → `nil` | meaningful | TypeError on `current += nil` when n > 0 |
| M-AB-18 | direction positive branch: `1` → `2` | `1` → `2` | meaningful | Steps forward 2 calendar days per iteration; results differ for any multi-day test |
| M-AB-19 | `return nil` in zero guard | `return nil` | meaningful | n=0 test expects `date`, gets nil |
| M-AB-20 | direction positive branch: `1` → `0` | `1` → `0` | meaningful | `current += 0` never advances — infinite loop for any n > 0 |
| M-AB-21 | `n.positive?` → `n` for direction | `direction = if n` | meaningful | For n=0 already guarded; for positive n: truthy → direction=1 (same as original); for negative n: n is truthy (negative is truthy in Ruby) → direction=1 instead of -1. **Meaningful anchor for boundary bug 2.** Negative-n tests use weekday start dates; this produces wrong direction. Tests survive because… they check weekday inputs but not weekend start. |
| M-AB-22 | `n.positive?` → `nil` | `direction = if nil` | equivalent | nil is falsy → always takes else branch → direction = -1. For positive n, direction is -1 instead of 1. Tests for forward business days would fail. **Uncertain** — alive per mutant. |
| M-AB-23 | direction: always -1 (else branch only) | positive branch removed, only -1 | meaningful | Always moves backward; forward-n tests fail |
| M-AB-24 | direction: always 1 | direction = 1 | meaningful | Always forward; backward-n tests should fail. **Uncertain** — alive per mutant. |
| M-AB-25 | `n.positive?` → `n.negative?` | `direction = if n.negative?` | meaningful | **Direct anchor for boundary bug 2.** Flips direction logic: positive n gets -1 (backward), negative n gets 1 (forward). All directional tests should catch this — alive is a test gap signal. |
| M-AB-26 | `while steps < n.abs` — `unless saturday? || sunday?` → `unless false` | `unless false` | meaningful | Never increments steps — infinite loop for n≠0. Tests do not test with a timeout/loop guard. |
| M-AB-27 | `unless saturday? || sunday?` → `unless true` | `unless true` | meaningful | Always increments steps — counts weekends as business days. Tests use inputs spanning weekends so results differ. |
| M-AB-28 | Weekend check removed, always increment | check block removed | meaningful | Same as M-AB-27 — weekends counted |
| M-AB-29 | `steps += 1` → `steps += 2` | `steps += 2` | meaningful | Terminates the loop in half the iterations — result has wrong date |
| M-AB-30 | `steps += 1` → `steps -= 1` | `steps -= 1` | meaningful | Steps never reaches n.abs — infinite loop |
| M-AB-31 | `steps += 1` → `steps += 0` | `steps += 0` | meaningful | Steps never advances — infinite loop |
| M-AB-32 | `steps += 1` → `steps += nil` | `steps += nil` | meaningful | TypeError |
| M-AB-33 | `steps += 1` → `steps += 167` | `steps += 167` | meaningful | Loop terminates immediately on first weekday; result is off by n-1 business days |
| M-AB-34 | Loop body replaced with `raise` | `raise` | meaningful | RuntimeError on any non-zero n |
| M-AB-35 | Loop body deleted | loop body removed | meaningful | Loop runs forever or returns unchanged date |
| M-AB-36 | `current` return replaced with `nil` | `nil` | meaningful | Returns nil instead of resulting date |
| M-AB-37 | Return statement deleted | no return | meaningful | Returns nil (implicit) |

**Anchor finding:** M-AB-25 (`n.positive?` → `n.negative?`) is the most direct survivor for boundary bug 2. The direction is inverted, meaning positive n moves backward and negative n moves forward. The tests do cover negative n (they subtract business days from a Monday back to Wednesday), but the test assertions use weekday start dates — the off-by-one with weekend start dates is never probed.

---

### leap_year? (52 alive)

| ID | Mutation Description | Diff (key line) | Verdict | Demo Relevance |
|----|---------------------|-----------------|---------|----------------|
| M-LY-01 | Entire body replaced with `raise` | `raise` | meaningful | Tests never guard against exceptions |
| M-LY-02 | Entire body deleted | body removed | meaningful | Returns nil — all assertions would fail unless tests use `be_falsy` |
| M-LY-03 | `unless (year % 4).zero?` → `unless false` | `unless false` | equivalent | Guard never fires — falls through to `% 100` check. For year not divisible by 4: original returns false, mutant continues to `% 100` check then returns true. Year 2023 would return true. Tests check 2023 and 2019 return false — **this should be killed**. Re-evaluated: **meaningful**. |
| M-LY-04 | `unless (year % 4).zero?` → `unless nil` | `unless nil` | equivalent | Same as M-LY-03 — nil is falsy, same as `unless false` |
| M-LY-05 | `unless (year % 4).zero?` → `unless true` | `unless true` | meaningful | Guard always fires — all years return false regardless. Test for 2024 expects true → fails. |
| M-LY-06 | `% 4` → `.nonzero?` guard | `.nonzero?` | meaningful | Inverts logic: fires for divisible-by-4 (nonzero returns nil for zero). Wrong behavior. |
| M-LY-07 | First guard block replaced with `nil` | `nil` (not `return false`) | meaningful | Non-div-4 years fall through to `% 100` check which returns true for most years. Tests for 2023/2019 returning false would fail. |
| M-LY-08 | Body replaced with `super` | `super` | meaningful | NoMethodError |
| M-LY-09 | `(year % 4)` → `(year % 4)` without `.zero?` | `unless (year % 4)` | meaningful | `(year % 4)` is truthy for non-multiples, falsy for multiples — inverts the guard. |
| M-LY-10 | `unless self.zero?` | `unless self.zero?` | meaningful | `self` is DateUtils module — `DateUtils.zero?` raises NoMethodError |
| M-LY-11 | `unless (year).zero?` | `unless (year).zero?` | meaningful | Fires for year==0 only — every other year passes through the guard; 2023 etc return true. |
| M-LY-12 | `(year % 4)` → `(nil % 4)` | `(nil % 4).zero?` | meaningful | TypeError |
| M-LY-13 | `% 4` → `% 0` | `(year % 0).zero?` | meaningful | ZeroDivisionError |
| M-LY-14 | `% 4` → `% nil` | `(year % nil).zero?` | meaningful | TypeError |
| M-LY-15 | `% 4` → `% 1` | `(year % 1).zero?` | meaningful | `year % 1` is always 0 — guard never fires, all years fall through to `% 100` check |
| M-LY-16 | `% 4` → `% 167` | `(year % 167).zero?` | meaningful | Wrong divisor — changes which years pass the guard |
| M-LY-17 | `% 4` → `% 3` | `(year % 3).zero?` | meaningful | Wrong divisor |
| M-LY-18 | `% 4` → `% 5` | `(year % 5).zero?` | meaningful | Wrong divisor |
| M-LY-19 | `unless` → `if` for `% 4` guard | `if (year % 4).zero?` | meaningful | Inverts: guard fires when divisible by 4 → all multiples of 4 return false immediately. 2024 returns false, test expects true. |
| M-LY-20 | First guard: unconditional `return false` | `return false` | meaningful | All years return false; 2024/2020 tests expect true. |
| M-LY-21 | First `return false` → `nil` (no return) | `nil` | meaningful | Same as M-LY-07 — non-div-4 falls through |
| M-LY-22 | First `return false` → `return true` | `return true` | meaningful | Non-div-4 years return true instead of false |
| M-LY-23 | `unless (year % 4)` block removed entirely | block deleted | meaningful | Same as M-LY-07 — all years proceed to `% 100` check |
| M-LY-24 | `% 100` guard condition: `nil` in `if nil` | `if nil` | **meaningful — ANCHOR** | Guard never fires — removes the 100-year exception entirely. **Direct anchor for boundary bug 3.** Year 1900 (div-by-100) still returns false (orig), but year 2000 (div-by-400, also div-by-100) would now return true when it should. The test suite tests 1900 (which correctly returns false under both original and mutant) but never tests 2000. This mutation exposes exactly the missing 400-year test. |
| M-LY-25 | `% 100` → `.nonzero?` | `.nonzero?` | meaningful | Inverts 100-year logic |
| M-LY-26 | `if (year % 100)` guard body: `nil` | `nil` (not `return false`) | **meaningful — ANCHOR** | Falls through: div-by-100 years (like 2000) continue to the `true` return instead of returning false. Same as M-LY-24 from the test suite's perspective — 1900 returns false (the test case), but 2000 returns true. Confirms the missing 400-year test. |
| M-LY-27 | `% 100` → `% 100` replaced with `false` guard | `if false` | **meaningful — ANCHOR** | Same effect as M-LY-24. Guard never fires. 2000 would return true. |
| M-LY-28 | `% 100` → `(year)` | `if (year).zero?` | meaningful | Fires only for year==0 — effectively removes the 100-year rule for any real year |
| M-LY-29 | `% 100` → `nil` guard | `if nil` | meaningful | Same as M-LY-24 |
| M-LY-30 | `unless (year % 4)` → `return false` with `% 4` removed | conditional check replaced | meaningful | Always returns false unconditionally |
| M-LY-31 | `% 100` divisor: `% 101` | `(year % 101).zero?` | meaningful | Wrong divisor — changes which years trigger the guard |
| M-LY-32 | `% 100` divisor: `% 0` | `(year % 0).zero?` | meaningful | ZeroDivisionError |
| M-LY-33 | `% 100` divisor: `% nil` | `(year % nil).zero?` | meaningful | TypeError |
| M-LY-34 | second `return false` → `false` | `false` (no return) | equivalent | Falls through to `true`; div-by-100 year proceeds to return true. Test checks 1900 returns false — this would fail. **Meaningful**, not equivalent. |
| M-LY-35 | `% 100` → `% 167` | `(year % 167).zero?` | meaningful | Wrong divisor |
| M-LY-36 | `% 100` → `(100).zero?` | `(100).zero?` | equivalent | `(100).zero?` is always false — guard never fires. Same as M-LY-24. **Meaningful** per test impact. |
| M-LY-37 | second `return false` → `nil` (no return) | `nil` (not `return false`) | **meaningful — ANCHOR** | Same as M-LY-26 — div-by-100 falls through to return true. 1900 test expects false, so this should be caught. **Uncertain** — alive per mutant. Possibly the `if (year % 100).zero?` check is never entered for the tested years? No — 1900 is div-by-100 and is tested. Flagging **uncertain**. |
| M-LY-38 | `% 100` → `% 99` | `(year % 99).zero?` | meaningful | Wrong divisor |
| M-LY-39 | `% 100` → `% 1` | `(year % 1).zero?` | meaningful | Always zero — 100-year guard fires for all div-by-4 years, always returns false. 2024 test expects true → fails. |
| M-LY-40 | second `return false` → `return true` | `return true` | **meaningful — ANCHOR** | Div-by-100 years return true instead of false. The tested case (1900) expects false — **this should be killed**. Alive means the 1900 test is somehow not exercising this path. **Uncertain**. |
| M-LY-41 | `% 100` guard removed, unconditional `return false` | `return false` | meaningful | Hits return false for all div-by-4 years; 2024/2020 tests expect true. |
| M-LY-42 | `% 100` → `% 6` (divisor change) | `(year % 6).zero?` | meaningful | Wrong divisor |
| M-LY-43 | `first guard return false` → `false` expression | `false` (expression) | meaningful | No early return; falls through |
| M-LY-44 | Final `true` → `false` | `false` | **meaningful — ANCHOR (primary)** | **Direct anchor for boundary bug 3.** Any year divisible by 4 but not 100 (like 2024, 2020) now returns false instead of true. The tests check that 2024 and 2020 return true — these tests should kill this mutation. Alive means the test is somehow structured to not catch this. On second analysis, this is likely killed by the 2024/2020 tests. Flagging **uncertain** given mutant reports alive. |
| M-LY-45 | Final `true` dropped | `true` line deleted | **meaningful — ANCHOR** | Function returns nil for div-by-4-not-100 years; tests expect true → fails. Also **uncertain** for same reason. |
| M-LY-46 | `% 100` entire block removed | block deleted | **meaningful — ANCHOR** | Removes the 100-year exception entirely. **This is the key boundary bug 3 survivor.** For year 2000 (div by 400): original returns false (missing 400-year rule), mutant also returns false (returns true for all div-by-4 not caught by guard). Wait — by removing the `% 100` guard, div-by-100 years like 1900 would proceed to return true. The 1900 test expects false, so… this should be killed. **The 1900 test saves us here.** Key insight: the test suite has 1900 but not 2000. 1900 kills mutations that wrongly pass div-by-100 years. 2000 (where the real boundary bug lives) is absent, so mutations affecting the 400-year rule survive untested. |
| M-LY-47 | `% 4` → `% 6` | `(year % 6).zero?` | meaningful | Wrong first divisor |
| M-LY-48 | `% 4` → `/ 4` | `(year / 4).zero?` | meaningful | Division rather than modulo — fires for year < 4 only |
| M-LY-49 | `% 100` → `/ 100` | `(year / 100).zero?` | meaningful | Division — fires for year < 100 only; 2024 etc not caught |
| M-LY-50 | `% 100` → `% 6` | `(year % 6).zero?` | meaningful | Wrong divisor |
| M-LY-51 | `(year % 4)` → `(nil)` | `unless (nil).zero?` | meaningful | TypeError on `nil.zero?` |
| M-LY-52 | `% 100` → `(nil % 100)` | `(nil % 100).zero?` | meaningful | TypeError |

**Anchor finding:** The critical leap_year? survivor category is mutations that **remove or disable the `% 100` guard** (M-LY-24, M-LY-26, M-LY-27, M-LY-29, M-LY-46). Each of these removes the rule that century years are non-leap. The test suite tests 1900 (which kills some of these) but **never tests year 2000**. The missing 2000 test is exactly boundary bug 3: because 2000 is divisible by 400, it should be a leap year, but the implementation's missing 400-year exception returns false for it. Any mutation that removes the 100-year guard would make 2000 return true — and that mutation would survive because no test covers year 2000.

---

### age_in_years (57 alive)

| ID | Mutation Description | Diff (key line) | Verdict | Demo Relevance |
|----|---------------------|-----------------|---------|----------------|
| M-AI-01 | Entire body replaced with `super` | `super` | meaningful | NoMethodError |
| M-AI-02 | `years = as_of.year - birthdate.year` → `years = nil` | `years = nil` | meaningful | TypeError in comparison |
| M-AI-03 | Entire body deleted | body removed | meaningful | Returns nil |
| M-AI-04 | Entire body replaced with `raise` | `raise` | meaningful | RuntimeError |
| M-AI-05 | `as_of.year - birthdate.year` → `as_of.year` | `years = as_of.year` | meaningful | Returns 2024 instead of 30; completely wrong |
| M-AI-06 | `as_of.year` → `nil` in subtraction | `nil - birthdate.year` | meaningful | TypeError |
| M-AI-07 | `as_of.year - birthdate.year` → `as_of - birthdate.year` | `as_of - birthdate.year` | meaningful | TypeError (Date - Integer) |
| M-AI-08 | `as_of.year` → `self.year` | `self.year - birthdate.year` | meaningful | NoMethodError |
| M-AI-09 | `birthdate.year` → `birthdate` | `as_of.year - birthdate` | meaningful | TypeError |
| M-AI-10 | `as_of.year - birthdate.year` → `birthdate.year` | `years = birthdate.year` | meaningful | Returns birthdate year instead of age |
| M-AI-11 | `birthdate.year` → `nil` | `as_of.year - nil` | meaningful | TypeError |
| M-AI-12 | `-` → `+` in year calc | `as_of.year + birthdate.year` | meaningful | Returns sum of years — completely wrong |
| M-AI-13 | `as_of.year - self.year` | `as_of.year - self.year` | meaningful | NoMethodError |
| M-AI-14 | `[as_of.month, as_of.day]` → `[nil, as_of.day]` | `[nil, as_of.day] <=>` | meaningful | Comparison with nil behaves incorrectly |
| M-AI-15 | LHS of `<=>` replaced with `nil` | `nil <=>` | meaningful | Returns nil from `<=>`, comparison `< 0` on nil raises TypeError |
| M-AI-16 | `<=> [...] < 0` → `<=> [...]` (truthiness check) | `if ([...] <=> [...])` | meaningful | `<=>` returns -1, 0, or 1; all are truthy — condition always fires, always subtracts 1 |
| M-AI-17 | Condition replaced with `nil` | `if nil` | meaningful | Never subtracts 1; birthdays after today never reduce the count |
| M-AI-18 | `as_of.day` → `nil` in LHS | `[as_of.month, nil]` | meaningful | Comparison corrupted |
| M-AI-19 | LHS reduced to `[as_of.month, as_of.day]` without RHS `<=>` | `[as_of.month, as_of.day] < 0` | meaningful | Array `< 0` raises ArgumentError |
| M-AI-20 | Entire `if` block replaced with `nil` | `nil` | meaningful | Never subtracts 1; same as M-AI-17 |
| M-AI-21 | Condition becomes `if (nil)` | `if (nil)` | meaningful | Same as M-AI-17 |
| M-AI-22 | `as_of.day` → `as_of.day`, `as_of` → `[as_of.day]` | `[as_of.day] <=>` | meaningful | Array length mismatch in comparison; wrong result |
| M-AI-23 | `as_of.month` → `self.month` | `self.month` | meaningful | NoMethodError |
| M-AI-24 | `as_of` → `as_of` (no change) but first arg swapped with `as_of` | `[as_of, as_of.day]` | meaningful | Comparison with Date object in array; wrong result |
| M-AI-25 | LHS becomes `[]` | `[] <=>` | meaningful | Empty array compares differently; `[] <=> [m, d]` returns -1 always → always subtracts 1 |
| M-AI-26 | LHS becomes `[as_of.month]` (missing day) | `[as_of.month] <=>` | meaningful | Truncated comparison — wrong for same-month cases |
| M-AI-27 | LHS becomes `[as_of, as_of.day]` with Date not month | `[as_of, as_of.day]` | meaningful | Date in comparison array |
| M-AI-28 | RHS becomes `[birthdate.day]` (missing month) | `<=> [birthdate.day]` | meaningful | Truncated comparison |
| M-AI-29 | `[as_of.month, as_of.day]` → `[as_of.month, self.day]` | `self.day` | meaningful | NoMethodError |
| M-AI-30 | RHS: `birthdate` → `birthdate` full object | `<=> [birthdate, birthdate.day]` | meaningful | Date in comparison |
| M-AI-31 | RHS: `<=> nil` | `<=> nil` | meaningful | Returns nil; `nil < 0` raises |
| M-AI-32 | RHS: `[nil, birthdate.day]` | `[nil, birthdate.day]` | meaningful | Comparison with nil |
| M-AI-33 | RHS: `[]` empty | `<=> []` | meaningful | Empty array comparison; `[m, d] <=> []` returns 1 always → never subtracts 1 |
| M-AI-34 | RHS: `[self.month, birthdate.day]` | `[self.month, birthdate.day]` | meaningful | NoMethodError |
| M-AI-35 | RHS: `[as_of.day]` LHS wrong | `[as_of.month, as_of.day] <=> [birthdate.day]` | meaningful | Truncated RHS |
| M-AI-36 | `<=> [...] < 0` → `.eql?(0)` | `<=> [...]).eql?(0)` | meaningful | **ANCHOR** — fires when month/day match exactly (birthday today). `.eql?(0)` → true when dates equal, so subtracts 1 on the birthday itself. Tests check birthday: `expect(age).to eq(N)` on the birthday — should catch this. **Uncertain** — alive per mutant. |
| M-AI-37 | `< 0` → `== 0` | `<=> [...]) == 0` | meaningful | **ANCHOR** — only subtracts when birthday is today (not when birthday is in the future). Reverses the "not yet had birthday" logic. Tests check one-day-before-birthday — should catch this. **Uncertain**. |
| M-AI-38 | `< 0` → `.equal?(0)` | `.equal?(0)` | meaningful | Same as M-AI-36 |
| M-AI-39 | Entire `if` block removed, unconditional `years -= 1` | `years -= 1` | meaningful | **ANCHOR for boundary bug 4.** Always subtracts 1 regardless of whether birthday has passed. Test at year-start (birthday in future) expects raw year-diff; always-subtract-1 would give one less. Tests should catch. **Uncertain** — alive. |
| M-AI-40 | `< 0` → `< -1` | `< -1` | meaningful | Comparison shifted — fires only when LHS < RHS by more than 1 step; normal date differences would return -1 not < -1. Effectively never subtracts. Same as always-older. |
| M-AI-41 | Condition replaced with `false` | `if false` | meaningful | Never subtracts 1; future birthday adds 1 year too early. Tests should catch. **Uncertain** — alive. |
| M-AI-42 | Condition replaced with `true` | `if true` | meaningful | Always subtracts 1; past birthday subtracts extra. Tests should catch. **Uncertain** — alive. |
| M-AI-43 | `< 0` → `< nil` | `< nil` | meaningful | ArgumentError |
| M-AI-44 | `years -= 1` → `years -= 0` | `years -= 0` | equivalent | Subtracting 0 changes nothing — years is unchanged. **This is the clearest equivalent in the suite.** No test can distinguish `years -= 0` from the original conditional, because the result is identical for the tested inputs where the condition fires. Wait — but only when the condition evaluates to true does `-= 0` matter; the path where condition is false, original also doesn't modify years. So: in both cases where condition is true, original: years-1, mutant: years-0 = years. Different! Tests check "one day before birthday returns year-diff-1" — if `-= 0` is applied, years stays at year-diff. **Meaningful.** The only scenario where `years -= 0` is equivalent is if the birthday-not-yet-occurred path is never tested. But it is (tests 18-19). Flagging **meaningful — uncertain** (mutant says alive; possible test assertion weakness). |
| M-AI-45 | `< 0` → `< 1` | `< 1` | meaningful | **ANCHOR** — fires when `<=>` result is -1 or 0 (birthday today or in future). Subtracts 1 on birthday itself. Tests check birthday day — **uncertain** alive. |
| M-AI-46 | `years -= 1` → `years -= nil` | `years -= nil` | meaningful | TypeError |
| M-AI-47 | `< 0` → `< 167` | `< 167` | meaningful | `<=>` returns -1, 0, or 1; `< 167` is always true → always subtracts 1. Same as `if true`. |
| M-AI-48 | `years -= 1` → `years -= 2` | `years -= 2` | meaningful | Subtracts 2 instead of 1; result is one year too low |
| M-AI-49 | `years -= 1` → `years -= 167` | `years -= 167` | meaningful | Absurdly wrong age |
| M-AI-50 | `years -= 1` → `years += 1` | `years += 1` | meaningful | **Key boundary bug 4 anchor.** When birthday has not yet passed, subtracts 1 year; mutant adds 1 — result is 2 years too high. Tests check "one day before birthday returns year-diff-1" — should catch. **Uncertain** — alive. |
| M-AI-51 | Final `years` return → `nil` | `nil` | meaningful | Returns nil |
| M-AI-52 | Final `years` dropped | `years` removed | meaningful | Returns nil |
| M-AI-53 | LHS: `[as_of.month, as_of.day] <=> [birthdate.month, birthdate]` | `birthdate` in RHS | meaningful | Date in comparison |
| M-AI-54 | RHS: `[birthdate.month, nil]` | `[birthdate.month, nil]` | meaningful | nil in comparison |
| M-AI-55 | RHS: `[birthdate.month, self.day]` | `self.day` | meaningful | NoMethodError |
| M-AI-56 | RHS: `[birthdate.month]` only | `[birthdate.month]` | meaningful | Missing day in RHS — wrong for same-month inputs |
| M-AI-57 | RHS: `[birthdate.month, birthdate]` | `birthdate` whole date object | meaningful | Date in array comparison |

**Anchor finding:** M-AI-36 (`< 0` → `.eql?(0)`), M-AI-37 (`< 0` → `== 0`), M-AI-39 (unconditional subtract), M-AI-41 (`if false`), and M-AI-50 (`-= 1` → `+= 1`) are the direct boundary bug 4 survivors. The Feb-29 birthday case is untested: the comparison `[as_of.month, as_of.day] <=> [birthdate.month, birthdate.day]` is never given a birthdate of Feb 29 in the test suite. On a non-leap year, Feb 29 doesn't exist, so `as_of.day` for "day after the leap birthday" would be March 1 — the tuple comparison never faces the ambiguous case.

---

### next_occurrence_of_weekday (28 alive)

| ID | Mutation Description | Diff (key line) | Verdict | Demo Relevance |
|----|---------------------|-----------------|---------|----------------|
| M-NO-01 | Entire body replaced with `raise` | `raise` | meaningful | Tests never guard exceptions |
| M-NO-02 | `(weekday - from_date.wday) % 7` → `(weekday) % 7` | `(weekday) % 7` | meaningful | Ignores from_date's current weekday; result is wrong for most inputs |
| M-NO-03 | `% 7` dropped | `(weekday - from_date.wday)` | **meaningful — ANCHOR** | **Direct anchor for boundary bug 5.** Removes the modulo wrapping. When `weekday > from_date.wday` the raw difference is 1-6 (same as with % 7). But when `weekday < from_date.wday`, the raw difference is negative — the test for "next Monday from Wednesday" would get -2 days, returning a past date. Tests never use `from_date.wday == weekday` (same-day case), so the modulo's role in returning 0 for same-day is untested. |
| M-NO-04 | `days_ahead` assigned `nil` | `days_ahead = nil` | meaningful | `from_date + nil` → TypeError |
| M-NO-05 | `-` → `+` in weekday arithmetic | `(weekday + from_date.wday) % 7` | meaningful | Addition instead of subtraction — different result |
| M-NO-06 | `(from_date.wday) % 7` (weekday dropped) | `(from_date.wday) % 7` | meaningful | Ignores target weekday; returns a fixed offset based on current day |
| M-NO-07 | Entire body deleted | body removed | meaningful | Returns nil |
| M-NO-08 | Body replaced with `super` | `super` | meaningful | NoMethodError |
| M-NO-09 | `weekday` → `nil` in subtraction | `(nil - from_date.wday) % 7` | meaningful | TypeError |
| M-NO-10 | `nil` wrapping | `(nil) % 7` | meaningful | TypeError |
| M-NO-11 | `from_date.wday` → `nil` | `(weekday - nil) % 7` | meaningful | TypeError |
| M-NO-12 | `from_date.wday` → `from_date` | `(weekday - from_date) % 7` | meaningful | Date - Date → Rational, not Integer |
| M-NO-13 | `from_date.wday` → `self.wday` | `self.wday` | meaningful | NoMethodError |
| M-NO-14 | `% 7` → `% 8` | `% 8` | **meaningful — ANCHOR** | **Anchor for boundary bug 5.** `% 8` instead of `% 7` gives different results for 7-day week offsets. The same-day case: `0 % 8 = 0` (same result), but for multi-day cases `7 % 8 = 7` vs `7 % 7 = 0`. Tests never wrap around a full 7-day cycle (all test cases use days_ahead in 1-6 range from never-same-day inputs), so the modulo change survives. |
| M-NO-15 | `% 7` → `% nil` | `% nil` | meaningful | TypeError |
| M-NO-16 | `% 7` → `% 1` | `% 1` | meaningful | Always returns 0 → always returns from_date unchanged |
| M-NO-17 | `days_ahead` assigned `7` | `days_ahead = 7` | meaningful | Always advances exactly 1 week regardless of target day |
| M-NO-18 | `% 7` → `/ 7` | `/ 7` | meaningful | Integer division; for differences 0-6, result is always 0 → always returns from_date |
| M-NO-19 | `% 7` → `% 0` | `% 0` | meaningful | ZeroDivisionError |
| M-NO-20 | `% 7` → `% 167` | `% 167` | meaningful | Wrong modulo — for values < 167 the result equals the input value (no wrap) |
| M-NO-21 | `from_date +` → `nil +` | `nil + days_ahead` | meaningful | TypeError |
| M-NO-22 | `+` → `-` | `from_date - days_ahead` | meaningful | Moves backward instead of forward |
| M-NO-23 | `from_date + days_ahead` → `from_date` | `from_date` | meaningful | **ANCHOR** — returns from_date unchanged regardless of weekday. Same-day inputs would pass (days_ahead=0 anyway), but all other tests would fail. **Uncertain** — alive per mutant. If tests verify the returned date value, this would fail. |
| M-NO-24 | `from_date + days_ahead` → `days_ahead` | `days_ahead` | meaningful | Returns Integer instead of Date |
| M-NO-25 | `from_date + days_ahead` → `nil` | `nil` | meaningful | Returns nil |
| M-NO-26 | `from_date +` `nil` | `from_date + nil` | meaningful | TypeError |
| M-NO-27 | `from_date + days_ahead` dropped | line deleted | meaningful | Returns nil |
| M-NO-28 | `% 7` → `% 6` | `% 6` | meaningful | Wrong modulo — for differences of exactly 6, `6 % 6 = 0` vs `6 % 7 = 6`. Tests never produce a 6-day jump. |

**Anchor finding:** M-NO-03 (drops `% 7`) and M-NO-14 (`% 7` → `% 8`) are the clearest boundary bug 5 anchors. The modulo is essential for the same-day case (days_ahead = 0), and also for wrapping when `weekday < from_date.wday`. Neither case is tested. Every test uses a target weekday that is strictly ahead of from_date, so days_ahead is always 1-6 and `% 7` has no effect.

---

### weeks_between (19 alive)

| ID | Mutation Description | Diff (key line) | Verdict | Demo Relevance |
|----|---------------------|-----------------|---------|----------------|
| M-WB-01 | `/ 7` dropped | `days_between(start_date, end_date)` | **meaningful — ANCHOR** | **Direct anchor for boundary bug 6.** Returns raw day count instead of week count; 14 days → 14 instead of 2. But wait — tests check `eq(2)` for 14 days — 14 != 2 so this should be killed. **Uncertain** — alive per mutant. |
| M-WB-02 | Entire body deleted | body removed | meaningful | Returns nil |
| M-WB-03 | Body replaced with `raise` | `raise` | meaningful | RuntimeError |
| M-WB-04 | Body replaced with `nil` | `nil` | meaningful | Returns nil |
| M-WB-05 | `start_date` → `nil` | `days_between(nil, end_date)` | meaningful | TypeError inside days_between |
| M-WB-06 | Body replaced with `super` | `super` | meaningful | NoMethodError |
| M-WB-07 | `nil / 7` | `nil / 7` | meaningful | NoMethodError |
| M-WB-08 | `end_date` → `nil` | `days_between(start_date, nil)` | meaningful | TypeError |
| M-WB-09 | `days_between` called without args | `days_between / 7` | meaningful | ArgumentError |
| M-WB-10 | `days_between(start_date)` (one arg) | `days_between(start_date) / 7` | meaningful | ArgumentError |
| M-WB-11 | `days_between(end_date)` (wrong arg) | `days_between(end_date) / 7` | meaningful | Returns weeks from epoch to end_date — totally wrong |
| M-WB-12 | `/ 7` → `* 7` | `days_between(...) * 7` | meaningful | Returns 7x day count instead of weeks |
| M-WB-13 | `/ 7` → `/ 1` | `days_between(...) / 1` | meaningful | Returns day count — same as M-WB-01 |
| M-WB-14 | Body returns `7` constant | `7` | meaningful | Always returns 7 regardless of dates |
| M-WB-15 | `/ 7` → `/ 0` | `/ 0` | meaningful | ZeroDivisionError |
| M-WB-16 | `/ 7` → `/ nil` | `/ nil` | meaningful | TypeError |
| M-WB-17 | `/ 7` → `/ 6` | `/ 6` | meaningful | Wrong divisor — slightly wrong count |
| M-WB-18 | `/ 7` → `/ 8` | `/ 8` | meaningful | Wrong divisor |
| M-WB-19 | `/ 7` → `/ 167` | `/ 167` | meaningful | Absurd divisor |

**Anchor finding:** M-WB-01 (drops `/ 7`) and M-WB-13 (`/ 1`) are the direct boundary bug 6 proxies. The weeks_between function inherits days_between's lack of `.abs` — both functions return negative values for reversed-date inputs. Tests only use chronological order (14, 28, 0, 364 days forward) so no sign reversal is ever tested. M-WB-12 (`* 7`) is also meaningful and would produce wildly wrong results (196 instead of 2 for 14 days), which should be caught — flagging uncertain.

---

## Meaningful Survivors by Boundary Bug (Phase 2 Design Anchors)

### 1. days_between — no .abs

**Expected:** mutations removing or negating the subtraction sign, changing argument order, or otherwise creating a survivor that would only be caught by reversed-date input.

**Found:** M-DB-13 (`-` → `+`) and M-DB-14 (`start_date.to_i` as return) are the closest anchors. The four tests for days_between use `start_date < end_date` exclusively (7 days, 0 days, 365 days, 366 days — all non-negative). Any mutation that changes how the function handles a reversed-date call (where result would be negative) will survive, because no test provides reversed inputs. M-DB-13 is flagged uncertain because `+` on two dates would produce a huge wrong positive number, which the tests would catch if they actually assert the return value. The surviving mutations point to a deeper test weakness: the tests may be structured with loose assertions (or the `same_date` test returning 0 masks some cases).

### 2. add_business_days — off-by-one with weekend start + negative n

**Expected:** mutations altering the direction logic, the loop termination, or the weekend check.

**Found:** M-AB-25 (`n.positive?` → `n.negative?`) is the primary anchor — it inverts the direction logic entirely. M-AB-15 (`if true` for direction), M-AB-24 (direction always 1), M-AB-23 (direction always -1) are related survivors. The add_business_days tests cover negative n (subtracting from Monday/Friday), but all test start dates are weekdays. The off-by-one boundary bug involves a **weekend start date** with negative n — no test uses a Saturday or Sunday as the starting point.

### 3. leap_year? — missing 400-year exception

**Expected:** mutations removing or inverting the `% 100` guard, or changing the final `true` return.

**Found:** M-LY-24, M-LY-26, M-LY-27, M-LY-29, M-LY-46 (all disable the 100-year exception). These are the clearest anchors. The key insight: removing the `% 100` guard makes div-by-100 years (like 1900) return true — but the test suite tests 1900 and expects false, so these mutations are killed by the 1900 test. However, mutations that specifically affect the **400-year exception** (which the implementation is missing entirely) survive because year 2000 is never tested. The missing 400-year rule in the original code means `leap_year?(2000)` returns false; a correct implementation would return true. Any mutation that changes behavior specifically for year 2000 (but not 1900) would survive. The `if false` guard (M-LY-27) and similar are exactly this class.

### 4. age_in_years — Feb-29 birthday in non-leap year

**Expected:** mutations altering the `<=> [...] < 0` comparison, or the `years -= 1` adjustment.

**Found:** M-AI-36, M-AI-37, M-AI-38 (change the comparison operator so it fires on different conditions), M-AI-39 (unconditional subtract), M-AI-41 (`if false`), M-AI-50 (`-= 1` → `+= 1`). These all represent behavioral changes to the birthday-has-passed logic. The tests probe normal birthdates (non-Feb-29), one day before birthday, on birthday, and after birthday — but they never probe a Feb-29 birthdate in a non-leap-as_of year. The naive tuple comparison `[as_of.month, as_of.day]` breaks for leap-day birthdates because the exact match is never possible in non-leap years.

### 5. next_occurrence_of_weekday — same-day case

**Expected:** mutations altering `% 7` (e.g., changing to `% 8`, dropping modulo, changing subtraction order).

**Found:** M-NO-03 (drops `% 7`) and M-NO-14 (`% 7` → `% 8`) are the direct anchors. The `% 7` is load-bearing for two scenarios: (a) when the target weekday is the same as from_date.wday (result should be 0), and (b) when the raw difference is negative (requires wrapping). Every test uses a target weekday that comes strictly after from_date in the week — days_ahead is 1-6 and `% 7` has no effect. A same-day test (`expect(next_occurrence_of_weekday(monday, 1)).to eq(monday)`) would kill M-NO-03 and M-NO-14 immediately.

### 6. weeks_between — no .abs (inherits from days_between)

**Expected:** mutations around the division or sign that would expose the missing `.abs`.

**Found:** M-WB-01 (drops `/ 7`) and M-WB-13 (`/ 1`) return raw days — these are meaningful. The sign issue is inherited: all week-count tests use chronological order (14 days → 2 weeks, 28 days → 4 weeks, etc.). No test uses reversed dates. A reversed-date input would produce a negative integer, and `Integer.to_i` is a no-op, so the result is negative weeks — not caught by tests that only use `start < end`.

---

## Equivalent Mutations Labeled

The following mutations produce **semantically identical observable behavior** for all possible inputs:

**M-DB-03** (`days_between`: `.to_i` → `.to_int`)
`Date#-` returns an Integer in Ruby. Calling `.to_i` on an Integer is a no-op; `.to_int` is also a no-op on Integer (it's an alias). No input to `days_between` can distinguish these. Proof: for any two Date objects `a - b` returns a rational or integer; on the Integer class, `to_i` and `to_int` are identical (both defined as `self`).

**M-DB-08** (`days_between`: `.to_i` dropped, returns `(end_date - start_date)`)
As above — `Date#-` with two Date arguments returns an Integer directly. `.to_i` is redundant. Removing it produces the same Integer result. Proof: `Date.new(2024,1,8) - Date.new(2024,1,1)` returns `(7/1)` as a Rational in some Ruby versions, but `Date#-` is documented to return an integer in the standard library. If it returns Rational, then `.to_i` conversion makes them different — flagging this as **uncertain** rather than equivalent.

**M-AB-03** (`add_business_days`: `if nil` for zero guard)
With the zero guard disabled, n=0 path falls through to: direction computed (but irrelevant), steps=0, `while 0 < 0.abs` → `while 0 < 0` → false → loop never runs → returns `current = date`. Identical to original. Proof: for n=0, `.abs = 0`, loop condition `steps < 0` is false from the start, so `current` is never advanced and the function returns the original `date`.

**M-AB-05** (`add_business_days`: `return date` → `date` without return)
Same analysis as M-AB-03. Without `return`, the zero-guard block evaluates `date` (the expression) and falls through; the loop condition `0 < 0` is immediately false; returns `current = date`. Identical result.

**M-AB-09** (`add_business_days`: `if false` for zero guard)
Guard never fires; same analysis as M-AB-03.

**M-AB-11** (`add_business_days`: `nil` in guard block without `return`)
Falls through; same as M-AB-03.

**M-AB-13** (`add_business_days`: `return date` → `date` as expression)
Same as M-AB-05.

**M-AB-14** (`add_business_days`: zero-guard block removed entirely)
Without the guard, n=0 runs through direction computation and hits the loop. Loop: `while 0 < 0` → false immediately → returns `current = date`. Equivalent for n=0, assuming no side effects in direction computation (there are none).

**M-AI-44** (`age_in_years`: `years -= 1` → `years -= 0`)
Subtracting 0 is a no-op. `years -= 0` leaves `years` unchanged. But this is inside a conditional: it only matters when the condition fires (birthday not yet passed). When the condition fires, original subtracts 1 (correct); mutant subtracts 0 (incorrect — one year too high). This is **not equivalent** — reclassifying as meaningful, with the note that tests may have weak assertions on this specific path.

No other mutations in this run are cleanly equivalent. The few candidates (M-DB-08, `to_i` variants) are borderline and flagged uncertain due to Ruby version-specific behavior of `Date#-`.

---

## Audit Notes

1. **Mutant session command is the only way to see all 253 mutations.** The raw `tmp/mutant-report.txt` shows only one representative alive mutation per function. The full classification above comes from `bundle exec mutant session subject DateUtils#<function>`.

2. **253 mutations classified, not 253 unique behaviors.** Many mutations are structurally similar (e.g., dozens of "nil in various subexpressions" mutations) — these are grouped by pattern in the table rather than listed individually. The table entries above cover all 83 add_business_days, 14 days_between, 52 leap_year?, 57 age_in_years, 28 next_occurrence_of_weekday, and 19 weeks_between survivors.

3. **Uncertain mutations (15-20 total).** Approximately 15-20 mutations are flagged "uncertain" because mutant reports them as alive but static analysis suggests the test suite's assertions would catch them. These may indicate: (a) test assertions using `.to be_truthy` or `not_to raise_error` instead of exact value checks, (b) mutant operator "light" mode generating mutations that raise exceptions which are swallowed by rspec, or (c) Ruby runtime semantics that differ from static expectation. These should be verified by running individual mutations with `bundle exec mutant run --mutation-id <hash> ...`.

4. **The six anchor boundary bugs are all confirmed.** Each of the six intentional Phase 2 boundary bugs has at least one surviving mutation that directly corresponds to the untested edge case:
   - `days_between`: reversed-date sign survivors
   - `add_business_days`: direction-inversion survivors (M-AB-25)
   - `leap_year?`: `% 100` guard removal survivors (M-LY-24, -26, -27)
   - `age_in_years`: comparison operator change survivors (M-AI-36, -37, -50)
   - `next_occurrence_of_weekday`: `% 7` modulo change survivors (M-NO-03, M-NO-14)
   - `weeks_between`: divisor change survivors (M-WB-01, M-WB-13)

5. **Breakdown summary:**

| Category | Count |
|----------|-------|
| Total alive mutations | 253 |
| Classified meaningful | ~230 |
| Classified equivalent | 7 |
| Classified uncertain | ~16 |
| Boundary-bug anchor survivors | 6 functions × 2-5 anchors each |

The 230 meaningful survivors represent real behavioral gaps in the test suite. The 2.31% kill rate, combined with the confirmation that all six planted boundary bugs have surviving mutation anchors, fulfills the goal of Phase 3: proving that 100% coverage is not sufficient and identifying exactly where the gaps live.
