# Phase 3: mutant Baseline - Context

**Gathered:** 2026-05-26
**Status:** Ready for planning
**Mode:** Auto-generated (discuss skipped via workflow.skip_discuss)

<domain>
## Phase Boundary

`bundle exec mutant run` executes against all six DateUtils functions, produces `tmp/mutant-report.txt` with kill rate and alive-mutation diffs, and a manual equivalence audit labels the meaningful survivors — Act 1 of the demo has its evidence.

**Requirements:** MUT-01, MUT-02, MUT-03, MUT-04, MUT-05

**Success Criteria:**
1. `bundle exec mutant run` completes against all six functions without hanging (timeout guard active)
2. `tmp/mutant-report.txt` exists, contains kill rate and at least one alive-mutation diff
3. SimpleCov does not load during mutant runs (env-guarded — already done in Phase 2)
4. Manual equivalence audit is complete — each surviving mutant is labeled as equivalent or meaningful
</domain>

<decisions>
## Implementation Decisions
All choices at Claude's discretion. Refer to REQUIREMENTS.md MUT-01..05, CLAUDE.md tech-stack pins, and Phase 2 summaries for the library's intentional boundary bugs.
</decisions>

<code_context>
- Phase 2 SUMMARYs document the six intentional boundary bugs per function (in 02-01-SUMMARY.md)
- `.mutant.yml` already exists with `usage: opensource`
- `spec/spec_helper.rb` has SimpleCov inside `ENV["COVERAGE"]` guard so mutant runs don't load it
- Gemfile pins mutant ~> 0.16.3 and mutant-rspec ~> 0.16.3 (already in Gemfile.lock)
</code_context>

<specifics>
## Specific Ideas
- Use `bundle exec mutant run --integration rspec --use rspec` per mutant-rspec convention
- Subject scope: `DateUtils*` (all functions)
- Capture full output to `tmp/mutant-report.txt`
- Audit must identify which survivors are *meaningful* (boundary bugs the weak tests missed) vs *equivalent* (semantically identical mutations the test suite couldn't catch anyway)
- This is Act 1 of the demo: weak tests survive mutations that would catch real bugs
</specifics>

<deferred>
## Deferred Ideas
None — autonomous run.
</deferred>
