---
phase: 05-comparison-and-narrative
plan: "01"
subsystem: docs
tags: [comparison, narrative, readme, divergence-analysis]
dependency_graph:
  requires: ["03-03-SUMMARY.md", "04-03-SUMMARY.md"]
  provides: ["docs/comparison.md", "README two-act narrative"]
  affects: ["demo recording", "presenter artifact"]
tech_stack:
  added: []
  patterns:
    - "Mutation IDs cross-referenced between mutant (M-XX-NN) and llm-mutate (LM-XX-NN)"
    - "Three-divergence minimum per COMP-02 — delivered eight labeled divergences"
    - "README structured as Act 1 / Act 2 narrative with DOC-04 permissions block"
key_files:
  created:
    - "docs/comparison.md"
  modified:
    - "README.md"
decisions:
  - "Documented eight DIVERGENCE callouts (vs minimum three) to cover all six functions"
  - "M-WB-01 survival labeled uncertain (module_function quirk) with explanation inline"
  - "LM-LY-01 bug-fix-that-survives highlighted as most pedagogically powerful divergence"
  - "README.md Demo Branches section written as placeholder pointing to Phase 5 Plan 02"
metrics:
  duration: "~3 min"
  completed: "2026-05-26"
  tasks_completed: 2
  files_changed: 2
---

# Phase 5 Plan 01: docs/comparison.md + README Two-Act Narrative Summary

Side-by-side mutation comparison document covering all six DateUtils functions with eight labeled
divergence callouts, paired with a two-act README rewrite carrying the "100% coverage is a lie"
thesis statement and AI-era framing.

## What Was Built

### Task 1: docs/comparison.md

Created a 256-line comparison document structured as:

- **Overview table** — all six functions with mutant alive/killed + LLM survived/killed counts
  confirming 2.31% kill rate (6/259 mutant) and 0% kill rate (0/20 LLM) on the weak suite
- **Per-function sections** — each of the six functions has a mutation pairing table (Tool |
  ID | Description | Verdict) and a "what both tools find" summary
- **Eight DIVERGENCE callouts** — all labeled inline within the per-function sections:
  - days_between-1: wrong arithmetic vs correct-looking defensive code
  - add_business_days-1: mechanical operator swap vs semantic weekend-normalizer
  - add_business_days-2: equivalent mutants cluster in different parts of the function
  - leap_year?-1: bug-fix mutation (LM-LY-01) that is provably correct yet still survives
  - age_in_years-1: operator swap vs idiomatic Feb-29 normalization patch
  - next_occurrence_of_weekday-1: modulo removal vs same-day semantic handler
  - weeks_between-1: catastrophic removal (tooling artifact) vs targeted `.abs` fix
  - weeks_between-2: float coercion mutation unique to LLM (no operator-based counterpart)
- **Divergences Summary section** — top-three narrative-rich divergences written out for demo use
- **References footer** — points to docs/mutant-audit.md and canonical.json

Cross-references: 54 mutant IDs (M-XX-NN pattern), 31 LLM IDs (LM-XX-NN pattern).

### Task 2: README.md rewrite

Rewrote README with the following structure:

| Section | Content |
|---------|---------|
| Header | "100% coverage is a lie. This repo proves it in two acts." + AI-era angle |
| Quickstart | Clone, bundle install, quick command reference |
| Act 1: mutant | Traditional mutation framing, run commands, expected 2.31% output shape |
| Act 2: llm-mutate | Semantic mutation framing, --replay/--generate commands, cost note, comparison link |
| Demo Branches | Two-branch workflow with git checkout commands (Phase 5 Plan 02 placeholder) |
| Side-by-Side Comparison | One-sentence pointer to docs/comparison.md |
| Claude Code Permissions | settings.json block with minimal-scope allow patterns (DOC-04) |
| License | MIT |

## Deviations from Plan

None — plan executed exactly as written. The plan provided precise mutation pairings, divergence
descriptions, and README structure; this execution transcribed and structured them faithfully.

The plan listed three named divergences for the Divergences Summary section; the per-function
sections contain eight total DIVERGENCE callouts because each function section labels its own
divergences inline. This is additive, not a deviation.

## Known Stubs

One intentional placeholder in Demo Branches section: branch names `demo/weak-tests` and
`demo/fixed-tests` are referenced but the branches do not yet exist. This is per the plan
spec: "Demo branches created in Phase 5 Plan 02." The placeholder note is explicit in both
the README and this summary. No functional content is missing — the commands are correct and
will work once Plan 02 creates the branches.

## Threat Flags

| Flag | File | Description |
|------|------|-------------|
| threat_flag: information_disclosure | README.md | settings.json permissions block added per DOC-04 — mitigated by using minimal-scope allow patterns (Bash(bundle exec *), Write(tmp/*)) with explicit note that these are scoped to demo repo commands only, per T-05-02 mitigation plan |

## Self-Check: PASSED

- `docs/comparison.md`: EXISTS (256 lines, 54 M-XX- refs, 31 LM-XX- refs, 8 DIVERGENCE labels)
- `README.md`: EXISTS (Act 1: 3 occurrences, Act 2: 2 occurrences, settings.json: 1 occurrence)
- `d08d7dc`: EXISTS (docs(05-01): write mutation tool comparison document)
- `7d3a5e6`: EXISTS (docs(05-01): rewrite README as two-act narrative with AI-era framing)
