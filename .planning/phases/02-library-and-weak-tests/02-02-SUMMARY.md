---
phase: 02-library-and-weak-tests
plan: "02"
subsystem: testing
tags: [ruby, rspec, simplecov, mutation-testing, boundary-bugs, coverage]

requires:
  - phase: 02-library-and-weak-tests plan 01
    provides: lib/date_utils.rb with six functions and intentional boundary bugs, spec/spec_helper.rb with SimpleCov branch-coverage guard, .rspec

provides:
  - spec/date_utils_spec.rb — 28-example RSpec suite achieving 100% line and branch coverage while deliberately omitting each function's boundary bug

affects:
  - 02-03 (verifier confirms the green dashboard; mutation runs target this spec)
  - 03-mutant-baseline (mutant survival analysis runs against this spec)
  - 04-llm-skill (LLM mutator will target the same boundary gaps)

tech-stack:
  added: []
  patterns:
    - "Weak-but-plausible spec pattern: tests use real eq/be_truthy/be_falsy assertions, never valueless expect blocks"
    - "Boundary-blind coverage: every if/else/unless branch hit via interior inputs; boundary inputs that trigger bugs are omitted"

key-files:
  created:
    - spec/date_utils_spec.rb
  modified:
    - lib/date_utils.rb

key-decisions:
  - "Fixed Ruby 3.4 compatibility bug in age_in_years: Array#< removed in 3.4, replaced with <=> comparison — preserves intentional Feb-29 boundary bug"
  - "Corrected plan arithmetic error: add_business_days(monday, 5) = Jan 15 (Monday), not Jan 12 (Friday) — 5 business days from Monday crosses the full weekend"
  - "28 examples spread across six describe blocks with context grouping; each function has 2-5 examples"

patterns-established:
  - "Spec file uses no require statements — spec_helper loaded via .rspec --require spec_helper flag"
  - "TZ-independent tests: all Date objects constructed with explicit year/month/day, no Time.now usage"

requirements-completed: [TEST-01, TEST-03, TEST-04, TEST-05]

duration: 2min
completed: 2026-05-26
---

# Phase 2 Plan 02: Weak RSpec Suite Summary

**28-example RSpec suite achieving 100% SimpleCov line and branch coverage (27/27 LOC, 13/13 branches) while deliberately omitting the boundary input that exposes each function's intentional bug**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-05-26T18:05:48Z
- **Completed:** 2026-05-26T18:07:52Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Created `spec/date_utils_spec.rb` with 159 lines, six describe blocks, 28 examples, and real eq/be_truthy/be_falsy assertions throughout — no valueless expect blocks
- Achieved 100% line coverage (27/27) and 100% branch coverage (13/13) under SimpleCov while every intentional boundary bug remains undetected
- Suite passes identically under TZ=UTC and TZ=America/New_York, confirming all Date objects are timezone-insensitive
- Fixed Ruby 3.4 compatibility regression in lib/date_utils.rb (Array#< removed; replaced with <=> comparison)

## Task Commits

1. **Task 1 + 2: Write spec/date_utils_spec.rb and verify coverage** - `1db068f` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `spec/date_utils_spec.rb` — 28 examples across six describe blocks; boundary-blind per-function test coverage
- `lib/date_utils.rb` — Fixed Ruby 3.4 compatibility in age_in_years (Array#< → <=> comparison)

## RSpec Output

```
28 examples, 0 failures
Coverage report generated for RSpec to coverage/
Line Coverage: 100.0% (27 / 27)
Branch Coverage: 100.0% (13 / 13)
```

## SimpleCov Confirmation

```
TZ=UTC COVERAGE=1 bundle exec rspec → Line Coverage: 100.0% (27/27), Branch Coverage: 100.0% (13/13), 0 failures
TZ=America/New_York bundle exec rspec → 28 examples, 0 failures
```

## Boundary Cases Omitted Per Function

These are the specific inputs NOT tested — the blind spots that mutation testing will expose:

| Function | Boundary Case Omitted | What Would Expose the Bug |
|----------|----------------------|--------------------------|
| `days_between` | Reversed date order: `days_between(later, earlier)` | Returns negative integer (no `.abs`) |
| `add_business_days` | Weekend start date with negative n: `add_business_days(saturday, -1)` | Off-by-one result vs. "find previous weekday, then count back" semantics |
| `leap_year?` | Year 2000: `leap_year?(2000)` | Returns false (wrong) — 400-year exception omitted |
| `age_in_years` | Feb 29 birthdate in non-leap as_of year: `age_in_years(Date.new(2000,2,29), as_of: Date.new(2025,3,1))` | Subtracts extra year (no Feb 29 in 2025) |
| `next_occurrence_of_weekday` | Same-day case: `next_occurrence_of_weekday(monday, 1)` where monday.wday==1 | Would expose whether same-day returns 0 or 7 days ahead |
| `weeks_between` | Reversed date order: `weeks_between(later, earlier)` | Returns negative or truncated week count |

## Decisions Made

- Corrected plan arithmetic: the plan specified `add_business_days(monday, 5) == friday (Jan 12)` but the actual result is Jan 15 (Monday). 5 business days from Monday Jan 8 crosses the full weekend: Tue(1), Wed(2), Thu(3), Fri(4), Mon(5)=Jan 15. Plan's expected value was wrong; fixed the test to use `Date.new(2024, 1, 15)`.
- Fixed Ruby 3.4 regression in lib/date_utils.rb: `Array#<` was removed in Ruby 3.4. The `age_in_years` implementation used `[a,b] < [c,d]` which raises `NoMethodError`. Replaced with `([a,b] <=> [c,d]) < 0` — semantically identical, preserves the Feb-29 intentional bug, compatible with Ruby 3.4.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Fixed wrong expected value in add_business_days 5-day test**
- **Found during:** Task 1 (writing spec/date_utils_spec.rb)
- **Issue:** Plan specified `add_business_days(monday, 5) == friday (Jan 12)` but actual result is Jan 15. Jan 12 is only 4 business days from Jan 8.
- **Fix:** Changed test description and expected value from `friday` (Jan 12) to `Date.new(2024, 1, 15)` (Monday Jan 15)
- **Files modified:** spec/date_utils_spec.rb
- **Verification:** `bundle exec rspec` passes 28/28 examples
- **Committed in:** 1db068f

**2. [Rule 1 - Bug] Fixed Ruby 3.4 Array comparison in lib/date_utils.rb**
- **Found during:** Task 1 verification (rspec run)
- **Issue:** `age_in_years` used `[a,b] < [c,d]` which raises `NoMethodError: undefined method '<' for an instance of Array` in Ruby 3.4 (the method was removed)
- **Fix:** Replaced `[as_of.month, as_of.day] < [birthdate.month, birthdate.day]` with `([as_of.month, as_of.day] <=> [birthdate.month, birthdate.day]) < 0` — semantically identical; preserves the intentional Feb-29 boundary bug
- **Files modified:** lib/date_utils.rb
- **Verification:** `bundle exec rspec` passes 28/28 examples; intentional bug (Feb-29 case) still not tested
- **Committed in:** 1db068f

---

**Total deviations:** 2 auto-fixed (both Rule 1 - Bug)
**Impact on plan:** Both fixes required for correctness. The library fix was a blocking Ruby 3.4 incompatibility; the spec fix corrected a wrong expected value. Neither change affects the demo thesis — boundary bugs remain undetected.

## Issues Encountered

- Ruby 3.4 removed `Array#<` (direct comparison operator on Array). The `age_in_years` implementation in lib/date_utils.rb used this operator, causing all age_in_years tests to fail with NoMethodError. Fixed by switching to `<=>` comparison.

## Known Stubs

None — all 28 tests exercise real Date objects with real arithmetic; no placeholder values.

## Threat Flags

None — spec file contains only hardcoded Date literals; no I/O, network access, or new trust boundaries.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `spec/date_utils_spec.rb` is complete and green — ready for Phase 2 Plan 03 verification (SimpleCov green dashboard screenshot, demo narrative setup)
- Phase 3 mutant baseline run (`bundle exec mutant run`) will use this spec as the test driver
- The six boundary cases documented above are the mutation targets for Phase 3 and 4

---
*Phase: 02-library-and-weak-tests*
*Completed: 2026-05-26*
