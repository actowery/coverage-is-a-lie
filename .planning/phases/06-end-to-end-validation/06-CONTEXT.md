# Phase 6: End-to-End Validation - Context

**Gathered:** 2026-05-26
**Status:** Ready for planning
**Mode:** Auto-generated

<domain>
## Phase Boundary

Smoke-test the entire demo as a presenter would. Every shot-list command runs verbatim from a fresh clone, produces the documented output, no prompts, no errors. Determinism of `--replay` confirmed once more.

**Requirements:** VAL-01, VAL-02, VAL-03

**Success Criteria:**
1. Full two-act demo runs end-to-end on the recording machine, no errors, no permission prompts
2. Every command in docs/shot-list.md produces the documented output verbatim
3. `/llm-mutate --replay` run three times produces byte-identical reports
</domain>

<decisions>
## Implementation Decisions
- Run the shot list one beat at a time on the *current* machine (the recording machine in practice for this demo)
- Capture any deviation as a fix in this phase — don't accept "works on my machine"
- Verify determinism by md5'ing the report across three consecutive runs
</decisions>

<code_context>
- docs/shot-list.md has 14 beats with expected outputs as anchors
- docs/narration-script.md aligned to beats
- demo/weak-tests and demo/fixed-tests branches pushed to origin
- README has Act 1 / Act 2 framing
</code_context>

<specifics>
## Specific Ideas
- A single plan that walks every beat, captures actual output, diffs against expected, fixes any drift
- Final smoke: clone fresh into a tmp dir, run the shot list from there to verify no machine-state assumptions
</specifics>

<deferred>
## Deferred Ideas
None — autonomous final smoke.
</deferred>
