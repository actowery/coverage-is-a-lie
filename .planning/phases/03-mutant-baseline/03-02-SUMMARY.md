---
phase: 03-mutant-baseline
plan: "02"
subsystem: mutation-testing
tags: [mutant, rspec, mutation-testing, date-utils, kill-rate, report]
dependency_graph:
  requires:
    - phase: 03-mutant-baseline/03-01
      provides: Timeout guard in spec_helper, rake mutant task, README Act 1 docs
    - phase: 02-library-and-weak-tests/02-01
      provides: DateUtils library with six intentional boundary bugs
    - phase: 02-library-and-weak-tests/02-02
      provides: Weak RSpec suite with 100% line+branch coverage
  provides:
    - tmp/mutant-report.txt — raw mutant output with 2.31% kill rate and 253 alive-mutation diffs
    - .mutant.yml with includes/requires configured for DateUtils subject discovery
  affects: [03-03-audit, 05-demo-branch]
tech-stack:
  added: []
  patterns:
    - ".mutant.yml includes/requires config pattern for mutant subject discovery"
    - "Force-add gitignored report artifact (git add -f) when plan explicitly requires it for downstream phases"
key-files:
  created:
    - tmp/mutant-report.txt
  modified:
    - .mutant.yml
key-decisions:
  - "Added includes/requires to .mutant.yml (Rule 2 auto-fix) — original file had only usage:opensource, causing 0 subjects found"
  - "Force-added tmp/mutant-report.txt despite /tmp/ being gitignored — plan explicitly requires it for Plan 03 audit and Phase 5 demo commits"
  - "Rakefile and README tee command work correctly without --include/--require CLI flags since .mutant.yml now provides them"
patterns-established:
  - "mutant subject discovery requires either --include lib --require date_utils CLI flags or equivalent .mutant.yml config"
requirements-completed: [MUT-01, MUT-02]
duration: 8min
completed: 2026-05-26
---

# Phase 03 Plan 02: Run Mutant Baseline and Capture Report Summary

**mutant 0.16.3 run against DateUtils: 259 mutations evaluated, 253 alive, 6 killed — 2.31% kill rate proves 100%-covered test suite is nearly mutation-blind**

## Performance

- **Duration:** ~8 min
- **Started:** 2026-05-26T18:25:00Z
- **Completed:** 2026-05-26T18:33:00Z
- **Tasks:** 2
- **Files modified:** 2

## Accomplishments

- Fixed `.mutant.yml` (missing `includes`/`requires` config) so mutant discovers all 6 DateUtils subjects instead of reporting 0 subjects/0 mutations
- Ran `bundle exec mutant run --integration rspec DateUtils` with 600-second timeout — completed in under 2 seconds with all 259 mutations evaluated
- Captured full output to `tmp/mutant-report.txt` (141 lines, force-added past gitignore) containing kill rate, alive counts, and representative diff per function
- Verified all 6 DateUtils functions appear in the report with alive mutation indicators

## Kill Rate Summary

| Metric | Value |
|--------|-------|
| Total mutations | 259 |
| Killed | 6 |
| Alive | 253 |
| Kill rate (Coverage) | 2.31% |
| Subjects | 6 |
| Tests | 28 |

## Alive Mutations by Function

| Function | Alive | First Survivor Example |
|----------|-------|------------------------|
| `add_business_days` | 83 | `n.zero?` -> `self.zero?` survives |
| `age_in_years` | 57 | Entire body replaced with `super` survives |
| `leap_year?` | 52 | Entire body replaced with `raise` survives |
| `next_occurrence_of_weekday` | 28 | Entire body replaced with `raise` survives |
| `weeks_between` | 19 | `days_between(…) / 7` -> `days_between(…)` survives |
| `days_between` | 14 | Body replaced with `raise` survives |

The kill rate of 2.31% is the Act 1 evidence — a test suite with 100% line and branch coverage kills fewer than 1 in 40 mutations. The surviving mutations are not noise; they represent real behavioral gaps including the intentional boundary bugs planted in Phase 2.

## Task Commits

1. **Task 1: Create tmp/ directory and run mutant with output capture** - `4a95346` (feat)
   - Also includes Rule 2 auto-fix: `.mutant.yml` includes/requires addition

## Files Created/Modified

- `tmp/mutant-report.txt` — Full mutant run output (141 lines): boot header, 6 function sections each with one representative alive-mutation diff, and summary footer with kill rate
- `.mutant.yml` — Added `includes: [lib]` and `requires: [date_utils]` so mutant discovers DateUtils subjects without explicit CLI flags

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added includes/requires to .mutant.yml**
- **Found during:** Task 1 (run mutant with output capture)
- **Issue:** Original `.mutant.yml` contained only `usage: opensource`. Running `bundle exec mutant run --integration rspec DateUtils` produced "Subjects: 0 / Mutations: 0 / Coverage: 100%" — mutant found nothing to test because the `lib/` directory was not in the load path and `date_utils` was not required.
- **Fix:** Added `includes: [lib]` and `requires: [date_utils]` to `.mutant.yml`. This is equivalent to passing `--include lib --require date_utils` on the CLI and is the canonical configuration approach.
- **Files modified:** `.mutant.yml`
- **Verification:** Re-ran mutant — "Subjects: 6 / Mutations: 259" confirming all functions are found.
- **Committed in:** 4a95346 (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical config)
**Impact on plan:** Fix was essential — without it the plan's must_have truths ("contains the word 'alive'" and "contains a numeric kill rate") could not be satisfied. No scope creep; the fix is the minimal configuration change to make the tool work as documented.

## Issues Encountered

- `timeout` and `gtimeout` binaries not available on macOS. Used the Ruby `Timeout.timeout(600)` wrapper as specified in the plan's fallback path. Functionally identical.
- `/tmp/` directory is gitignored. Used `git add -f tmp/mutant-report.txt` to force-add the specific report file as required by the plan (the plan explicitly lists `tmp/mutant-report.txt` as `files_modified` and states it is referenced by downstream plans).

## Known Stubs

None. `tmp/mutant-report.txt` is fully populated with real mutant output — no placeholders.

## Threat Flags

No new security-relevant surface introduced. `tmp/mutant-report.txt` contains only source code diffs from `lib/date_utils.rb` — no secrets, credentials, or PII (T-03-04 accepted as planned).

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `tmp/mutant-report.txt` is ready for Plan 03-03 (audit) to parse alive-mutation counts per function and generate the Act 1 narrative table
- `.mutant.yml` now has complete configuration; `bundle exec mutant run --integration rspec DateUtils` and `bundle exec rake mutant` both work without additional flags
- Phase 5 (demo branch commits) can reference `tmp/mutant-report.txt` directly

---

## Self-Check: PASSED

Files exist:
- tmp/mutant-report.txt: FOUND (141 lines, non-empty)
- .mutant.yml: FOUND (includes/requires added)
- .planning/phases/03-mutant-baseline/03-02-SUMMARY.md: FOUND

Commits exist:
- 4a95346: FOUND (feat(03-02): run mutant baseline and capture report)

*Phase: 03-mutant-baseline*
*Completed: 2026-05-26*
