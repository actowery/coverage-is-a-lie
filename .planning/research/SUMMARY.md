# Project Research Summary

**Project:** Mutation Testing Demo — "100% Coverage Is a Lie"
**Domain:** Ruby demo repo with dual mutation-testing approach (traditional tool + LLM-driven Claude Code skill)
**Researched:** 2026-05-26
**Confidence:** HIGH

## Executive Summary

This project is a recording-ready demo repo that proves a single thesis for a mixed engineering/leadership audience: green CI and 100% line coverage can hide tests that verify nothing. The canonical approach is a two-act narrative — Act 1 shows a passing, fully-covered test suite and then exposes surviving mutations; Act 2 shows the fixed suite killing every mutation. The specimen library is a small, pure-Ruby date/time utility (six functions) chosen specifically because its boundary conditions (leap years, off-by-one on business-day loops, sign handling for negative durations) produce semantically meaningful mutations where the audience immediately understands why a real engineer could have shipped the bug. Nothing in the stack is experimental: Ruby 3.4, RSpec 3.13, SimpleCov 0.22, and mutant 0.16 are all stable, well-documented, and integrate cleanly.

The headline novelty is the LLM-driven mutation skill — a Claude Code slash command (Sonnet 4.6) that generates mutations the way Meta's ACH system does: by asking "what would a careless developer plausibly write here?" rather than exhaustively applying operator substitutions. The skill runs inside Claude Code using native Read/Write/Bash tools, writes ephemeral mutant copies to `tmp/mutants/`, runs RSpec against each one, and emits plain-English descriptions alongside diffs and kill/survive verdicts. The side-by-side comparison of mutant gem output vs LLM skill output on the same six functions is the demo's money shot.

The two non-negotiable risks are (1) the mutant gem's binary licensing model — the repo must be public from day one, or a commercial subscription purchased before any private work begins — and (2) LLM non-determinism, which requires a fixture-replay system built into the skill from the start so the demo produces identical output every rehearsal and every live run. Three additional decisions need user input before implementation begins: repo visibility (public vs private), the equivalent-mutant handling strategy, and the fixture replay invocation pattern.

---

## Key Findings

### Recommended Stack

The entire stack is locked and stable. Ruby 3.4 is the forward-looking pin because mutant switches to the faster Prism parser on 3.4 and requires >= 3.3 in any case. RSpec 3.13 (not the 4.0 beta) is required because mutant-rspec 0.16.3 pins `rspec-core < 5.0.0` and the beta has demo-breakage risk. The official Anthropic Ruby SDK (`anthropic ~> 1.43.0`) supersedes all community gems and must be used; do not use `alexrudall/ruby-anthropic`. The LLM skill is packaged as a Claude Code skill under `.claude/skills/llm-mutate/SKILL.md` — not a standalone Ruby script — to deliver the "reusable across repos" leverage the project explicitly wants.

**Core technologies:**
- **Ruby 3.4.x** — runtime; 3.4 enables Prism parser in mutant (faster boot), required >= 3.3
- **RSpec 3.13.2** — test framework; expressive matchers make weak-looking-strong tests most visible; mutant-rspec integration clean
- **SimpleCov 0.22.0** — coverage reporting; produces the "100% green" proof before the mutation reveal; branch coverage via `enable_coverage :branch`
- **mutant 0.16.3 + mutant-rspec 0.16.3** — traditional operator-based mutation baseline; the side-by-side comparison anchor; licensing requires public repo or paid subscription
- **anthropic ~> 1.43.0** — official Anthropic Ruby SDK; used inside the LLM skill script; supports prompt caching with 1-hour TTL
- **Claude Sonnet 4.6 (`claude-sonnet-4-6`)** — mutation quality / cost balance; pinned exact model ID (not an alias); $3/$15 MTok input/output

**Critical version constraints:** mutant 0.16.3 and mutant-rspec 0.16.3 must be exactly the same version. Do not combine RSpec 4.0.0.beta1 with mutant-rspec 0.16.3. Pin model string as `"claude-sonnet-4-6"` — not `claude-sonnet-latest`.

### Expected Features

**The six library functions (the demo's entire surface area):**

| Function | Primary mutation-richness |
|----------|--------------------------|
| `days_between(start_date, end_date)` | Sign flip, inclusive/exclusive boundary |
| `add_business_days(date, n)` | Weekend-skip direction, fence-post, negative n |
| `leap_year?(year)` | Three-clause rule; dropping `% 400 == 0` is the classic miss |
| `age_in_years(birthdate, as_of:)` | Leap-day birthday fallback, birthday-this-year off-by-one |
| `next_occurrence_of_weekday(from_date, weekday)` | Return-same-day vs always-next, modular arithmetic boundary |
| `weeks_between(start_date, end_date)` | Integer vs float division, sign for reversed dates |

DST is intentionally excluded — timezone-dependent behavior is unreliable in a self-contained demo without a fake clock, and leap year / business-day logic provides equivalent narrative richness without the fragility.

**Must have (table stakes — narrative breaks without these):**
- 100%-coverage RSpec suite that passes green with deliberately weak assertions (omission of edge cases, not obvious `not_to be_nil` nonsense)
- mutant gem integration with survived-mutation report and kill rate number
- LLM mutation skill: generate mutations, run RSpec per mutation, emit plain-English description + diff + verdict + mutation score
- "Fixed tests" branch/state showing all mutations killed — Act 2 close
- README with demo flow, commands, dual-audience narration script, and shot list

**Should have (differentiators):**
- Side-by-side comparison table: mutant gem mutations vs LLM skill mutations on same functions
- Plain-English mutation descriptions ("what a careless developer would write")
- AI-era framing in README and script: "AI-generated tests can hit every line without verifying behavior"
- Cost reporting per LLM skill run (tokens + estimated $)
- Fixture replay mode in the LLM skill — required for reproducible demos

**Defer to v1.x or later:**
- SimpleCov coverage-gap targeting in LLM skill
- Configurable `--mutations-per-function` flag
- CI integration example
- Equivalent-mutation detection as a pipeline step (solve via library design instead)

**Anti-features (do not build):**
- DST-dependent library functions
- Web UI / dashboard for the skill
- Auto-fix suggestions from LLM skill
- Replacing or wrapping mutant

### Architecture Approach

The repo is a standard Ruby gem layout (`lib/date_utils/`, `spec/date_utils/`) with two mutation runners operating on the same library through fundamentally different mechanisms: mutant manipulates ASTs in-memory and evals mutated code into the running Ruby VM; the LLM skill writes physical file copies to `tmp/mutants/` and runs RSpec as a subprocess via a thin shell wrapper (`scripts/run_mutant_spec.sh`). This architectural difference is itself a useful demo beat. Both tools produce report artifacts committed at each demo-state branch. The skill runs entirely inside the Claude Code session — Claude is the runtime; no separate daemon.

**Major components:**
1. **`lib/date_utils/`** — subject under test; pure Ruby, dependency-free, three focused source files
2. **`spec/date_utils/` + SimpleCov** — test oracle; spec_helper must load SimpleCov as its very first line before any library require; `minimum_coverage 100` enforces the green premise; guard SimpleCov behind `ENV['COVERAGE']` to prevent it loading during mutant runs
3. **`mutant` gem** — traditional baseline runner; AST → operator mutations → in-VM eval → RSpec per mutation; outputs to `tmp/mutant-report.txt`
4. **`.claude/skills/llm-mutate/`** — LLM skill; SKILL.md orchestrates Claude's Read/Write/Bash loop; `run_mutant_spec.sh` wraps RSpec with exit convention 0=killed / 1=survived; `disable-model-invocation: true`, `context: fork`
5. **`tmp/` reports** — primary demo artifacts; committed per act on named branches (`demo/weak-tests`, `demo/fixed-tests`)
6. **`docs/`** — shot list and narration script; human-consumed, no code dependencies

### Critical Pitfalls

1. **mutant licensing trap** — The repo must be public from day one to use `--usage opensource`, or a commercial subscription purchased first. No gray area, no trial tier. Resolve at Phase 1 before writing any code. Set `usage:` key in `.mutant.yml` explicitly.

2. **LLM non-determinism breaks demo reproducibility** — Even at `temperature: 0`, runs produce different mutations. The skill must be built with fixture-replay duality from the start: `generate` mode calls the API; `replay` mode reads the fixture. The demo always uses `replay` mode. Non-negotiable.

3. **Weak tests look like an obvious straw man** — Tests must look like reasonable first-pass coverage with real assertions (`expect(result).to eq(value)`) — the only failure is omission of boundary cases. Get a blind review from someone not involved in building the demo before recording.

4. **Equivalent mutants inflate the survivor narrative** — ~25% of LLM-generated mutants that build and pass are semantically equivalent to the original (per Meta's research). Design library functions so arithmetic mutations always change observable behavior; post-process LLM output to strip comment-only changes; label equivalents in output.

5. **LLM generates non-compilable mutants (~25-38% rate)** — Build `ruby -c` syntax validation into the skill pipeline before running RSpec. Report compile-error rejections separately. Constrain mutation prompts to single-expression changes, not whole-function rewrites.

6. **LLM cost runaway during prompt iteration** — Enforce `MAX_MUTATIONS` cap (default 20); target a single function during prompt development (not the full file); use fixture replay during demo flow testing. Set up budget guardrails before iterative prompt work begins.

7. **Claude Code skill permissions interrupt demo flow** — `allowed-tools` frontmatter does not currently propagate to Bash command permissions (open issue #14956). Pre-configure `~/.claude/settings.json` on the demo machine before recording. Test in a fresh terminal first.

---

## Implications for Roadmap

Based on research, the build order is hard-constrained by dependencies. The library must exist before tests, tests before either mutation tool, and both tools before the comparison and narrative artifacts. Fixture infrastructure belongs in Phase 4 (skill development) — not as an afterthought — because it is the primary guard against demo-breaking non-determinism.

### Phase 1: Repo Foundation and Licensing Decision
**Delivers:** Repo with correct access level, `.ruby-version` pinned to 3.4.x, Gemfile with locked versions, `.mutant.yml` with `usage:` key set, skeleton directory structure, `bundle install` running clean.
**Avoids:** mutant license violation (Pitfall 1)

### Phase 2: Date/Time Library and Deliberately Weak Test Suite
**Delivers:** All six library functions; 100%-covered RSpec suite that passes green but omits boundary cases; SimpleCov configured with `minimum_coverage 100` and branch coverage; blind-review confirming tests look like plausible first-pass work; timezone consistency verified (`TZ=UTC` and `TZ=America/New_York` both pass).
**Avoids:** Straw-man weak tests (Pitfall 3); DST-dependent functions; flaky tests

### Phase 3: mutant Gem Integration and Act 1 Baseline
**Delivers:** `bundle exec mutant run` against all six functions; `tmp/mutant-report.txt` with kill rate and alive-mutation diffs; timeout guard in spec_helper; SimpleCov guarded behind `ENV['COVERAGE']`; manual equivalence audit of top survivors.

### Phase 4: LLM Mutation Skill
**Delivers:** Full `.claude/skills/llm-mutate/` skill with SKILL.md frontmatter, prompt templates for semantically meaningful date/time mutations, `run_mutant_spec.sh` with 0/1 exit convention, `ruby -c` syntax validation, `MAX_MUTATIONS` cap, fixture generate/replay modes, plain-English mutation descriptions, kill/survive verdicts, mutation score summary, cost reporting, `tmp/llm-mutation-report.md`.
**Research flag:** Needs deeper research during planning (`/gsd-plan-phase --research-phase 4`).

### Phase 5: Side-by-Side Comparison and Narrative Assembly
**Delivers:** Side-by-side comparison table; `docs/shot-list.md` with per-beat notes and dual-audience markers; `docs/narration-script.md`; `demo/weak-tests` and `demo/fixed-tests` branches committed with both report artifacts; complete README.

### Phase 6: End-to-End Demo Validation
**Delivers:** Full two-act demo verified on recording machine; all Claude Code permissions pre-configured; fixture file committed; timezone consistency confirmed; "looks done but isn't" checklist from PITFALLS.md completed.

---

## Open Decisions Needing User Input

These cross-cutting decisions must be resolved before or during Phase 1.

| Decision | Options | Blocker for |
|----------|---------|-------------|
| **Repo visibility: public or private?** | Public (use `--usage opensource`, free) vs Private (purchase commercial subscription, $250/year) | Phase 1 — mutant cannot run without this resolved |
| **Equivalent-mutant strategy** | (a) Design library to avoid them + label in output, vs (b) Build optional LLM equivalence-check step (doubles cost), vs (c) Manual audit only | Phase 2 (library design) and Phase 4 (skill design) |
| **Fixture replay invocation: how does the presenter trigger it?** | `--replay` flag in shell invocation vs argument passed to skill in Claude Code chat vs separate `/llm-mutate-replay` skill | Phase 4 (skill architecture) |

---

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | HIGH | All versions verified against official sources. |
| Features | HIGH (table stakes), MEDIUM (LLM skill surface) | Table stakes and library function design well-grounded. LLM skill fixture format and prompt structure are novel. |
| Architecture | HIGH | mutant gem and Claude Code skill architectures both well-documented. |
| Pitfalls | HIGH | All major risks confirmed against primary sources. |

**Overall confidence:** HIGH

---

## Sources

### Primary (HIGH confidence)
- [mutant GitHub (mbj/mutant)](https://github.com/mbj/mutant)
- [mutant-rspec RubyGems.org](https://rubygems.org/gems/mutant-rspec)
- [anthropics/anthropic-sdk-ruby GitHub](https://github.com/anthropics/anthropic-sdk-ruby)
- [Anthropic Models overview](https://platform.claude.com/docs/en/about-claude/models/overview)
- [Anthropic Prompt Caching docs](https://platform.claude.com/docs/en/build-with-claude/prompt-caching)
- [Claude Code Skills docs](https://code.claude.com/docs/en/skills)
- [Meta ACH paper arXiv 2501.12862](https://arxiv.org/abs/2501.12862)
- [arXiv 2406.09843: Comprehensive Study on LLMs for Mutation Testing](https://arxiv.org/html/2406.09843v2)

### Secondary
- [Meta Engineering blog Sep 2025](https://engineering.fb.com/2025/09/30/security/llms-are-the-key-to-mutation-testing-and-better-compliance/)
- [SimpleCov GitHub](https://github.com/simplecov-ruby/simplecov)
- [How Does Mutant Work? (Timo Rößner)](https://troessner.github.io/articles/2016-08-02-how-does-mutant-work.html)
- [Claude Code issue #14956](https://github.com/anthropics/claude-code/issues/14956)

---
*Research completed: 2026-05-26*
*Ready for roadmap: yes*
