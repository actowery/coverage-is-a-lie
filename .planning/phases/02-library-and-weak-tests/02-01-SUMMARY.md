---
phase: 02-library-and-weak-tests
plan: "01"
subsystem: testing
tags: [ruby, date-utils, simplecov, rspec, mutation-testing, boundary-bugs]

requires:
  - phase: 01-repo-foundation
    provides: Gemfile with pinned rspec/simplecov/mutant gems, .ruby-version, bundled Gemfile.lock

provides:
  - lib/date_utils.rb — six DateUtils module_function methods with intentional boundary bugs
  - spec/spec_helper.rb — SimpleCov initialization inside ENV["COVERAGE"] guard, branch coverage, 100% minimum
  - .rspec — --color and --require spec_helper flags

affects:
  - 02-02 (weak test suite needs this library and spec_helper as the base)
  - 03-mutant-baseline (mutant runs against this library)
  - 04-llm-skill (LLM mutator targets this library)

tech-stack:
  added: []
  patterns:
    - "ENV['COVERAGE'] guard around SimpleCov.start — prevents SimpleCov loading during mutant runs"
    - "module_function pattern — methods callable as DateUtils.method_name (class-level) without explicit self"
    - "Intentional boundary bugs documented inline in source — bugs are the demo payload, not defects to fix"

key-files:
  created:
    - lib/date_utils.rb
    - spec/spec_helper.rb
    - .rspec
  modified: []

key-decisions:
  - "Intentional bugs implemented exactly per plan spec — do not fix; they are the mutation testing demo payload"
  - "ENV['COVERAGE'] guard established in spec_helper from day one (Phase 3 MUT-04 requirement)"
  - "module_function used instead of def self.method — idiomatic for pure-utility Ruby modules"
  - "leap_year? bug targets year 2000 (omits 400-year exception) — test suite uses 2024/2023/1900, missing 2000"

patterns-established:
  - "Boundary bugs are annotated in source comments for clarity during demo walkthrough"
  - "Pure stdlib: only require 'date' — no external gem dependencies in the library"

requirements-completed: [LIB-01, LIB-02, LIB-03, LIB-04, LIB-05, LIB-06, LIB-07, TEST-02]

duration: 8min
completed: 2026-05-26
---

# Phase 2 Plan 01: DateUtils Library and Test Infrastructure Summary

**Pure-Ruby DateUtils module with six functions carrying intentional boundary bugs, plus SimpleCov branch-coverage infrastructure guarded by ENV["COVERAGE"] for mutant compatibility**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-05-26T00:00:00Z
- **Completed:** 2026-05-26T00:08:00Z
- **Tasks:** 2
- **Files modified:** 3

## Accomplishments

- Created `lib/date_utils.rb` with six `module_function` methods, each containing exactly one intentional boundary bug invisible to happy-path tests
- Created `spec/spec_helper.rb` with SimpleCov configured for line + branch coverage at 100% minimum, guarded behind `ENV["COVERAGE"]` to prevent SimpleCov loading during mutant runs (Phase 3 MUT-04 compatibility)
- Created `.rspec` with `--color` and `--require spec_helper` so SimpleCov initializes before any spec file loads

## Task Commits

1. **Task 1: Create spec/spec_helper.rb and .rspec** - `9686451` (feat)
2. **Task 2: Write lib/date_utils.rb with six functions and intentional boundary bugs** - `33ac028` (feat)

**Plan metadata:** (docs commit follows)

## Files Created/Modified

- `lib/date_utils.rb` — Six DateUtils class methods, pure Ruby (require "date" only), each with one intentional boundary bug
- `spec/spec_helper.rb` — SimpleCov initialization inside `ENV["COVERAGE"]` guard; branch + line coverage at 100% minimum; `add_filter "/spec/"` to scope coverage gate to lib/
- `.rspec` — `--color` and `--require spec_helper` on separate lines

## Intentional Boundary Bugs (by function)

These are INTENTIONAL — the demo thesis depends on them surviving the weak test suite.

| Function | Bug | What Tests Miss |
|----------|-----|-----------------|
| `days_between` | No `.abs` — returns negative when `start > end` | Tests only call with chronological-order dates |
| `add_business_days` | Step-then-check loop is off-by-one when `date` is a weekend and `n` is negative | Tests only use weekday start dates and positive `n` |
| `leap_year?` | Omits 400-year exception — `year 2000` returns `false` (wrong) | Tests use 2024 (→ true), 2023 (→ false), 1900 (→ false); never 2000 |
| `age_in_years` | Naive `[month, day]` tuple comparison subtracts extra year for Feb 29 birthdays in non-leap years | Tests use non-leap-day birthdates only |
| `next_occurrence_of_weekday` | No branch for same-day case — `days_ahead = 0` silently falls out of modulo; a "strictly after" mutation survives | Tests never pass `from_date.wday == weekday` |
| `weeks_between` | Delegates to `days_between` without `.abs` — reversed dates produce negative week counts | Tests only use chronological order with exact 7-day multiples |

## SimpleCov Configuration Choices

```ruby
if ENV["COVERAGE"]
  require "simplecov"
  SimpleCov.start do
    enable_coverage :branch
    minimum_coverage line: 100, branch: 100
    add_filter "/spec/"
  end
end
```

- **ENV["COVERAGE"] guard:** Prevents SimpleCov from loading during `bundle exec mutant run` (Phase 3 MUT-04 requirement — established from day one to avoid architectural change later)
- **enable_coverage :branch:** Enables SimpleCov branch tracking so the demo shows 100% _branch_ coverage, not just line coverage
- **minimum_coverage line: 100, branch: 100:** CI fails unless tests touch every line and every branch in lib/ — the demo's "green dashboard" guarantee
- **add_filter "/spec/":** Scopes the 100% minimum to lib/ only; spec files are not subject to coverage measurement

## Verification Results

```
ruby -c lib/date_utils.rb  → Syntax OK
ruby -c spec/spec_helper.rb  → Syntax OK
cat .rspec  → --color / --require spec_helper
grep "module_function" lib/date_utils.rb  → matches
grep "SimpleCov.start" spec/spec_helper.rb  → matches
grep 'ENV["COVERAGE"]' spec/spec_helper.rb  → matches
grep "enable_coverage :branch" spec/spec_helper.rb  → matches
grep "minimum_coverage" spec/spec_helper.rb  → matches
DateUtils.days_between(Date.new(2024,1,1), Date.new(2024,1,8))  → 7 ✓
```

## Decisions Made

- Implemented all six intentional bugs exactly as described in the plan spec — no "fixing" of boundary conditions
- `ENV["COVERAGE"]` guard placed from day one (not retrofitted in Phase 3) to avoid architectural drift
- `module_function` chosen over `def self.method` — idiomatic for a pure-utility module; callable as `DateUtils.method_name` without requiring include
- No `.rspec` `--format documentation` flag per plan spec — keeps output compact for demo recording

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## Known Stubs

None — all six functions are fully implemented with the intentional bugs in place.

## Threat Flags

None — no new security-relevant surface introduced. Library is pure logic with no I/O, no state, no network access. Trust boundary analysis from plan threat model accepted as-is (T-02-01, T-02-02, T-02-SC).

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- `lib/date_utils.rb` and `spec/spec_helper.rb` are ready for Plan 02-02 (weak test suite)
- Plan 02-02 must write specs that exercise every line and branch in `lib/date_utils.rb` while deliberately omitting the boundary cases documented above
- `bundle exec rspec` will require the spec files from 02-02 before any green run is possible (no specs exist yet)
- Phase 3 mutant integration can load `lib/date_utils.rb` directly; `ENV["COVERAGE"]` guard is already in place

---

## Self-Check

### Files exist:
- `lib/date_utils.rb`: FOUND
- `spec/spec_helper.rb`: FOUND
- `.rspec`: FOUND

### Commits exist:
- `9686451` (Task 1 — spec/spec_helper.rb + .rspec): FOUND
- `33ac028` (Task 2 — lib/date_utils.rb): FOUND

## Self-Check: PASSED

---
*Phase: 02-library-and-weak-tests*
*Completed: 2026-05-26*
