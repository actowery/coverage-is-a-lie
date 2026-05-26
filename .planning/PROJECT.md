# Mutation Testing Demo

## Current State

**v1.0 shipped 2026-05-26** — Demo is recording-ready. Public repo at https://github.com/actowery/coverage-is-a-lie. Two-act narrative with 14-beat shot list, mutant baseline (2.31% kill rate against weak tests), `/llm-mutate` skill (0/20 score on weak tests, 13/13 on fixed tests), and demo branches that show the punchline via `git checkout` alone.

**Next milestone:** Start with `/gsd-new-milestone` when ready. SKILL-V2-* features were deferred for v1.0.

## What This Is

A runnable Ruby demo that proves the AI-era thesis that **100% code coverage is a lie** — green CI and full coverage can hide tests that don't actually verify anything. The demo pairs a small date/time utility library with deliberately weak (but passing) RSpec tests, then uses two mutation-testing approaches to expose the gaps: the traditional `mutant` gem as a baseline, and a custom Claude Code skill that generates LLM-driven mutations in the spirit of Meta's published research. Primary audience is internal Perforce/PE engineering and tech-apt skip-level leadership.

## Core Value

A viewer watches the demo and immediately understands that coverage metrics can be gamed and that mutation testing — especially LLM-driven — is the missing assurance layer in an AI-assisted development era.

## Requirements

### Validated

<!-- Shipped and confirmed valuable. -->

(None yet — ship to validate)

### Active

<!-- Current scope. Building toward these. -->

- [ ] A small Ruby date/time utility library (4–6 functions) with non-trivial branching logic (DST, leap years, negative durations, boundary conditions)
- [ ] RSpec test suite for the library that achieves 100% line coverage (SimpleCov) and passes green, but is deliberately weak (missing assertions, only happy paths, no boundary checks)
- [ ] `mutant` gem integration as the traditional mutation-testing baseline, with survived-mutation report
- [ ] Custom Claude Code skill (Sonnet 4.6) that generates LLM-driven mutations à la Meta's research and runs the test suite to detect survivors
- [ ] Side-by-side comparison output: traditional mutations vs LLM-driven mutations on the same codebase
- [ ] "Fixed tests" branch/state showing mutations now killed — closes the two-act narrative
- [ ] README walkthrough mapping to demo flow, plus a recording-ready shot list / narration script
- [ ] Repo runs cleanly from `git clone` → `bundle install` → demo commands

### Out of Scope

<!-- Explicit boundaries. Includes reasoning to prevent re-adding. -->

- Adrian recording or producing the actual demo video — that's a human deliverable; the project produces a recording-ready repo and script
- Languages other than Ruby — single-language keeps the demo tight and matches the PE audience's day-job ecosystem
- A polished public-facing blog post — audience is internal; a clean README is enough
- Hosting the LLM mutator as a managed service or web UI — it's a Claude Code skill, invoked locally
- Mutation testing of anything beyond the demo library — the skill should be reusable, but proving it on multiple codebases is a follow-up
- Replacing or wrapping `mutant` — we run it as-is; the LLM-driven mutator is the novelty, not a fork of existing tools

## Context

- **Inspiration:** Meta's published work on LLM-driven mutation testing at scale — using LLMs to generate semantically meaningful mutations beyond the classic operator set. This research will be investigated properly in the research phase to ground the skill design.
- **The AI-era angle:** Code coverage was always a weak signal, but in an AI-assisted era it's actively misleading — generated tests can hit every line without verifying behavior. Mutation testing exercises whether tests actually catch regressions.
- **Audience mix:** Internal PE engineering (technically deep, wants practical adoption story) + skip-level leadership (tech-apt, wants the narrative arc). The "coverage is a lie" framing carries both.
- **Why Ruby:** Matches PE's day-job ecosystem, has a strong traditional mutation tool (`mutant` gem) for the side-by-side comparison, and is readable in a video walkthrough.
- **Why date/time:** Small surface, pure logic, brutal edge cases (DST, leap years, off-by-one, negative durations) where mutations land hard and visibly — strong narrative juice for the video.
- **Demo deliverable:** Cloneable repo + README + recording-ready script. Adrian records.

## Constraints

- **Tech stack — Ruby:** Demo language locked to Ruby for ecosystem fit with PE audience and access to `mutant` gem for baseline comparison.
- **Test framework — RSpec:** Most expressive matchers and best integration with `mutant` and SimpleCov; also strongest narrative power for showing weak-looking-strong tests.
- **LLM model — Claude Sonnet 4.6:** Balance of mutation quality and cost. The skill should be tunable but Sonnet is the default.
- **Mutator packaging — Claude Code skill (no external API key):** The skill is pure SKILL.md instructions; Claude Code itself is the LLM runtime. No `anthropic` Ruby SDK, no API key — runs on the user's existing Claude Code session. Required because Adrian's org does not freely issue API keys, and this also makes the demo more reproducible for any viewer with Claude Code.
- **Quality over speed:** No deadline. Optimize for a polished, clear demo that travels well across teams.

## Key Decisions

<!-- Decisions that constrain future work. Add throughout project lifecycle. -->

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Ruby + RSpec for the demo | Matches PE ecosystem; `mutant` + SimpleCov integrate cleanly; RSpec matchers make "weak tests look fine" easier to demo | — Pending |
| LLM-driven mutator as the headline novelty | Mirrors Meta's research; differentiates from off-the-shelf mutation tools | — Pending |
| Include `mutant` gem as side-by-side baseline | Strongest narrative — shows where LLM-driven adds value vs traditional operator-based mutations | — Pending |
| Date/time utility library as demo subject | Small surface, pure logic, edge-case-rich — mutations land visibly | — Pending |
| Two-act narrative (green-but-broken → mutations expose) | Strongest pedagogical arc for mixed audience; carries both engineers and leadership | — Pending |
| Mutator delivered as a Claude Code skill | Reusable across repos, higher leverage than an in-repo script | — Pending |
| Skill runs inside the Claude Code session (no external API key) | Adrian's org doesn't freely issue Anthropic API keys; this also makes the demo runnable by any Claude Code user without auth setup | — Pending |
| Sonnet 4.6 as the default LLM for the mutator | Best quality/cost balance for semantically meaningful mutations | — Pending |
| Recording-ready repo + script, not a recorded video | Adrian records; project produces the artifacts that make recording easy | — Pending |

## Evolution

This document evolves at phase transitions and milestone boundaries.

**After each phase transition** (via `/gsd-transition`):
1. Requirements invalidated? → Move to Out of Scope with reason
2. Requirements validated? → Move to Validated with phase reference
3. New requirements emerged? → Add to Active
4. Decisions to log? → Add to Key Decisions
5. "What This Is" still accurate? → Update if drifted

**After each milestone** (via `/gsd-complete-milestone`):
1. Full review of all sections
2. Core Value check — still the right priority?
3. Audit Out of Scope — reasons still valid?
4. Update Context with current state

---
*Last updated: 2026-05-26 after initialization*
