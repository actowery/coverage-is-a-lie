# Phase 1: Repo Foundation - Discussion Log

> **Audit trail only.** Do not use as input to planning, research, or execution agents.
> Decisions are captured in CONTEXT.md — this log preserves the alternatives considered.

**Date:** 2026-05-26
**Phase:** 1-Repo Foundation
**Areas discussed:** License choice, Repo hosting and naming, Gem packaging style, CI + scaffold scope

---

## License choice

| Option | Description | Selected |
|--------|-------------|----------|
| MIT (Recommended) | Shortest, most familiar, satisfies mutant's OSS requirement. Default for demo/example repos. | ✓ |
| Apache-2.0 | Adds explicit patent grant + NOTICE conventions. Pick if Perforce legal prefers Apache. | |
| BSD-3-Clause | MIT-equivalent permissions with an attribution clause. | |

**User's choice:** MIT
**Notes:** No legal complications anticipated; MIT is the lowest-friction path for an internal demo that's also publicly cloneable.

---

## Repo hosting

| Option | Description | Selected |
|--------|-------------|----------|
| Personal account (Recommended) | github.com/<adrian-handle>/<name>. Fastest path, no org approval, no Perforce brand attached. | ✓ |
| Perforce / PE org | github.com/puppetlabs/... Adds organizational legitimacy but needs org-repo approval. | |
| Personal now, transfer later | Ship under personal handle; transfer later if leadership wants to adopt. | |

**User's choice:** Personal account
**Notes:** "Transfer later" is implicitly preserved as a future option (noted in deferred ideas); for now, personal hosting unblocks Phase 1 immediately.

## Repo name

| Option | Description | Selected |
|--------|-------------|----------|
| mutation-testing-example | Matches current working directory. Generic but searchable. | |
| ruby-mutation-demo | Calls out language + intent. | |
| coverage-is-a-lie | Memorable, leans on the demo's thesis. Bold; works well as a self-pitch. | ✓ |

**User's choice:** coverage-is-a-lie
**Notes:** The repo name becomes part of the pitch. README H1 will mirror the name.

---

## Gem packaging style

| Option | Description | Selected |
|--------|-------------|----------|
| Gemfile-only (Recommended) | Just Gemfile + Gemfile.lock + lib/. Simplest scaffold for demo-only intent. | ✓ |
| .gemspec + Gemfile calls gemspec | Production-gem layout with version + summary. Mirrors a real prod repo. | |

**User's choice:** Gemfile-only
**Notes:** No need to publish the library as a gem. Keeps Phase 1 tight.

---

## CI

| Option | Description | Selected |
|--------|-------------|----------|
| Yes — minimal `bundle install` smoke check (Recommended) | Workflow checks out, sets up Ruby 3.4.x, runs bundle install. No rspec yet. | ✓ |
| Yes — bundle install + run rspec | Same as above + bundle exec rspec. Would fail in Phase 1 without placeholder specs. | |
| No — defer CI to Phase 6 | Phase 6's E2E validation is the canonical clean-run gate. Risk: Gemfile drift goes unnoticed. | |

**User's choice:** Minimal smoke check
**Notes:** RSpec step gets added by Phase 2 once specs exist. Mutant never runs in CI (deferred — too slow/expensive for push hooks).

## Scaffold scope

| Option | Description | Selected |
|--------|-------------|----------|
| Only what Phase 1 needs (Recommended) | LICENSE, README, Gemfile, .ruby-version, .mutant.yml, .gitignore, ci.yml only. Each later phase owns its dirs. | ✓ |
| Full skeleton with empty dirs + .gitkeep | Pre-create lib/, spec/, docs/, tmp/ with placeholders. Whole repo shape visible from Phase 1. | |

**User's choice:** Only what Phase 1 needs
**Notes:** Phase 2 owns lib/ + spec/, Phase 3 owns tmp/, Phase 4 owns .claude/skills/llm-mutate/ + scripts/, Phase 5 owns docs/.

---

## Claude's Discretion

- Exact Gemfile pinning style (`~>` vs `=`)
- `.gitignore` ordering / specific Ruby gitignore template choice
- CI workflow name string and concurrency settings
- README quickstart prose (minimal/factual, no marketing copy yet)

## Deferred Ideas

- `.gemspec` + publishable-gem layout — explicitly rejected for Phase 1
- CI running RSpec on push — Phase 2 task
- CI running mutant on push — explicitly NOT desired (too slow/expensive)
- README Act 1 / Act 2 narrative framing — Phase 5
- GitHub repo settings (branch protection, required reviews) — out of scope for demo
- Transferring repo to a Perforce org later — possible follow-up, not Phase 1
- CI badge in README — Phase 5
