# Mutation Tool Comparison: mutant vs llm-mutate

This document maps mutations from both tools against the same six DateUtils functions.
`mutant` applies exhaustive operator-based substitutions; `llm-mutate` generates semantically
meaningful mutations in the spirit of Meta's ACH research. Both tools run the same weak RSpec
test suite — 100% line and branch coverage, 28 tests — and both expose surviving mutations
that coverage metrics cannot see.

---

## Overview

| Function | mutant alive | mutant killed | LLM total | LLM survived | LLM killed | Divergences |
|---|---|---|---|---|---|---|
| days_between | 14 | 0 | 3 | 3 | 0 | 1 |
| add_business_days | 83 | 0 | 4 | 4 | 0 | 2 |
| leap_year? | 52 | 6 | 3 | 3 | 0 | 1 |
| age_in_years | 57 | 0 | 4 | 4 | 0 | 1 |
| next_occurrence_of_weekday | 28 | 0 | 3 | 3 | 0 | 1 |
| weeks_between | 19 | 0 | 3 | 3 | 0 | 2 |
| **Total** | **253** | **6** | **20** | **20** | **0** | **8** |

**Kill rate summary:** mutant killed 6 of 259 mutations (2.31%). All 6 kills are in `leap_year?`
because the test suite covers 2023, 2024, and 1900 — enough to exercise basic divisibility
checks. The LLM killed 0 of 20 mutations because all 20 fixture mutations target the same anchor
boundary bugs that the weak test suite misses. Both tools confirm the same verdict: green CI and
full coverage mask real behavioral gaps.

---

## Per-Function Analysis

### days_between

Both tools independently converge on the missing `.abs` anchor — the function always returns a
positive count for chronological inputs, but neither tool's mutation triggers a test failure
because no test ever passes reversed dates.

| Tool | Mutation ID | Description | Verdict |
|------|-------------|-------------|---------|
| mutant | M-DB-13 | Replaces `-` with `+` in the subtraction, producing addition of Julian day numbers instead of a date difference | alive |
| llm-mutate | LM-DB-03 | Adds `.abs` to the result, fixing the reversed-date sign bug — a change a reviewer would accept | survived |
| mutant | M-DB-08 | Drops `.to_i`, returns Rational instead of Integer | alive (equivalent) |
| llm-mutate | LM-DB-01 | Drops `.to_i`, same Rational-return behavior | survived (equivalent) |

**DIVERGENCE (days_between-1):** M-DB-13 changes the arithmetic sign entirely (addition instead
of subtraction), producing a wildly wrong result for any two chronological dates — a mutation so
gross it should be caught by any test checking a non-zero result. Its survival is uncertain and
may reflect a `module_function` self-resolution quirk. LM-DB-03, by contrast, adds the precise
fix a developer would write: `.abs` after the result. Both survive because tests never use
reversed dates, but they represent different failure modes — wrong arithmetic vs correct-looking
defensive code. Only the LLM mutation could fool a code reviewer.

**What both tools find:** the test suite's exclusive use of chronological date order leaves the
sign of the difference unverified, allowing a wide range of sign-altering or magnitude-changing
mutations to pass undetected.

---

### add_business_days

The most mutation-dense function (83 alive in mutant) also produces the clearest strategic
divergence between the two tools.

| Tool | Mutation ID | Description | Verdict |
|------|-------------|-------------|---------|
| mutant | M-AB-25 | Replaces `n.positive?` with `n.negative?`, inverting the direction logic so positive n moves backward | alive |
| llm-mutate | LM-AB-01 | Adds a weekend-normalizer before the loop: advances past any initial Saturday or Sunday before counting | survived |
| llm-mutate | LM-AB-02 | Rewrites `unless A || B` as `if !A && !B` (De Morgan rewrite — semantically identical) | survived (equivalent) |
| llm-mutate | LM-AB-03 | Replaces named Saturday/Sunday predicates with `[6, 0].include?(current.wday)` — semantically identical | survived (equivalent) |

**DIVERGENCE (add_business_days-1):** M-AB-25 uses a mechanical operator swap — the kind of
change no developer would intentionally write. It inverts direction globally so any forward
input produces a backward result. LM-AB-01 adds a realistic weekend-normalizer that any
developer might write as a defensive pre-condition. Both survive because all test start dates are
weekdays. But M-AB-25 would be caught immediately by any reviewer scanning the diff; LM-AB-01
looks like a legitimate improvement. The LLM mutation is qualitatively more dangerous.

**DIVERGENCE (add_business_days-2):** LM-AB-02 and LM-AB-03 are equivalent mutations in the
weekend-predicate expression area — De Morgan rewrites and numeric wday substitutions that change
form but not behavior. Mutant's equivalent mutations in this function cluster around the zero-guard
path (M-AB-03, M-AB-05, M-AB-09, M-AB-11, M-AB-13, M-AB-14), not around the weekend predicate.
This is a genuine strategic difference: the LLM generates equivalent mutations where the logic
is semantically rich (the weekend check), while mutant generates them where the control flow
happens to produce the same result for the tested input (the zero guard). Equivalent-mutant
noise from both tools is real, but it lives in different parts of the function.

**What both tools find:** the test suite's weekday-only start dates leave both the direction
logic and the weekend-start pre-condition path completely untested.

---

### leap_year?

The most pedagogically powerful function. Six mutant mutations are killed here — the only kills
in the entire run — because the 1900 test partially exercises the century guard. But the most
interesting mutations survive on both sides.

| Tool | Mutation ID | Description | Verdict |
|------|-------------|-------------|---------|
| mutant | M-LY-24 | Disables the `% 100` guard with `if nil`, removing the century-year exception entirely | alive |
| llm-mutate | LM-LY-01 | Adds the complete correct 400-year Gregorian exception (`&& (year % 400) != 0`) — the actual fix | survived |
| mutant | M-LY-26 | Drops `return false` in the century-guard body so century years fall through to return true | alive |
| llm-mutate | LM-LY-03 | Replaces `%` with `Numeric#remainder` for the 4-year check — semantically identical for positive years | survived (equivalent) |

**DIVERGENCE (leap_year?-1):** M-LY-24 removes the century guard outright — a clearly broken
change that would cause any century year to return true. But the test suite tests 1900, which
expects false, so mutations that make century years return true are killed. M-LY-24 is
specifically the `if nil` variant (guard never fires), which means year 2000 is never tested
in the `% 100` path at all. LM-LY-01 adds the precise Gregorian correction: the century guard
fires only when year is NOT divisible by 400. This mutation is the correct implementation — it
fixes the planted boundary bug. Yet it still survives because no test checks year 2000. This
is the most pedagogically powerful divergence in the comparison: an LLM-generated mutation that
is provably correct still goes undetected because the test suite cannot distinguish a correct
from an incorrect Gregorian calendar rule.

**What both tools find:** the missing year-2000 test is the critical gap. Any mutation that
changes behavior specifically for a century year divisible by 400 — whether it breaks the rule
or corrects it — will survive untested.

---

### age_in_years

The birthday-comparison logic generates the most complex surviving mutations. The anchor is the
Feb-29 birthdate case: the tuple `[as_of.month, as_of.day]` can never equal `[2, 29]` in a
non-leap year, making the year-adjustment comparison permanently unreachable for leap-day
birthdays.

| Tool | Mutation ID | Description | Verdict |
|------|-------------|-------------|---------|
| mutant | M-AI-36 | Replaces `< 0` with `.eql?(0)` — fires only when birthday is today, reversing the not-yet-occurred logic | alive (uncertain) |
| mutant | M-AI-37 | Replaces `< 0` with `== 0` — same effect as M-AI-36 | alive (uncertain) |
| llm-mutate | LM-AI-01 | Clamps birthdate day to `[birthdate.day, 28].min` in the tuple comparison, normalizing Feb 29 to Feb 28 | survived |
| llm-mutate | LM-AI-02 | Replaces `< 0` with `.negative?` — semantically identical | survived (equivalent) |
| llm-mutate | LM-AI-03 | Rewrites `years -= 1 if` as `years = years - 1 if` — syntactic sugar expansion, semantically identical | survived (equivalent) |

**DIVERGENCE (age_in_years-1):** M-AI-36 and M-AI-37 apply mechanical operator swaps to the
threshold comparison — changing `< 0` to `.eql?(0)` or `== 0`. These are the kind of mutations
a fuzzer or operator-based tool naturally generates. LM-AI-01 adds the specific Feb-29
normalization a developer might genuinely write to handle the leap-year edge case: clamping the
birthdate day to 28 when computing the month/day tuple. This is a plausible-looking defensive
fix, and it directly corresponds to boundary bug 4. The mutant mutations are mechanical;
the LLM mutation is idiomatic and reviewable. Neither is caught because no test uses a Feb-29
birthdate.

**What both tools find:** the month/day tuple comparison is never given a leap-day birthdate,
leaving the entire normalization path — whether correct or incorrect — permanently untested.

---

### next_occurrence_of_weekday

A compact function with a single load-bearing modulo operation. Both tools converge on the same
boundary: the `% 7` is needed for the same-day case (result should be 0) and for negative raw
differences, but every test uses a strictly forward target weekday.

| Tool | Mutation ID | Description | Verdict |
|------|-------------|-------------|---------|
| mutant | M-NO-03 | Drops `% 7` entirely — raw difference returned, which is negative when target < current weekday | alive |
| llm-mutate | LM-NO-01 | Adds explicit same-day override: `days_ahead = 7 if days_ahead.zero?` after the modulo line | survived |
| llm-mutate | LM-NO-03 | Adds 7 before the modulo: `(7 + weekday - from_date.wday) % 7` — mathematically equivalent | survived (equivalent) |

**DIVERGENCE (next_occurrence_of_weekday-1):** M-NO-03 removes the modulo entirely — exposing the
underlying boundary by producing an unmodified integer difference that would be negative for
any same-day-or-earlier target. LM-NO-01 handles the same boundary at a higher abstraction level:
it adds an explicit same-day handler that returns 7 instead of 0 when the target weekday equals
from_date.wday. These two mutations are two different expressions of the same underlying gap, but
M-NO-03 is a mechanical deletion while LM-NO-01 is a semantic patch that looks like a deliberate
design choice. A code reviewer would flag M-NO-03 on sight; LM-NO-01 might pass review as a
valid business-logic clarification.

**What both tools find:** no test calls `next_occurrence_of_weekday` with a start date already on
the target weekday, leaving the same-day and backward-wrap cases completely untested.

---

### weeks_between

The simplest function in the library: delegates to `days_between` and divides by 7. Both tools
expose the inherited sign gap, but through very different mutations.

| Tool | Mutation ID | Description | Verdict |
|------|-------------|-------------|---------|
| mutant | M-WB-01 | Drops `/ 7` entirely — returns raw day count instead of week count | alive (uncertain) |
| llm-mutate | LM-WB-03 | Adds `.abs` to the `days_between` result before dividing — the actual missing fix | survived |
| llm-mutate | LM-WB-01 | Changes `/ 7` to `/ 7.0` — float division; `14.0 / 7.0 = 2.0`, and `2.0 == 2` passes `eq(2)` | survived |

**DIVERGENCE (weeks_between-1):** M-WB-01 removes the division entirely — a catastrophic mutation
that should be caught by any test checking that 14 days returns 2 weeks rather than 14. Its
survival is uncertain and may reflect a `module_function` self-resolution quirk where `self / 7`
resolves differently than expected. LM-WB-03 adds `.abs` to the days_between result — the actual
fix for the reversed-date bug, and exactly the change a careful developer would add after reading
the code. Both survive, but for completely different (and instructive) reasons: M-WB-01's survival
is a tooling artifact, LM-WB-03's survival is a genuine test gap.

**DIVERGENCE (weeks_between-2):** LM-WB-01 changes integer division to float division (`/ 7` to
`/ 7.0`). Ruby's Numeric equality means `2.0 == 2` is true, so every `eq(n)` assertion passes
even though the return type changed from Integer to Float. This is a mutation with no direct mutant
counterpart — mutant's division mutations are catastrophic (remove it, multiply instead, use a wrong
integer divisor) rather than type-shifting. The LLM finds a subtle coercion mutation that would
pass any code review and silently changes the API contract. No operator-based tool generates this
class of mutation because it requires semantic understanding of Ruby's numeric type system.

**What both tools find:** no test uses reversed dates for either `days_between` or `weeks_between`,
and no test checks the return type — leaving sign, magnitude, and type mutations all alive.

---

## Divergences Summary

Three divergences are the most narrative-rich for a demo presentation.

### Divergence 1: Operator mutation vs semantic patch (add_business_days)

mutant's M-AB-25 inverts the direction flag with a mechanical operator swap — replacing
`n.positive?` with `n.negative?`. This is the kind of mutation a linter or human reviewer would
catch on first glance: nobody writes a direction predicate that fires for negative numbers when
positive behavior is wanted. LLM's LM-AB-01 adds a realistic weekend-normalizer a developer might
actually write as a defensive pre-condition: advancing past any initial Saturday or Sunday before
the main loop begins. Both survive because all tests use weekday start dates, but only the LLM
mutation could pass a code review. This is the core argument for LLM-driven mutation testing in
an AI-assisted era: generated code changes look like generated code, and mechanical operator
mutations are too obviously wrong to simulate them.

### Divergence 2: Catastrophic removal vs targeted fix (weeks_between)

mutant's M-WB-01 removes the `/ 7` entirely — a mutation so drastic that returning raw day counts
instead of weeks should be caught by the most minimal test imaginable. Its survival is uncertain
and likely reflects a Ruby `module_function` resolution quirk rather than a genuine test gap. LLM's
LM-WB-03 adds `.abs` to the days_between result before dividing — precisely the fix a developer
would apply after noticing the reversed-date gap, and a change that would be accepted in any code
review. Tests cannot catch either, but for completely different reasons: M-WB-01 survives due to
possible tooling behavior, LM-WB-03 survives because no test exercises reversed date order. The
LLM mutation is the actionable signal; the mutant mutation is the tooling artifact.

### Divergence 3: Bug-fix mutation that still survives (leap_year?)

mutant's M-LY-24 removes the century guard entirely using `if nil` — the guard never fires, so
century years like 2000 are no longer excluded from the leap-year rule. LLM's LM-LY-01 adds the
complete correct Gregorian 400-year exception — `return false if (year % 100).zero? && (year % 400) != 0`.
This mutation is not a bug: it is the actual fix for the planted boundary bug in the implementation.
Yet both survive. A test suite that tested year 2000 would kill LM-LY-01 (because 2000 would now
correctly return true) and also kill M-LY-24 (because 2000 would return true on a century year
without the guard). Coverage metrics and mutant alike are blind to whether your test suite validates
the complete Gregorian calendar rule — only a test for year 2000 can distinguish them.

---

## References

Full mutant classification, including all 253 surviving mutations with equivalence verdicts and
boundary-bug anchor analysis, is in `docs/mutant-audit.md`.

LLM mutation detail — original lines, mutated lines, anchor-bug flags, and expected verdicts for
all 20 fixture mutations — is in `.claude/skills/llm-mutate/fixtures/canonical.json`.
