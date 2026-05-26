# Phase 5: Comparison and Narrative - Context

**Gathered:** 2026-05-26
**Status:** Ready for planning
**Mode:** Auto-generated (discuss skipped via workflow.skip_discuss)

<domain>
## Phase Boundary

The demo's storytelling layer: write `docs/comparison.md` mapping mutant + LLM-mutate results to the same six functions; create `demo/weak-tests` and `demo/fixed-tests` git branches with committed report artifacts; turn the README into a two-act narrative; write `docs/shot-list.md` and `docs/narration-script.md` for the recording.

**Requirements:** COMP-01, COMP-02, DEMO-01, DEMO-02, DEMO-03, DOC-01, DOC-02, DOC-03, DOC-04

**Success Criteria:**
1. `docs/comparison.md` table covers all six functions with kill/survive verdicts from both tools, and calls out at least three mutations where they diverge with one-sentence explanations
2. `git checkout demo/weak-tests` and `git checkout demo/fixed-tests` each land in a self-consistent state with committed report artifacts; no manual edits required
3. README contains clearly-labeled Act 1 / Act 2 sections with the "100% coverage is a lie" and AI-era framing
4. `docs/shot-list.md` enumerates every demo beat with terminal commands, expected output, and dual-audience cues
5. `docs/narration-script.md` recording-ready voice-over text aligned to the shot list
</domain>

<decisions>
## Implementation Decisions
- Branches: `demo/weak-tests` (current weak suite + both reports committed), `demo/fixed-tests` (suite augmented with boundary-case tests that kill the mutations, both reports re-run and committed)
- Dual-audience cues per shot: one beat for technical viewers (the mutation diff), one beat for leadership viewers (the implication)
- Sources of truth already in repo: `tmp/mutant-report.txt`, `docs/mutant-audit.md`, `.claude/skills/llm-mutate/fixtures/canonical.json`, `tmp/llm-mutation-report.md` (replay) — Phase 5 doesn't regenerate, it cross-references
</decisions>

<code_context>
- Phase 3 deliverables: `tmp/mutant-report.txt`, `docs/mutant-audit.md` (253 alive, 6 anchor bugs labeled meaningful)
- Phase 4 deliverables: `.claude/skills/llm-mutate/` with fixture, replay, generate modes; mutation score 0/20 on weak suite
- The "fixed-tests" branch needs a strengthened RSpec suite that turns 0/20 → ~20/20 (most mutations killed). This requires writing the boundary-case tests the weak suite intentionally omitted.
- README Act 1 already drafted in 03-01 (mutant section); Phase 5 adds Act 2 (LLM-mutate) and the overall narrative framing
</code_context>

<specifics>
## Specific Ideas
- `docs/comparison.md`: a table per function with rows for mutant mutations and llm-mutate mutations and a divergence column
- `docs/shot-list.md`: numbered beats — open terminal, run command, expected output, what the viewer should notice
- `docs/narration-script.md`: prose that ties the beats together with the demo's thesis
- The `demo/fixed-tests` branch is also implicitly a proof of concept: strengthening tests kills the planted bugs
</specifics>

<deferred>
## Deferred Ideas
None — autonomous run.
</deferred>
