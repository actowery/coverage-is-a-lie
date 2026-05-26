# Phase 1: Repo Foundation - Context

**Gathered:** 2026-05-26
**Status:** Ready for planning

<domain>
## Phase Boundary

Phase 1 produces a publicly-visible GitHub repo, MIT-licensed, with a locked Gemfile and `.mutant.yml`, such that `git clone` → `bundle install` runs clean on a fresh machine and every subsequent phase can start without a licensing or dependency surprise. No library code, no tests, no `mutant`/RSpec runs yet — those start in Phase 2.

</domain>

<decisions>
## Implementation Decisions

### License
- **D-01:** Use the **MIT License**. Satisfies `mutant --usage opensource`, is the lowest-friction default for an internal/demo repo, and is the most familiar to the PE audience.
- **D-02:** `LICENSE` file lives at repo root with Adrian Towery (Perforce) as copyright holder, year 2026.

### Repo hosting and naming
- **D-03:** Host on **Adrian's personal GitHub account** (not a Perforce org). Fastest path, no org approval needed, easy clone path for any viewer.
- **D-04:** Repo name: **`coverage-is-a-lie`**. Carries the demo's thesis directly; memorable for the recording.
- **D-05:** Repo must be **public** (hard requirement for `mutant --usage opensource`).
- **D-06:** Local working directory stays `mutation-testing-example`; the GitHub remote name is `coverage-is-a-lie`. Planner should configure `git remote add origin git@github.com:<adrian-handle>/coverage-is-a-lie.git` — actual GitHub username/handle to be confirmed during execution if it isn't already set in the user's git config.

### Gem packaging
- **D-07:** **Gemfile-only**. No `.gemspec`, no version constant, no publish path. Keeps Phase 1 minimal and matches the demo-only intent. The library is consumed via `bundle exec` only.
- **D-08:** Gemfile pins the four runtime/test gems from CLAUDE.md's tech stack:
  - `rspec ~> 3.13.2`
  - `simplecov ~> 0.22.0`
  - `mutant ~> 0.16.3`
  - `mutant-rspec ~> 0.16.3`
  - `rake` (bundled; loose pin acceptable)
  Group `:development, :test` for all four.
  No `anthropic` SDK gem — per PROJECT.md, the LLM skill runs inside Claude Code (no API client in Ruby).
- **D-09:** `Gemfile.lock` is committed (this is an application/demo, not a published library).

### CI
- **D-10:** **GitHub Actions workflow** at `.github/workflows/ci.yml`. Phase 1 scope: matrix on Ubuntu latest, single Ruby version (read from `.ruby-version`), steps = checkout → setup-ruby (`ruby/setup-ruby@v1` with `bundler-cache: true`) → `bundle install` validation. **No `bundle exec rspec` yet** — that's added by Phase 2 when specs exist. Trigger on `push` to default branch and `pull_request`.
- **D-11:** No README badge required for Phase 1, but the workflow file's name should be readable (`ci.yml`) so a badge can be added in Phase 5.

### Scaffold scope
- **D-12:** Phase 1 creates ONLY: `LICENSE`, `README.md`, `Gemfile`, `Gemfile.lock`, `.ruby-version`, `.mutant.yml`, `.gitignore`, `.github/workflows/ci.yml`. Each later phase creates its own directories:
  - Phase 2 creates `lib/` and `spec/`
  - Phase 3 creates `tmp/` (or it's `.gitignore`'d and created at runtime)
  - Phase 4 creates `.claude/skills/llm-mutate/` and `scripts/`
  - Phase 5 creates `docs/`
- **D-13:** `.gitignore` must include `tmp/`, `Gemfile.lock` for gems (NOT for this repo — keep the lock), `.bundle/`, `vendor/bundle/`, `coverage/`, and standard Ruby/macOS noise (`.DS_Store`, `*.gem`). Note: `Gemfile.lock` IS committed per D-09; the .gitignore should NOT exclude it.

### Specific file contents
- **D-14:** `.ruby-version` contains `3.4.8` (latest stable patch as of Dec 2025, per CLAUDE.md tech stack).
- **D-15:** `.mutant.yml` minimum content: `usage: opensource` (per REPO-04). Other mutant config (integration, includes, requires) deferred to Phase 3 where mutant actually runs.
- **D-16:** README quickstart (per REPO-05) shows: clone → `cd coverage-is-a-lie` → `bundle install` → placeholder commands for future phases (e.g., `bundle exec rspec`, `bundle exec mutant run`, `/llm-mutate --replay` in Claude Code). Phase 1's README is a quickstart skeleton; Phase 5 builds the full Act 1 / Act 2 narrative version.

### Claude's Discretion
- Specific Gemfile syntax (pessimistic vs exact pins) — pessimistic (`~>`) is fine; planner can tighten if needed.
- `.gitignore` exact line ordering — standard Ruby gitignore template is acceptable.
- CI workflow name string and concurrency settings — planner picks sensible defaults.
- README quickstart wording — minimal/factual, no marketing copy yet.

</decisions>

<canonical_refs>
## Canonical References

**Downstream agents MUST read these before planning or implementing.**

### Project context (always)
- `CLAUDE.md` — tech stack pins (Ruby 3.4.x, RSpec 3.13.2, SimpleCov 0.22.0, mutant/mutant-rspec 0.16.3); What NOT to Use table; version compatibility matrix
- `.planning/PROJECT.md` — Core Value, Constraints, Key Decisions; especially the "no `anthropic` SDK" constraint
- `.planning/REQUIREMENTS.md` §"Repo Foundation" — REPO-01 through REPO-05 (the locked acceptance criteria for this phase)
- `.planning/ROADMAP.md` §"Phase 1: Repo Foundation" — Goal and Success Criteria

### External (do not fetch during planning; for reference)
- `mutant` OSS-usage docs: https://github.com/mbj/mutant (license clause that requires `usage: opensource` for non-paid use)
- `ruby/setup-ruby` GitHub Action: https://github.com/ruby/setup-ruby (used in CI)

No internal ADRs exist yet — this is the project's first phase.

</canonical_refs>

<code_context>
## Existing Code Insights

### Reusable Assets
- None — repo currently contains only `.planning/`, `.git/`, `.claude/`, `.gsd/`, and `CLAUDE.md`. Phase 1 is genuinely greenfield.

### Established Patterns
- None yet. Phase 1's outputs will become the pattern for everything downstream.

### Integration Points
- `.planning/` directory (GSD workflow state) — must not be touched by Phase 1 file creation; it lives alongside the repo's working files but is internal to the planning workflow.
- `.claude/` directory — currently exists but is empty of skills. The `/llm-mutate` skill lands here in Phase 4, not Phase 1.
- `CLAUDE.md` — already exists at repo root; do not overwrite. README is a separate file (`README.md`).

</code_context>

<specifics>
## Specific Ideas

- Repo name `coverage-is-a-lie` is intentional — it doubles as a pitch line. The README's H1 can be the same phrase.
- Adrian's GitHub handle should be detected from `git config user.email` (`adrian.towery@perforce.com`) or `git config github.user` during execution. If unset, planner should add a step that prompts for it.
- The Gemfile group block stays as `group :development, :test do ... end` for all four gems — they are all dev-time tooling; nothing the library itself depends on at runtime.
- CI ruby version should be sourced from `.ruby-version` (via `setup-ruby`'s `ruby-version-file: .ruby-version` input) rather than hardcoded — keeps the two pins in sync.

</specifics>

<deferred>
## Deferred Ideas

- **`.gemspec` + publishable-gem layout** — considered and rejected for Phase 1 (D-07). Not on the roadmap; if someone wants the library installable as a gem post-demo, that's a new phase or a follow-up project, not a Phase 1 task.
- **CI: run RSpec on push** — defer to Phase 2 (when specs exist). Phase 2's plan should extend `ci.yml` to add a `bundle exec rspec` step.
- **CI: run mutant on push** — explicitly NOT desired. mutant runs are slow and expensive; they belong in local/manual flows (and in Phase 3's demo evidence), not in CI.
- **README narrative (Act 1 / Act 2 framing, "100% coverage is a lie")** — that's Phase 5 (DOC-01). Phase 1's README is quickstart-only.
- **GitHub repo settings (branch protection, required reviews)** — out of scope for a demo repo. If Perforce ever adopts this, those get added at transfer time.
- **Transferring repo to a Perforce org later** — flagged as a possibility but not a Phase 1 action. Personal-account hosting for now.
- **CI badge in README** — Phase 5, when README gets its full pass.

</deferred>

---

*Phase: 1-Repo Foundation*
*Context gathered: 2026-05-26*
