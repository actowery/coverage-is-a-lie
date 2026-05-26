# LLM Mutation Report — Replay Mode

**Fixture:** .claude/skills/llm-mutate/fixtures/canonical.json
**Mode:** --replay (deterministic)
**Total mutations:** 20
**Invalid (ruby -c rejected):** 0
**Killed:** 0
**Survived:** 20
**Mutation score:** 0/20 (0.0%)

---

## Per-Function Breakdown

| Function | Total | Killed | Survived |
|----------|-------|--------|----------|
| days_between | 3 | 0 | 3 |
| add_business_days | 4 | 0 | 4 |
| leap_year? | 3 | 0 | 3 |
| age_in_years | 4 | 0 | 4 |
| next_occurrence_of_weekday | 3 | 0 | 3 |
| weeks_between | 3 | 0 | 3 |

---

## Mutation Details

### days_between

| ID | Description | Verdict | Anchor Bug |
|----|-------------|---------|------------|
| LM-DB-01 | Drops .to_i — returns a Rational instead of an integer. Ruby's eq(7) assertion still passes because Rational(7,1) == 7, but downstream integer division in weeks_between breaks silently for non-exact-multiple inputs. | SURVIVED | no |
| LM-DB-02 | Replaces .to_i with Kernel#Integer() — for Date subtraction which returns a Rational, Integer(Rational(7,1)) and Rational(7,1).to_i are identical. A semantically equivalent refactor that no test will ever catch. | SURVIVED | no |
| LM-DB-03 | Adds .abs to the result — this is the Phase 2 anchor boundary bug pattern made explicit. A reviewer might think it fixes the reversed-date bug; the fix would in fact be correct. But the weak test suite never passes reversed dates, so the mutation (whether a bug or a fix) survives undetected. | SURVIVED | yes |

### add_business_days

| ID | Description | Verdict | Anchor Bug |
|----|-------------|---------|------------|
| LM-AB-01 | Advances past any initial weekend before the loop begins — a careless fix attempt for weekend-start inputs that changes behavior only when the start date is Saturday or Sunday. All test start dates are weekdays (Monday, Thursday, Friday), so this mutation survives. This is the Phase 2 anchor boundary bug pattern. | SURVIVED | yes |
| LM-AB-02 | Rewrites the weekend guard using De Morgan's law — unless A \|\| B becomes if !A && !B. These forms are logically equivalent, so the mutation is undetectable by any test regardless of its inputs. | SURVIVED | no |
| LM-AB-03 | Replaces the named Saturday/Sunday predicates with a numeric wday inclusion check — [6, 0].include?(current.wday) is semantically identical to current.saturday? \|\| current.sunday? in all cases. Another equivalent mutation that survives all tests. | SURVIVED | no |
| LM-AB-04 | Converts the loop bound to Float — uses n.abs.to_f instead of n.abs in the while condition. Integer < Float comparison is valid Ruby and produces identical results for all integer step counts. This is a semantically equivalent mutation that no test will ever catch. | SURVIVED | no |

### leap_year?

| ID | Description | Verdict | Anchor Bug |
|----|-------------|---------|------------|
| LM-LY-01 | Adds the correct 400-year Gregorian exception — replaces the blunt 100-year guard with the precise rule that fires for century years NOT divisible by 400. Year 2000 now correctly returns true, but no test ever checks year 2000, so this bug-fix mutation survives undetected. | SURVIVED | yes |
| LM-LY-02 | Adds a spurious post-2100 guard — changes the final return from true to year <= 2100. For all test years (2019, 2020, 2023, 2024, 1900) the result is unchanged. No test uses a year after 2100, so this survives. | SURVIVED | no |
| LM-LY-03 | Replaces modulo with Numeric#remainder for the 4-year divisibility check — for positive year arguments, Integer#remainder and % are identical. This is a semantically equivalent mutation that demonstrates equivalent mutant noise in the report. | SURVIVED | no |

### age_in_years

| ID | Description | Verdict | Anchor Bug |
|----|-------------|---------|------------|
| LM-AI-01 | Clamps birthdate day to 28 in the month/day tuple comparison — normalizes Feb 29 birthdays to Feb 28, which would fix the over-subtraction for leap-day birthdays in non-leap years. No test uses a Feb 29 birthdate, so this bug-fix mutation survives. | SURVIVED | yes |
| LM-AI-02 | Replaces the explicit < 0 comparison with the Integer#negative? predicate — semantically identical for the result of a <=> comparison. This equivalent mutation demonstrates that superficially different code can be functionally indistinguishable. | SURVIVED | no |
| LM-AI-03 | Rewrites the compound assignment as an explicit subtraction — years = years - 1 if instead of years -= 1 if. Ruby's -= is syntactic sugar for the explicit form; behavior is identical across all test inputs. | SURVIVED | no |
| LM-AI-04 | Adds a redundant .to_i call on as_of.year — Date#year already returns an Integer, so .to_i is a no-op. Another equivalent mutation that survives all tests, illustrating the equivalent-mutant problem. | SURVIVED | no |

### next_occurrence_of_weekday

| ID | Description | Verdict | Anchor Bug |
|----|-------------|---------|------------|
| LM-NO-01 | Forces same-day input to return 7 days ahead instead of 0 — adds days_ahead = 7 if days_ahead.zero? after the modulo line. This is the Phase 2 intentional same-day boundary bug made explicit. No test ever calls next_occurrence_of_weekday with from_date already on the target weekday, so the mutation survives. | SURVIVED | yes |
| LM-NO-02 | Adds a redundant .to_i call on from_date.wday — Date#wday already returns an Integer. Semantically equivalent, survives all tests. Demonstrates that trivial syntactic changes can produce surviving mutants in a coverage-only CI pipeline. | SURVIVED | no |
| LM-NO-03 | Adds 7 before the modulo operation — (7 + weekday - from_date.wday) % 7 is mathematically equivalent to (weekday - from_date.wday) % 7 because Ruby's modulo is always non-negative. A careless refactor that changes nothing observable. | SURVIVED | no |

### weeks_between

| ID | Description | Verdict | Anchor Bug |
|----|-------------|---------|------------|
| LM-WB-01 | Converts integer division to float division — uses / 7.0 instead of / 7. In Ruby, 14.0 / 7.0 = 2.0, and 2.0 == 2 is true (Numeric equality), so all eq(n) assertions still pass. The mutation survives even though the return type changes from Integer to Float. | SURVIVED | no |
| LM-WB-02 | Inlines the date subtraction instead of delegating to days_between — computes (end_date - start_date).to_i / 7 directly. Bypasses days_between's missing .abs, but tests only use chronological date order, so the two implementations agree for all tested inputs. | SURVIVED | no |
| LM-WB-03 | Adds .abs to the days_between result before dividing — would fix the negative-week-count bug for reversed date order, but no test ever passes reversed dates to weeks_between. Mirrors the LM-DB-02 pattern: the bug fix itself survives undetected. | SURVIVED | yes |

---

## Diff — Survived Mutations

### LM-DB-01 — days_between

**Description:** Drops .to_i — returns a Rational instead of an integer. Ruby's eq(7) assertion still passes because Rational(7,1) == 7, but downstream integer division in weeks_between breaks silently for non-exact-multiple inputs.

**Diff:**
```
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
-     (end_date - start_date).to_i
+     (end_date - start_date)
```

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** no

---

### LM-DB-02 — days_between

**Description:** Replaces .to_i with Kernel#Integer() — for Date subtraction which returns a Rational, Integer(Rational(7,1)) and Rational(7,1).to_i are identical. A semantically equivalent refactor that no test will ever catch.

**Diff:**
```
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
-     (end_date - start_date).to_i
+     Integer(end_date - start_date)
```

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** no

---

### LM-DB-03 — days_between

**Description:** Adds .abs to the result — this is the Phase 2 anchor boundary bug pattern made explicit. A reviewer might think it fixes the reversed-date bug; the fix would in fact be correct. But the weak test suite never passes reversed dates, so the mutation (whether a bug or a fix) survives undetected.

**Diff:**
```
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
-     (end_date - start_date).to_i
+     (end_date - start_date).to_i.abs
```

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** yes

---

### LM-AB-01 — add_business_days

**Description:** Advances past any initial weekend before the loop begins — a careless fix attempt for weekend-start inputs that changes behavior only when the start date is Saturday or Sunday. All test start dates are weekdays (Monday, Thursday, Friday), so this mutation survives. This is the Phase 2 anchor boundary bug pattern.

**Diff:**
```
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
-     current = date
+     current = date.saturday? ? date + 1 : (date.sunday? ? date + 2 : date)
```

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** yes

---

### LM-AB-02 — add_business_days

**Description:** Rewrites the weekend guard using De Morgan's law — unless A || B becomes if !A && !B. These forms are logically equivalent, so the mutation is undetectable by any test regardless of its inputs.

**Diff:**
```
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
-       steps += 1 unless current.saturday? || current.sunday?
+       steps += 1 if !current.saturday? && !current.sunday?
```

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** no

---

### LM-AB-03 — add_business_days

**Description:** Replaces the named Saturday/Sunday predicates with a numeric wday inclusion check — [6, 0].include?(current.wday) is semantically identical to current.saturday? || current.sunday? in all cases. Another equivalent mutation that survives all tests.

**Diff:**
```
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
-       steps += 1 unless current.saturday? || current.sunday?
+       steps += 1 unless [6, 0].include?(current.wday)
```

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** no

---

### LM-AB-04 — add_business_days

**Description:** Converts the loop bound to Float — uses n.abs.to_f instead of n.abs in the while condition. Integer < Float comparison is valid Ruby and produces identical results for all integer step counts. This is a semantically equivalent mutation that no test will ever catch.

**Diff:**
```
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
-     while steps < n.abs
+     while steps < n.abs.to_f
```

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** no

---

### LM-LY-01 — leap_year?

**Description:** Adds the correct 400-year Gregorian exception — replaces the blunt 100-year guard with the precise rule that fires for century years NOT divisible by 400. Year 2000 now correctly returns true, but no test ever checks year 2000, so this bug-fix mutation survives undetected.

**Diff:**
```
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
-     return false if (year % 100).zero?
+     return false if (year % 100).zero? && (year % 400) != 0
```

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** yes

---

### LM-LY-02 — leap_year?

**Description:** Adds a spurious post-2100 guard — changes the final return from true to year <= 2100. For all test years (2019, 2020, 2023, 2024, 1900) the result is unchanged. No test uses a year after 2100, so this survives.

**Diff:**
```
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
-     true
+     year <= 2100
```

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** no

---

### LM-LY-03 — leap_year?

**Description:** Replaces modulo with Numeric#remainder for the 4-year divisibility check — for positive year arguments, Integer#remainder and % are identical. This is a semantically equivalent mutation that demonstrates equivalent mutant noise in the report.

**Diff:**
```
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
-     return false unless (year % 4).zero?
+     return false unless year.remainder(4).zero?
```

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** no

---

### LM-AI-01 — age_in_years

**Description:** Clamps birthdate day to 28 in the month/day tuple comparison — normalizes Feb 29 birthdays to Feb 28, which would fix the over-subtraction for leap-day birthdays in non-leap years. No test uses a Feb 29 birthdate, so this bug-fix mutation survives.

**Diff:**
```
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
-     years -= 1 if ([as_of.month, as_of.day] <=> [birthdate.month, birthdate.day]) < 0
+     years -= 1 if ([as_of.month, as_of.day] <=> [birthdate.month, [birthdate.day, 28].min]) < 0
```

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** yes

---

### LM-AI-02 — age_in_years

**Description:** Replaces the explicit < 0 comparison with the Integer#negative? predicate — semantically identical for the result of a <=> comparison. This equivalent mutation demonstrates that superficially different code can be functionally indistinguishable.

**Diff:**
```
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
-     years -= 1 if ([as_of.month, as_of.day] <=> [birthdate.month, birthdate.day]) < 0
+     years -= 1 if ([as_of.month, as_of.day] <=> [birthdate.month, birthdate.day]).negative?
```

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** no

---

### LM-AI-03 — age_in_years

**Description:** Rewrites the compound assignment as an explicit subtraction — years = years - 1 if instead of years -= 1 if. Ruby's -= is syntactic sugar for the explicit form; behavior is identical across all test inputs.

**Diff:**
```
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
-     years -= 1 if ([as_of.month, as_of.day] <=> [birthdate.month, birthdate.day]) < 0
+     years = years - 1 if ([as_of.month, as_of.day] <=> [birthdate.month, birthdate.day]) < 0
```

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** no

---

### LM-AI-04 — age_in_years

**Description:** Adds a redundant .to_i call on as_of.year — Date#year already returns an Integer, so .to_i is a no-op. Another equivalent mutation that survives all tests, illustrating the equivalent-mutant problem.

**Diff:**
```
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
-     years = as_of.year - birthdate.year
+     years = as_of.year.to_i - birthdate.year
```

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** no

---

### LM-NO-01 — next_occurrence_of_weekday

**Description:** Forces same-day input to return 7 days ahead instead of 0 — adds days_ahead = 7 if days_ahead.zero? after the modulo line. This is the Phase 2 intentional same-day boundary bug made explicit. No test ever calls next_occurrence_of_weekday with from_date already on the target weekday, so the mutation survives.

**Diff:**
```
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
-     days_ahead = (weekday - from_date.wday) % 7
+     days_ahead = (weekday - from_date.wday) % 7; days_ahead = 7 if days_ahead.zero?
```

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** yes

---

### LM-NO-02 — next_occurrence_of_weekday

**Description:** Adds a redundant .to_i call on from_date.wday — Date#wday already returns an Integer. Semantically equivalent, survives all tests. Demonstrates that trivial syntactic changes can produce surviving mutants in a coverage-only CI pipeline.

**Diff:**
```
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
-     days_ahead = (weekday - from_date.wday) % 7
+     days_ahead = (weekday - from_date.wday.to_i) % 7
```

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** no

---

### LM-NO-03 — next_occurrence_of_weekday

**Description:** Adds 7 before the modulo operation — (7 + weekday - from_date.wday) % 7 is mathematically equivalent to (weekday - from_date.wday) % 7 because Ruby's modulo is always non-negative. A careless refactor that changes nothing observable.

**Diff:**
```
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
-     days_ahead = (weekday - from_date.wday) % 7
+     days_ahead = (7 + weekday - from_date.wday) % 7
```

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** no

---

### LM-WB-01 — weeks_between

**Description:** Converts integer division to float division — uses / 7.0 instead of / 7. In Ruby, 14.0 / 7.0 = 2.0, and 2.0 == 2 is true (Numeric equality), so all eq(n) assertions still pass. The mutation survives even though the return type changes from Integer to Float.

**Diff:**
```
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
-     days_between(start_date, end_date) / 7
+     days_between(start_date, end_date) / 7.0
```

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** no

---

### LM-WB-02 — weeks_between

**Description:** Inlines the date subtraction instead of delegating to days_between — computes (end_date - start_date).to_i / 7 directly. Bypasses days_between's missing .abs, but tests only use chronological date order, so the two implementations agree for all tested inputs.

**Diff:**
```
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
-     days_between(start_date, end_date) / 7
+     (end_date - start_date).to_i / 7
```

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** no

---

### LM-WB-03 — weeks_between

**Description:** Adds .abs to the days_between result before dividing — would fix the negative-week-count bug for reversed date order, but no test ever passes reversed dates to weeks_between. Mirrors the LM-DB-02 pattern: the bug fix itself survives undetected.

**Diff:**
```
--- a/lib/date_utils.rb
+++ b/lib/date_utils.rb
-     days_between(start_date, end_date) / 7
+     days_between(start_date, end_date).abs / 7
```

**Verdict:** SURVIVED — this mutation was NOT caught by the test suite.
**Anchor bug:** yes

---

## Estimated Cost

Mode: --replay (no LLM calls made during replay)
Fixture generation cost: N/A — fixture is hand-curated (Phase 4 plan 02)
RSpec runs: 20 executions of bundle exec rspec spec/date_utils_spec.rb

*Note: --generate mode logs estimated token cost. --replay mode has no LLM token usage.*
