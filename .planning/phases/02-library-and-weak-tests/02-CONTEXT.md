# Phase 2: Library and Weak Tests - Context

**Gathered:** 2026-05-26
**Status:** Ready for planning
**Mode:** Auto-generated (discuss skipped via workflow.skip_discuss for autonomous run)

<domain>
## Phase Boundary

All six `DateUtils` functions exist with non-trivial branching logic and the RSpec suite achieves 100% line and branch coverage while deliberately omitting boundary cases — the "green but broken" premise of the demo is proven and blind-review confirmed.

**Requirements:** LIB-01, LIB-02, LIB-03, LIB-04, LIB-05, LIB-06, LIB-07, TEST-01, TEST-02, TEST-03, TEST-04, TEST-05, TEST-06

**Success Criteria:**
1. `bundle exec rspec` passes green and SimpleCov reports 100% line and branch coverage on the library
2. Suite passes identically under `TZ=UTC` and `TZ=America/New_York`
3. A reviewer who did not build the library agrees the test suite looks like plausible first-pass coverage (no obvious straw-man tells)
4. Every function contains at least one boundary condition (leap-day, negative duration, off-by-one, weekend boundary) that the suite omits

</domain>

<decisions>
## Implementation Decisions

### Claude's Discretion
All implementation choices are at Claude's discretion — discuss phase was skipped per user setting for the autonomous run. Use ROADMAP phase goal, success criteria, REQUIREMENTS.md, PROJECT.md, and codebase conventions (CLAUDE.md) to guide decisions.

### Anchoring References
- `.planning/PROJECT.md` — project intent, evolution rules, key decisions
- `.planning/REQUIREMENTS.md` — LIB-* and TEST-* requirements with detail
- `.planning/ROADMAP.md` — phase 2 goal and success criteria
- `./CLAUDE.md` — locked tech stack (Ruby 3.4.9, RSpec 3.13.2, SimpleCov 0.22.0)
- Phase 1 summaries — established scaffold (Gemfile pins, .gitignore exclusions, CI workflow)

</decisions>

<code_context>
## Existing Code Insights

Phase 1 established the scaffold: Gemfile pins rspec, simplecov, mutant, mutant-rspec, rake. The library and spec directories don't exist yet — plan-phase will create them.

</code_context>

<specifics>
## Specific Ideas

No specific requirements — discuss phase skipped per user directive. Refer to ROADMAP, REQUIREMENTS, and PROJECT for the demo narrative requirements:

- **Six DateUtils functions** with non-trivial branching logic (boundaries hidden — leap years, DST, negative durations, off-by-one)
- **Weak tests** that achieve 100% line+branch coverage but deliberately miss boundaries
- **Must look plausible** — not a straw-man; a reviewer should believe this is normal first-pass test coverage
- **TZ robustness** — pass under both `TZ=UTC` and `TZ=America/New_York`
- **SimpleCov green dashboard** — the demo's payoff is showing this passing while mutations survive

</specifics>

<deferred>
## Deferred Ideas

None — discuss phase skipped per user directive for autonomous run.

</deferred>
