---
phase: 03-mutant-baseline
plan: "01"
subsystem: test-infrastructure
tags: [mutation-testing, rspec, timeout, rake, documentation]
dependency_graph:
  requires: [02-01, 02-02, 02-03]
  provides: [03-02, 03-03]
  affects: [spec/spec_helper.rb, Rakefile, README.md]
tech_stack:
  added: []
  patterns: [RSpec around_example timeout guard, Rake shell task]
key_files:
  modified:
    - spec/spec_helper.rb
    - Rakefile
    - README.md
decisions:
  - "Timeout set to 5 seconds per example — sufficient for all real date calculations, kills infinite-loop mutations from while-loop in add_business_days"
  - "Used --integration rspec flag (correct for mutant 0.16.3) not --use rspec"
  - "Documented both tee command and rake convenience task in README so demo viewers have two options"
metrics:
  duration: "53 seconds"
  completed: "2026-05-26T18:21:22Z"
  tasks_completed: 2
  tasks_total: 2
  files_modified: 3
---

# Phase 03 Plan 01: Timeout Guard, Rake Mutant Task, README Act 1 Summary

Timeout guard added to RSpec spec_helper and rake mutant task wired, with README Act 1 documentation — repo is now safe to run bundle exec mutant run without risk of infinite-loop hangs.

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Add Timeout guard to spec_helper.rb and rake mutant task to Rakefile | 5d8289f | spec/spec_helper.rb, Rakefile |
| 2 | Document mutant command in README under Act 1 heading | 6787db0 | README.md |

## What Was Built

**Task 1 — spec/spec_helper.rb:** Added `require "timeout"` at file top (unconditional, not inside the COVERAGE guard). Added `RSpec.configure` block with `config.around(:each)` hook wrapping `example.run` in `Timeout.timeout(5)`. The ENV["COVERAGE"] guard and its SimpleCov configuration are untouched. This satisfies MUT-03 (timeout guard) while MUT-04 (SimpleCov isolation) was already satisfied.

**Task 1 — Rakefile:** Added a plain `task :mutant` with `desc` and `sh "bundle exec mutant run --integration rspec DateUtils"`. Uses `--integration rspec` (the correct mutant 0.16.3 flag) not `--use rspec` or `--include lib`.

**Task 2 — README.md:** Updated the Quickstart placeholder commands to reflect current phase reality. Added `## Act 1: Traditional Mutation Testing (mutant)` section with framing sentence, the tee command (`2>&1 | tee tmp/mutant-report.txt`), rake convenience alternative, opensource license note (.mutant.yml), and expected output shape description.

## Deviations from Plan

None - plan executed exactly as written.

## Verification Results

All plan verification checks passed:
- `ruby -c spec/spec_helper.rb` exits 0
- `grep "Timeout.timeout(5)" spec/spec_helper.rb` matches
- `grep 'ENV["COVERAGE"]' spec/spec_helper.rb` matches (guard intact)
- `ruby -c Rakefile` exits 0
- `grep "mutant run" Rakefile` matches
- `grep "Act 1" README.md` matches
- `grep "mutant-report.txt" README.md` matches (2 occurrences)
- `bundle exec rake -T` lists both `spec` and `mutant` tasks

## Known Stubs

None. No UI rendering or data wiring in this plan — pure configuration/documentation changes.

## Threat Flags

No new security-relevant surface introduced. The timeout guard addresses T-03-01 (DoS via infinite-loop mutation) as planned.

## Self-Check: PASSED

Files exist:
- spec/spec_helper.rb: FOUND
- Rakefile: FOUND
- README.md: FOUND

Commits exist:
- 5d8289f: FOUND (feat(03-01): add Timeout guard)
- 6787db0: FOUND (docs(03-01): add Act 1 mutant documentation)
