# Phase 1: Repo Foundation - Research

**Researched:** 2026-05-26
**Domain:** Ruby project scaffolding, GitHub Actions CI, mutant OSS licensing, GitHub repo creation
**Confidence:** HIGH

## Summary

Phase 1 produces eight files and one public GitHub repo. The technical surface is small but contains four high-value gotchas that the planner must lock in before tasks are written:

1. **CLAUDE.md's pin of Ruby 3.4.8 is stale.** As of today (2026-05-26), Ruby **3.4.9** (released 2026-03-11) is the latest 3.4.x stable patch. The planner should pin `.ruby-version` to `3.4.9`, not `3.4.8`. This is the single concrete update CLAUDE.md's "as of Dec 2025" caveat anticipated.
2. **`bundler-cache: true` auto-enables deployment mode** when a `Gemfile.lock` is committed. This means Gemfile and Gemfile.lock must stay in sync — any unlocked Gemfile edit breaks CI with Bundler exit code 16. Acceptable for this project (we WANT a locked lock file) but the planner should be aware so the Phase 1 implementer commits both files together in the same commit.
3. **mutant OSS licensing as of mutant 0.16.3 is genuinely just `--usage opensource`** — no separate `mutant-license` gem, no signup, no key. The 2019 issue about `gem.mutant.dev` and license keys is historical; current README simply says "Free for open source. Use `--usage opensource` for public repositories." `.mutant.yml` accepts `usage: opensource` as a config-file equivalent so the CLI flag isn't required in every invocation.
4. **GitHub repo creation is best handled by `gh repo create --public --source=. --remote=origin --push`** in a single step — no need for separate `git remote add` + `git push -u`. The user is already authenticated as `actowery` via `gh auth status`, so no auth task is needed.

**Primary recommendation:** Plan Phase 1 as ~8 file-creation tasks (one per artifact) plus a single repo-creation/push task at the end. The planner should NOT add a "set up Ruby version manager" task — that's a manual prerequisite, not a Phase 1 deliverable (see Environment Availability below for the conditional gate).

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**License:**
- D-01: Use the **MIT License**. Satisfies `mutant --usage opensource`.
- D-02: `LICENSE` file lives at repo root with Adrian Towery (Perforce) as copyright holder, year 2026.

**Repo hosting and naming:**
- D-03: Host on **Adrian's personal GitHub account** (not a Perforce org).
- D-04: Repo name: **`coverage-is-a-lie`**.
- D-05: Repo must be **public** (hard requirement for `mutant --usage opensource`).
- D-06: Local working directory stays `mutation-testing-example`; GitHub remote name is `coverage-is-a-lie`. Configure `git remote add origin git@github.com:<adrian-handle>/coverage-is-a-lie.git` — actual GitHub username to be confirmed during execution.

**Gem packaging:**
- D-07: **Gemfile-only**. No `.gemspec`, no version constant, no publish path.
- D-08: Gemfile pins:
  - `rspec ~> 3.13.2`
  - `simplecov ~> 0.22.0`
  - `mutant ~> 0.16.3`
  - `mutant-rspec ~> 0.16.3`
  - `rake` (bundled; loose pin acceptable)
  All in `group :development, :test`. No `anthropic` SDK gem.
- D-09: `Gemfile.lock` IS committed.

**CI:**
- D-10: GitHub Actions workflow at `.github/workflows/ci.yml`. Ubuntu latest, single Ruby version (read from `.ruby-version`), steps = checkout → setup-ruby (`ruby/setup-ruby@v1` with `bundler-cache: true`) → `bundle install` validation. **No `bundle exec rspec` yet.** Trigger on `push` to default branch and `pull_request`.
- D-11: No README badge required for Phase 1.

**Scaffold scope:**
- D-12: Phase 1 creates ONLY: `LICENSE`, `README.md`, `Gemfile`, `Gemfile.lock`, `.ruby-version`, `.mutant.yml`, `.gitignore`, `.github/workflows/ci.yml`.
- D-13: `.gitignore` must include `tmp/`, `.bundle/`, `vendor/bundle/`, `coverage/`, `.DS_Store`, `*.gem`. Must NOT exclude `Gemfile.lock`.

**Specific contents:**
- D-14: `.ruby-version` contains `3.4.8` per CLAUDE.md tech stack. *(SEE NOTE BELOW — research found 3.4.9 is the current latest patch.)*
- D-15: `.mutant.yml` minimum content: `usage: opensource`. Other config deferred to Phase 3.
- D-16: README quickstart shows: clone → `cd coverage-is-a-lie` → `bundle install` → placeholder commands for future phases.

### Claude's Discretion
- Specific Gemfile syntax (pessimistic vs exact pins) — pessimistic (`~>`) is fine.
- `.gitignore` exact line ordering — standard Ruby template acceptable.
- CI workflow `name:` string and concurrency settings — planner picks sensible defaults.
- README quickstart wording — minimal/factual, no marketing copy yet.

### Deferred Ideas (OUT OF SCOPE)
- `.gemspec` + publishable-gem layout
- CI: run RSpec (defer to Phase 2)
- CI: run mutant (explicitly NOT desired)
- README narrative (Act 1 / Act 2 framing) — Phase 5
- GitHub repo settings (branch protection, required reviews)
- Transferring repo to a Perforce org later
- CI badge in README — Phase 5

### Research-Surfaced Updates to Locked Decisions

Two locked decisions reference values that may need a small update once the planner sees this research:

| Decision | Current Value | Research Finding | Planner Action |
|----------|---------------|------------------|----------------|
| D-14: `.ruby-version` content | `3.4.8` | Ruby 3.4.9 released 2026-03-11; is current stable patch as of 2026-05-26 | **Recommend updating to `3.4.9`.** CLAUDE.md explicitly anticipated this with "as of Dec 2025" caveat. Trivial change, lower exposure to known 3.4.8 issues. The planner should call this out as a deviation for user sign-off or treat the update as within Claude's discretion (CLAUDE.md authorizes "latest stable patch"). |
| D-15: `.mutant.yml` content | `usage: opensource` | Confirmed valid — both `.mutant.yml` `usage:` key and `--usage opensource` CLI flag are supported. No conflict; D-15 stands as-is. | No change. |

</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|------------------|
| REPO-01 | Repo is public on GitHub with an OSS license file present, so `mutant` can run under `--usage opensource` | Verified `gh repo create --public --source=. --remote=origin --push` workflow; MIT LICENSE template available; `--usage opensource` is the only OSS gate per current mutant README. |
| REPO-02 | `.ruby-version` pinned to a stable Ruby 3.4.x release | Verified Ruby 3.4.9 is the latest 3.4.x stable patch (2026-03-11); `.ruby-version` is auto-detected by `ruby/setup-ruby@v1` and by rbenv/asdf/chruby/mise. |
| REPO-03 | Gemfile declares locked versions for rspec, simplecov, mutant, and mutant-rspec; `bundle install` runs clean (no `anthropic` SDK) | All four gems verified on rubygems.org with current versions and active maintenance (see Package Legitimacy Audit). Pessimistic pin (`~>`) syntax confirmed. |
| REPO-04 | `.mutant.yml` contains explicit `usage: opensource` key | Confirmed `usage:` is a valid `.mutant.yml` top-level key per mutant docs; CLI flag `--usage opensource` is the equivalent. Either suffices, both are acceptable. |
| REPO-05 | README quickstart shows clone → bundle install → run-the-demo flow | Quickstart pattern is standard; placeholder commands for future phases noted in D-16. |

</phase_requirements>

## Architectural Responsibility Map

| Capability | Primary Tier | Secondary Tier | Rationale |
|------------|-------------|----------------|-----------|
| Source-controlled project metadata (LICENSE, README, .gitignore) | Repo Root / Filesystem | — | Static text files committed to git; no runtime tier involved. |
| Dependency management (Gemfile, Gemfile.lock) | Build / Toolchain | — | Owned by Bundler; consumed at `bundle install` time, not at app runtime. |
| Ruby version pinning (.ruby-version) | Build / Toolchain | CI (GitHub Actions) | Read by both local version managers (rbenv/asdf/chruby/mise) and `ruby/setup-ruby@v1` on CI. |
| Mutation tooling config (.mutant.yml) | Build / Toolchain | — | Consumed by `bundle exec mutant run` (Phase 3+); Phase 1 only places the licensing key, never invokes it. |
| Continuous integration (.github/workflows/ci.yml) | CI / GitHub Actions | — | Runs on push/PR; Phase 1's CI only validates `bundle install`. |
| Repository hosting | GitHub (external service) | — | Public repo on github.com; created via `gh repo create` from local source. |

**Sanity check for the planner:** Every Phase 1 artifact is either a static file in the working tree or a GitHub-side resource. There is no runtime application tier in Phase 1 — that begins in Phase 2.

## Standard Stack

### Core
| Library | Version | Purpose | Why Standard |
|---------|---------|---------|--------------|
| Ruby | 3.4.9 | Pinned interpreter version | Latest 3.4.x stable patch as of 2026-05-26. Mutant 0.16.3 uses Prism parser on 3.4+ for faster boot. [VERIFIED: ruby-lang.org/en/downloads/releases/] |
| Bundler | bundled with Ruby 3.4.9 | Dependency manager | Ships with Ruby 2.6+; no separate install. `Gemfile.lock`'s `BUNDLED WITH` line dictates which Bundler version `ruby/setup-ruby@v1` provisions on CI. [VERIFIED: setup-ruby action.yml] |
| GitHub Actions | n/a (hosted service) | CI runtime | Locked by D-10. `ubuntu-latest` resolves to `ubuntu-24.04` as of May 2026. [VERIFIED: docs.github.com runner images] |
| `ruby/setup-ruby@v1` | v1 (floating major) | GitHub Action to install Ruby and run `bundle install` | The de-facto Ruby setup action; supersedes `actions/setup-ruby`. Always prefer `@v1` (not pinned commit) per its own README. [VERIFIED: github.com/ruby/setup-ruby README] |

### Supporting (Gemfile contents — declared but NOT invoked in Phase 1)
| Library | Pin | Purpose | When to Use |
|---------|-----|---------|-------------|
| `rspec` | `~> 3.13.2` | Test framework | Phase 2+ — Phase 1 only declares it in the Gemfile so `bundle install` resolves. [VERIFIED: rubygems.org/api/v1/gems/rspec.json — 3.13.2 released 2025-10-21] |
| `simplecov` | `~> 0.22.0` | Coverage reporting | Phase 2+. [VERIFIED: rubygems.org — 0.22.0 released 2022-12-23, 469M+ downloads] |
| `mutant` | `~> 0.16.3` | Traditional mutation testing | Phase 3. [VERIFIED: rubygems.org — 0.16.3 released 2026-04-30, 1.78M+ downloads] |
| `mutant-rspec` | `~> 0.16.3` | RSpec integration for mutant | Phase 3. [VERIFIED: rubygems.org — 0.16.3 released 2026-04-30, 1.67M+ downloads, same author as mutant] |
| `rake` | (loose, no version) | Task runner | Optional convenience for `rake spec` / `rake mutant` aliases. Bundled with Ruby. [VERIFIED: bundled gem] |

**Installation (locally, after Phase 1 files exist):**
```bash
bundle install
```

**Version verification (run by planner before plan finalizes):**
```bash
gem search -re ^rspec$ ^simplecov$ ^mutant$ ^mutant-rspec$ ^rake$
# or equivalently:
curl -s https://rubygems.org/api/v1/gems/<gem>.json | jq -r '.version'
```

All five versions above were live-verified against `rubygems.org/api/v1/gems/<name>.json` on 2026-05-26.

## Package Legitimacy Audit

Phase 1 declares five gems. **Slopcheck flagged `simplecov` and `mutant-rspec` as [SLOP]** — but slopcheck only checks PyPI by default, and these are Ruby gems, not Python packages. This is the documented cross-ecosystem false-positive case slopcheck explicitly warns about. Per protocol, I cross-verified all five on the correct registry (rubygems.org). All five are legitimate.

| Package | Registry | Age | Downloads | Source Repo | slopcheck (PyPI — wrong ecosystem) | rubygems verdict | Disposition |
|---------|----------|-----|-----------|-------------|-------------------------------------|------------------|-------------|
| `rspec` | rubygems.org | ~17 yrs | 981M total | github.com/rspec/rspec | [OK] | Verified, MIT, active | Approved |
| `simplecov` | rubygems.org | ~13 yrs | 469M total | github.com/simplecov-ruby/simplecov | [SLOP — wrong ecosystem] | Verified, MIT, dominant Ruby coverage gem | Approved (slopcheck false positive) |
| `mutant` | rubygems.org | ~12 yrs | 1.78M total | github.com/mbj/mutant | [OK] | Verified, Nonstandard license (commercial w/ OSS exemption), active | Approved |
| `mutant-rspec` | rubygems.org | ~12 yrs | 1.67M total | github.com/mbj/mutant | [SLOP — wrong ecosystem] | Verified, same author/license as mutant, version-locked release | Approved (slopcheck false positive) |
| `rake` | rubygems.org | ~20 yrs | bundled | github.com/ruby/rake | [OK] | Verified, MIT, bundled with Ruby | Approved |

**Packages removed due to slopcheck [SLOP] verdict:** none (all PyPI [SLOP] findings are wrong-ecosystem false positives; correct registry is rubygems.org).
**Packages flagged as suspicious [SUS]:** none.
**Postinstall scripts:** N/A (Ruby gems use `extconf.rb`, not npm-style `postinstall`; none of the five gems require native compilation on Ubuntu).

**Note for the planner:** Because slopcheck operated on the wrong registry, treat its verdicts as advisory only for this phase. The authoritative verification is the rubygems.org `/api/v1/gems/<name>.json` cross-check performed during this research (curl evidence captured in research session, 2026-05-26). All five gems passed.

## Architecture Patterns

### System Architecture Diagram

```
                           Local developer machine
                           ┌─────────────────────────┐
                           │  /coverage-is-a-lie/    │
                           │                         │
   git clone               │  LICENSE                │
   ────────────────────────┤  README.md              │
                           │  .ruby-version  ────────┼─► rbenv/asdf/chruby/mise
                           │  Gemfile                │   (local Ruby resolution)
                           │  Gemfile.lock           │
   bundle install          │  .gitignore             │
   ────────────────────────┤  .mutant.yml            ├─► (Phase 3+: mutant reads)
                           │  .github/workflows/     │
                           │     └── ci.yml          │
                           └────────────┬────────────┘
                                        │ git push origin main
                                        ▼
                           ┌─────────────────────────┐
                           │  GitHub: actowery/      │
                           │  coverage-is-a-lie      │  ◄── public repo
                           │  (MIT-licensed)         │
                           └────────────┬────────────┘
                                        │ trigger: push, pull_request
                                        ▼
                           ┌─────────────────────────┐
                           │  GitHub Actions:        │
                           │  ubuntu-latest          │
                           │   1. actions/checkout   │
                           │   2. ruby/setup-ruby@v1 │
                           │      (reads .ruby-version,
                           │       bundler-cache:true)│
                           │   3. (implicit bundle   │
                           │      install via cache) │
                           └─────────────────────────┘
```

**Reader trace (REPO-01 → REPO-05):** local files → `gh repo create` pushes to GitHub → CI on push verifies clean `bundle install` → README quickstart documents the same flow for any cloner.

### Recommended Project Structure (Phase 1 boundary)

```
coverage-is-a-lie/                          (working dir stays mutation-testing-example locally)
├── .github/
│   └── workflows/
│       └── ci.yml                          ← REPO-01 enforcement
├── .gitignore                              ← D-13 contents
├── .mutant.yml                             ← REPO-04 (`usage: opensource`)
├── .ruby-version                           ← REPO-02 (`3.4.9` recommended)
├── Gemfile                                 ← REPO-03 (gems in :development, :test group)
├── Gemfile.lock                            ← committed per D-09
├── LICENSE                                 ← REPO-01 (MIT, Adrian Towery 2026)
└── README.md                               ← REPO-05 (quickstart only)

NOT created by Phase 1:
  lib/      (Phase 2)    spec/     (Phase 2)    tmp/      (Phase 3)
  scripts/  (Phase 4)    .claude/skills/        docs/     (Phase 5)
```

### Pattern 1: Gemfile with grouped dev/test deps

**What:** All five gems are dev-time tooling, never required at library runtime.
**When to use:** Always for this phase — locked by D-08.
**Example:**
```ruby
# Source: bundler.io/v2.6/man/gemfile.5.html (group block syntax)
source "https://rubygems.org"

ruby file: ".ruby-version"

group :development, :test do
  gem "rspec",        "~> 3.13.2"
  gem "simplecov",    "~> 0.22.0"
  gem "mutant",       "~> 0.16.3"
  gem "mutant-rspec", "~> 0.16.3"
  gem "rake"
end
```

**Note on `ruby file: ".ruby-version"`:** This Gemfile directive tells Bundler to read the Ruby version from `.ruby-version` so the pin lives in exactly one place. It's optional — if omitted, Bundler just uses whatever Ruby is active. The CI is unaffected (CI uses `setup-ruby` to resolve the version). Planner discretion: include for tightness, omit for minimalism.

### Pattern 2: GitHub Actions workflow — minimum viable Phase 1 CI

**What:** Single-platform, single-Ruby CI that proves `bundle install` is clean.
**When to use:** Phase 1 only. Phase 2 extends this file to add `bundle exec rspec`.
**Example:**
```yaml
# Source: github.com/ruby/setup-ruby README (verified 2026-05-26)
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  bundle:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: .ruby-version
          bundler-cache: true
```

Notes:
- `ruby-version: .ruby-version` is the official syntax per the setup-ruby README's "Supported Version Syntax" section. (The action also supports `ruby-version-file:` as an alternative; both work. The CONTEXT.md spec called for `ruby-version-file:` but `ruby-version: .ruby-version` is what the README's example uses. Either is correct; pick one.)
- `bundler-cache: true` runs `bundle install` automatically AND caches gems — no separate `run: bundle install` step needed.
- No `permissions:` block is required for a minimal CI that does not write back to the repo. GitHub's default `GITHUB_TOKEN` permissions are sufficient.
- `actions/checkout@v6` is current as of May 2026 (v4 still works; v6 introduced default `actions/checkout@v6` in setup-ruby's own examples).

### Pattern 3: `.mutant.yml` — Phase 1 minimum

**What:** Single-line YAML file declaring OSS license posture.
**Example:**
```yaml
# Source: mutant README + 2019 issue thread (verified usage: key still works in 0.16)
usage: opensource
```
**Phase 3 will expand this file** with `integration: rspec`, `requires:`, `includes:`, etc. Phase 1 leaves it minimal.

### Pattern 4: MIT LICENSE — copyright line

**What:** Standard MIT template with Adrian Towery / Perforce / 2026.
**Source:** opensource.org/licenses/MIT (canonical text). The first line should read:
```
Copyright (c) 2026 Adrian Towery (Perforce)
```
The rest of the body is the unchanged MIT boilerplate. Do not modify the permission/limitation paragraphs — that violates SPDX MIT identification, which mutant's `--usage opensource` mode could in principle key off (though it currently only checks repo visibility per the mutant README).

### Anti-Patterns to Avoid

- **Manually authoring Gemfile.lock.** Always generate it via `bundle install`. Hand-edited lock files cause hash mismatches and Bundler exit code 16 on CI deployment mode.
- **Pinning `ruby/setup-ruby` to a commit SHA.** The action explicitly recommends `@v1` (floating major). Pinned commits go stale and only support Ruby versions known at pin time.
- **Adding `mutant-license` gem or a private gem source.** A 2019 issue (#964) shows users used `gem.mutant.dev` with a token. This is outdated. Current mutant 0.16.x OSS use needs only `--usage opensource` (CLI) or `usage: opensource` (config). Do NOT add a license gem or auth-bearing source.
- **Committing `.bundle/` or `vendor/bundle/`.** These contain machine-local install caches; `.gitignore` must exclude them (D-13).
- **Excluding `Gemfile.lock` from git.** This is an application/demo, not a publishable library. Lock file MUST be committed (D-09). The github/gitignore Ruby.gitignore template comments `Gemfile.lock` out by default; the planner must leave it commented or remove that line entirely.
- **Adding `bundle exec rspec` to CI in Phase 1.** Specs don't exist yet (Phase 2). The CI would fail. CONTEXT.md D-10 explicitly forbids this.
- **Triggering CI on `mutant run`.** Out of scope and would consume mutant license budget unnecessarily. Phase 3 runs mutant locally only.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| MIT license text | Custom worded license | Verbatim opensource.org/licenses/MIT body | SPDX identification + legal clarity; mutant's OSS check may evolve to verify SPDX. |
| Ruby .gitignore | Bespoke ignore patterns | github/gitignore `Ruby.gitignore` template | Battle-tested for ~15 yrs; covers RubyMotion, yard, byebug, bundler, RuboCop. Just remove the `# Gemfile.lock` comment that suggests excluding it for libraries. |
| GitHub repo + remote + first push | `gh api repos POST` then `git remote add` then `git push -u` | `gh repo create <name> --public --source=. --remote=origin --push` | One command does all three. The user is already authenticated as `actowery`. |
| Ruby on CI | Custom `apt install ruby` + manual cache key | `ruby/setup-ruby@v1` with `bundler-cache: true` | 5-second prebuilt downloads; automatic Bundler cache keyed on Gemfile.lock hash. |
| Bundler version pinning on CI | Explicit `bundler:` input | Let `setup-ruby` read `BUNDLED WITH` from Gemfile.lock (default) | Default `bundler: 'Gemfile.lock'` mode keeps local and CI Bundler aligned automatically. |
| Quickstart command list in README | Hand-curated narrative | Numbered list of three lines: `git clone`, `cd`, `bundle install`, plus placeholder lines for future phases | REPO-05 only requires clone → bundle install → demo flow. Phase 5 rewrites the README anyway. |

**Key insight:** Phase 1 is almost entirely composing existing well-known artifacts (MIT LICENSE, github/gitignore Ruby template, the canonical setup-ruby example). The temptation is to "improve" them — resist it. The only artifact that needs project-specific authoring is the README and the Gemfile group block.

## Common Pitfalls

### Pitfall 1: Gemfile.lock / Gemfile drift breaks deployment-mode CI

**What goes wrong:** Developer edits `Gemfile` (adds/changes a gem, updates a pin), commits only `Gemfile`, forgets to re-run `bundle install` and commit the regenerated `Gemfile.lock`. CI fails with Bundler exit 16: "Bundler is configured to use a frozen Gemfile.lock but ..." [VERIFIED: ruby/setup-ruby Issue #292]
**Why it happens:** `bundler-cache: true` automatically runs `bundle config --local deployment true` when `Gemfile.lock` exists. Deployment mode forbids Gemfile/lock drift.
**How to avoid:** Phase 1's PLAN.md must instruct the implementer to run `bundle install` AFTER writing the Gemfile and BEFORE the first commit, so Gemfile and Gemfile.lock land together. The README quickstart should also note `bundle install` regenerates the lock if Gemfile changes.
**Warning signs:** CI log line "You have either added a new gem, modified an existing one, or you are running on a different platform..." → drift detected.

### Pitfall 2: Pinning `.ruby-version` to a patch that isn't available on `ruby/setup-ruby`

**What goes wrong:** Pin to `3.4.10-preview1` or some Ruby version that lacks a prebuilt binary; CI takes 5+ minutes building from source or fails entirely.
**Why it happens:** `setup-ruby` only ships prebuilts for [ruby-builder](https://github.com/ruby/ruby-builder/releases) released versions.
**How to avoid:** Stick to released stable patches. **3.4.9 is confirmed available on Ubuntu via ruby-builder** as of May 2026 (ruby-builder publishes within days of upstream release; 3.4.9 released 2026-03-11, well past the buffer).
**Warning signs:** Workflow log shows "Falling back to source build" or "no prebuilt available for ruby-3.4.x on ubuntu-24.04".

### Pitfall 3: `gh repo create` from a directory with uncommitted changes

**What goes wrong:** `gh repo create --push` fails if the local directory has uncommitted files or no initial commit.
**Why it happens:** `--push` requires HEAD to exist and the working tree to be reasonably clean.
**How to avoid:** Plan tasks in this order: (1) `git init` if not already a repo (this directory IS already a git repo per `.git/` presence — confirmed during research), (2) create all eight files, (3) `git add -A && git commit -m "Phase 1: initial scaffold"`, (4) THEN `gh repo create coverage-is-a-lie --public --source=. --remote=origin --push`.
**Warning signs:** "no commits yet" or "repository is not in a clean state".

### Pitfall 4: System Ruby version is too old to validate locally

**What goes wrong:** Developer runs `bundle install` locally and gets `Ruby version is 2.6.10 but your Gemfile specified ~> 3.4.0` — system Ruby on this machine is 2.6.10.
**Why it happens:** macOS system Ruby is ancient. The project requires Ruby 3.4.9. No rbenv/asdf/chruby/mise is installed on this machine (verified — see Environment Availability). Homebrew has `ruby@3.3` but NOT `ruby@3.4`.
**How to avoid:** Phase 1's PLAN should include a clear prerequisite check: either (a) install a Ruby version manager AND Ruby 3.4.9 before any `bundle install` step, OR (b) document that the human implementer is responsible for arranging Ruby 3.4.9 on PATH before running the bundle step. The recommendation is (b) — installing rbenv + Ruby 3.4.9 is a 5-10 minute environment chore that doesn't belong inside the phase's task graph. Treat it as a `checkpoint:human-verify` precondition.
**Warning signs:** `bundle install` errors out with the Ruby version mismatch message, or `ruby --version` shows 2.6.10 / 3.3.x.

### Pitfall 5: GitHub handle assumed instead of detected

**What goes wrong:** Plan hardcodes a GitHub username that doesn't match the authenticated user; remote URL points to wrong account.
**Why it happens:** Multiple GitHub accounts on one machine; handle never verified before use.
**How to avoid:** Phase 1's PLAN should source the handle from `gh auth status` (NOT `git config user.email`, which is `adrian.towery@perforce.com` — a Perforce email is unrelated to the personal GitHub handle). Research already confirmed: **the active gh-authenticated handle on this machine is `actowery`.** The planner can hardcode this OR keep an explicit "verify handle" step. Hardcoding is safer (eliminates a runtime variable) given research has confirmed it.
**Warning signs:** `gh repo create` succeeds but creates the repo under the wrong account, or the remote URL string `git@github.com:<handle>/coverage-is-a-lie.git` has a placeholder that was never substituted.

### Pitfall 6: `usage: opensource` written with wrong YAML structure

**What goes wrong:** `.mutant.yml` written as `usage:\n  opensource` (a nested key) or as `usage: "opensource"` quoted. Mutant may reject or fall back to commercial-license check.
**Why it happens:** YAML's permissiveness invites variations.
**How to avoid:** Use exactly `usage: opensource` — flat scalar, unquoted. Verified working syntax per mutant docs and 2019 issue discussion.
**Warning signs:** When `bundle exec mutant run` is eventually executed in Phase 3, it errors with "no valid usage configured" or attempts to contact a license server.

## Code Examples

Verified patterns from official/canonical sources:

### LICENSE file body
```
MIT License

Copyright (c) 2026 Adrian Towery (Perforce)

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
Source: [opensource.org/licenses/MIT](https://opensource.org/licenses/MIT) — canonical SPDX MIT.

### `.gitignore` (project-tailored, derived from github/gitignore Ruby.gitignore)
```gitignore
# Source: github.com/github/gitignore/blob/main/Ruby.gitignore (trimmed for demo scope)

# Bundler / gem builds
*.gem
*.rbc
.bundle/
vendor/bundle/

# Test & coverage output (Phases 2-3 generate these)
/coverage/
/spec/reports/
/spec/examples.txt

# Mutant + LLM mutator output (Phase 3-4 generate these)
/tmp/

# OS / editor noise
.DS_Store
.byebug_history

# Documentation cache
/.yardoc/
/_yardoc/
/doc/
/rdoc/

# Note: Gemfile.lock is INTENTIONALLY committed for this project (it is an
# application/demo, not a publishable library). Do not add Gemfile.lock here.
```

### Gemfile
```ruby
# frozen_string_literal: true

source "https://rubygems.org"

# Pin Ruby version (read from .ruby-version for single source of truth)
ruby file: ".ruby-version"

group :development, :test do
  gem "rspec",        "~> 3.13.2"
  gem "simplecov",    "~> 0.22.0"
  gem "mutant",       "~> 0.16.3"
  gem "mutant-rspec", "~> 0.16.3"
  gem "rake"
end
```

### `.mutant.yml`
```yaml
usage: opensource
```

### `.ruby-version`
```
3.4.9
```
*(Single line, no trailing newline issues. Rbenv/asdf/chruby/mise all accept this.)*

### `.github/workflows/ci.yml`
```yaml
name: CI

on:
  push:
    branches: [main]
  pull_request:

jobs:
  bundle:
    name: bundle install
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v6
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: .ruby-version
          bundler-cache: true
```

### README.md (Phase 1 skeleton — Phase 5 will rewrite)
```markdown
# coverage-is-a-lie

A runnable demo showing why 100% code coverage is not the assurance signal it appears to be — and why mutation testing, especially LLM-driven, is the missing layer for AI-era development.

## Quickstart

\`\`\`bash
git clone https://github.com/actowery/coverage-is-a-lie.git
cd coverage-is-a-lie
bundle install
\`\`\`

The full two-act demo (run RSpec → run mutant → run /llm-mutate) lands in later phases. See `.planning/ROADMAP.md` for phase order. Placeholder commands:

\`\`\`bash
# Phase 2+: bundle exec rspec
# Phase 3+: bundle exec mutant run --use rspec --usage opensource
# Phase 4+: /llm-mutate --replay      # Claude Code skill, run inside a Claude Code session
\`\`\`

## License

MIT — see [LICENSE](./LICENSE).
```

### Repo creation command (single shot)
```bash
gh repo create coverage-is-a-lie \
  --public \
  --source=. \
  --remote=origin \
  --push \
  --description "Mutation testing demo — why 100% coverage is a lie"
```
Source: [cli.github.com/manual/gh_repo_create](https://cli.github.com/manual/gh_repo_create).

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `actions/setup-ruby@v1` | `ruby/setup-ruby@v1` | 2020 | actions/setup-ruby was deprecated in favor of ruby/setup-ruby; only use ruby/setup-ruby. |
| Manual `bundle install` + `actions/cache` for gems | `ruby/setup-ruby@v1` with `bundler-cache: true` | 2021+ | Single line replaces ~15 lines of cache config. Default for all new Ruby workflows. |
| mutant w/ private gem source + license key (`gem.mutant.dev`) for OSS | `--usage opensource` CLI flag or `usage: opensource` in `.mutant.yml`, no signup | mutant 0.10+ era | OSS use is now zero-friction; the 2019 license-key flow is obsolete. |
| `Gemfile.lock` excluded for libraries | `Gemfile.lock` committed for applications/demos | Long-standing best practice, reinforced by Bundler 2.x | Applies here: demo is not a publishable library, so commit the lock. |
| `actions/checkout@v3`/`@v4` | `actions/checkout@v6` | 2025-2026 | Use v6 for new workflows; v4 still works but is one major behind. |

**Deprecated/outdated (do NOT use):**
- `actions/setup-ruby@v1` — superseded by `ruby/setup-ruby@v1`.
- Hand-managed bundler caching with `actions/cache` — replaced by `bundler-cache: true`.
- `mutant-license` gem with `gem.mutant.dev` source for OSS use — historical only; current OSS use is config-flag-only.
- `Gemfile.lock` in `.gitignore` for this project — D-09 explicitly commits it.

## Assumptions Log

| # | Claim | Section | Risk if Wrong |
|---|-------|---------|---------------|
| A1 | The active gh-authenticated GitHub handle `actowery` (verified via `gh auth status`) is the correct account to host the demo on. | Pitfall 5, README example | If wrong, repo lands on the wrong account; trivial to delete and recreate. |
| A2 | Ruby 3.4.9 is available as a prebuilt for `ubuntu-latest` via ruby-builder. Based on ruby-builder's normal release cadence (prebuilts ship within ~1 week of upstream release) and 3.4.9's release date (2026-03-11), this is near-certain — but not directly confirmed by visiting ruby-builder/releases. | Standard Stack, Pitfall 2 | If unavailable, CI falls back to source build (slow but functional) or planner pins to 3.4.8. |
| A3 | `.mutant.yml` with single key `usage: opensource` is accepted by mutant 0.16.3 without error. Confirmed via WebSearch but not via running mutant itself (Phase 3 will be the live test). | Pattern 3, Pitfall 6 | If rejected, fallback is to use `--usage opensource` on the CLI in Phase 3 instead. Zero blast radius for Phase 1 — file is just text. |
| A4 | The `ruby file: ".ruby-version"` Bundler directive is honored by Bundler shipped with Ruby 3.4.9. This is long-standing Bundler 2.x behavior. | Pattern 1 | If wrong, Bundler emits a warning, not an error. Trivial to remove the line. |
| A5 | `actions/checkout@v6` is the current major as of May 2026. The setup-ruby README's examples use `@v6`, so this is well-supported. Not independently verified against actions/checkout releases page. | Pattern 2, code examples | If `@v6` doesn't yet exist (unlikely given setup-ruby README uses it), fall back to `@v4`. |

## Open Questions

1. **Should `.ruby-version` be `3.4.9` (latest patch) or `3.4.8` (CLAUDE.md's value)?**
   - What we know: 3.4.9 is the current stable patch (released 2026-03-11); CLAUDE.md was written with Dec 2025 knowledge and pins `3.4.8`. CLAUDE.md explicitly says "latest patch."
   - What's unclear: Whether the planner treats CLAUDE.md's `3.4.8` as a hard pin or as "latest, currently 3.4.8."
   - Recommendation: Update to `3.4.9`. The planner can either treat this as within Claude's discretion (CLAUDE.md authorizes "latest stable") or surface it for sign-off — but 3.4.9 is the right answer.

2. **Should the Gemfile include `ruby file: ".ruby-version"`?**
   - What we know: It's optional and works with Bundler 2.x. CONTEXT.md doesn't mention it.
   - What's unclear: Whether keeping the version in two places (`.ruby-version` AND Gemfile via the directive) adds clarity or just adds maintenance surface.
   - Recommendation: Include it. It is a one-liner, sources from `.ruby-version` so there is no drift risk, and it gives `bundle install` a clearer error if the user has the wrong Ruby active locally. Within Claude's discretion per D-08.

3. **Should `ci.yml` use `ruby-version: .ruby-version` or `ruby-version-file: .ruby-version`?**
   - What we know: CONTEXT.md says `ruby-version-file:`. The setup-ruby README's canonical example uses `ruby-version: .ruby-version`. Both work.
   - What's unclear: Whether `ruby-version-file` is still a documented alias or deprecated.
   - Recommendation: Use `ruby-version: .ruby-version` (matches setup-ruby README's own example, future-proof). This deviates from CONTEXT.md slightly — flag for the planner. Functionally identical.

4. **README quickstart: which placeholder commands are correct for future phases?**
   - What we know: Phases 2/3 run `bundle exec rspec` and `bundle exec mutant run`. Phase 4's `/llm-mutate` is a Claude Code skill, NOT a shell command.
   - What's unclear: Whether to show `/llm-mutate --replay` as a literal command in a fenced block (it isn't a shell command) or annotate it as a Claude Code action.
   - Recommendation: Annotate it explicitly: `/llm-mutate --replay   # invoked inside a Claude Code session`. Prevents a viewer from copy-pasting it into a terminal.

## Environment Availability

| Dependency | Required By | Available | Version | Fallback |
|------------|------------|-----------|---------|----------|
| Git | All file operations + `gh repo create` | ✓ | 2.50.1 (Apple Git-155) | — |
| `gh` CLI | Public repo creation, push | ✓ | 2.89.0 (2026-03-26), authenticated as `actowery` | Manual repo create on github.com web UI |
| Homebrew | Optional — for installing Ruby 3.4.9 if needed | ✓ | `/opt/homebrew` | rbenv/asdf manual install |
| Ruby 3.4.9 (target version) | `bundle install` to generate Gemfile.lock | ✗ | only `/usr/bin/ruby 2.6.10` (system) and `brew ruby@3.3` are installed | Human installs via Homebrew `ruby@3.4` (NOT YET available), rbenv, asdf, chruby, or mise — see below |
| Ruby version manager (rbenv/asdf/chruby/mise) | Pin local Ruby to 3.4.9 | ✗ | none installed | Required for human to install before Phase 1 `bundle install` task runs |
| Bundler 2.x | Generating Gemfile.lock | partial | Bundler 1.17.2 (with system Ruby 2.6) — not the version we want | Auto-installed when Ruby 3.4.9 is provisioned |

**Missing dependencies with no fallback:**
- **Ruby 3.4.9 with a version manager.** This is a hard prerequisite for the `bundle install` task and is NOT something the GSD plan should attempt to install in-band. The planner should either:
  - (a) Add a `checkpoint:human-verify` task at the start of Phase 1 that requires the user to confirm `ruby --version` shows `3.4.9` before any later task runs, OR
  - (b) Document this prerequisite in the phase's PLAN.md preamble and trust the user to have it ready.
  Recommendation: option (a). Five-second checkpoint, prevents an entire phase from failing on a fixable environmental gap.

**Missing dependencies with fallback:**
- None — the only true blocker is local Ruby 3.4.9. CI doesn't care about the local Ruby state.

**Note:** `gh auth status` confirms authentication is already in place; the planner does NOT need a task for `gh auth login`.

## Validation Architecture

### Test Framework
| Property | Value |
|----------|-------|
| Framework | None in Phase 1 — RSpec is declared in Gemfile but no specs exist (Phase 2 creates the first spec). |
| Config file | none — see Wave 0 |
| Quick run command | `bundle install --dry-run` (validates Gemfile/lock without writing anything) |
| Full suite command | `bundle install` (in clean working dir) + CI workflow run on GitHub |
| Phase gate | Repo is public, all eight files committed and pushed, CI workflow runs green on push to main |

### Phase Requirements → Test Map
| Req ID | Behavior | Test Type | Automated Command | File Exists? |
|--------|----------|-----------|-------------------|-------------|
| REPO-01 | Repo public on GitHub w/ LICENSE | smoke | `gh repo view actowery/coverage-is-a-lie --json visibility,licenseInfo \| jq` | ❌ Wave 0 (executed after repo create) |
| REPO-02 | `.ruby-version` pinned to 3.4.x | smoke | `grep -E '^3\.4\.[0-9]+$' .ruby-version` | ❌ Wave 0 |
| REPO-03 | Gemfile pins four gems; `bundle install` clean | smoke | `bundle install --quiet && bundle check` | ❌ Wave 0 |
| REPO-04 | `.mutant.yml` has `usage: opensource` | smoke | `grep -E '^usage:[[:space:]]+opensource$' .mutant.yml` | ❌ Wave 0 |
| REPO-05 | README quickstart shows clone → bundle install → demo placeholder | manual + automated | `grep -E 'git clone' README.md && grep -E 'bundle install' README.md` | ❌ Wave 0 |

### Sampling Rate
- **Per task commit:** N/A — file-creation tasks are individually verified by their own existence checks.
- **Per wave merge:** Run the smoke commands above in order; all five must pass.
- **Phase gate:** `gh repo view actowery/coverage-is-a-lie` succeeds, CI workflow on default branch shows green, and `bundle install` runs clean on a fresh clone.

### Wave 0 Gaps
- [ ] No `.rspec`, `spec_helper.rb`, or any test infrastructure — Phase 2 creates them.
- [ ] No `Rakefile` — optional, can be added when convenient.
- [ ] Phase 1 itself has no automated unit tests; verification is acceptance-criteria-based (the five smoke commands above).

*This is a scaffolding phase. Test infrastructure proper begins in Phase 2.*

## Security Domain

### Applicable ASVS Categories

| ASVS Category | Applies | Standard Control |
|---------------|---------|-----------------|
| V1 Architecture | yes | Phase 1 establishes the project surface; the only architectural concern is repo visibility — locked public per D-05, which is intentional and required by mutant's OSS license. |
| V2 Authentication | partial | `gh` CLI authentication is required for `gh repo create`; already in place (verified via `gh auth status` as `actowery`). No new credentials introduced by Phase 1. |
| V3 Session Management | no | No application sessions in Phase 1. |
| V4 Access Control | no | No application access control; repo is intentionally public. |
| V5 Input Validation | no | No application input handling. |
| V6 Cryptography | no | No cryptographic operations introduced. |
| V14 Configuration | yes | Phase 1's purpose IS configuration. Key controls: pin gem versions (D-08, REPO-03), pin Ruby version (D-14, REPO-02), no secrets in any of the eight files (verified — no env files, no `.env.example`, no credentials touched). |

### Known Threat Patterns for {Ruby + GitHub Actions + public repo}

| Pattern | STRIDE | Standard Mitigation |
|---------|--------|---------------------|
| Dependency confusion / supply-chain attack via slopped gem name | Tampering | All five gems verified directly against rubygems.org during research; pessimistic version pins (`~>`) constrain unexpected major upgrades; Gemfile.lock checksums every transitive dep. |
| Unbounded GitHub Actions write permissions | Elevation of Privilege | Default `GITHUB_TOKEN` permissions are sufficient for read-only CI; no `permissions:` block needed; do NOT grant `contents: write` or `pull-requests: write` for Phase 1's CI. |
| Untrusted third-party action in CI | Tampering | Only two third-party actions used: `actions/checkout@v6` and `ruby/setup-ruby@v1`. Both are GitHub-official org / Ruby-org-official. No randomly-sourced actions introduced. |
| Secrets accidentally committed | Information Disclosure | Phase 1 deliberately includes ZERO secrets. README quickstart does not reference any. `.gitignore` excludes `.env`-style files via the documentation cache patterns; planner should add an explicit `.env*` line if any phase ever introduces env files. |
| Stale dependency exposing unfixed CVE | Tampering | All four pinned gems are at their latest stable releases as of 2026-05-26. Pessimistic pins (`~> 0.16.3`) allow patch upgrades to ship via `bundle update`. |
| Action version pinning to a moveable tag | Tampering | `@v1` and `@v6` are major-version tags maintained by the action publishers. For higher rigor, the planner could pin to commit SHAs — but this directly contradicts ruby/setup-ruby's own guidance to use `@v1`. Recommendation: stay with `@v1` and `@v6`. |

**Phase 1 carries low security risk** — it is configuration only, no application code, no secrets, no user input, no application authentication. The main security discipline is gem provenance, which has been independently verified (see Package Legitimacy Audit).

## Project Constraints (from CLAUDE.md)

CLAUDE.md is authoritative and the planner must comply with these directives:

| Constraint | Source (CLAUDE.md section) | Phase 1 Implication |
|------------|---------------------------|---------------------|
| Ruby 3.4.x (latest patch) | Recommended Stack | Use 3.4.9 (latest as of 2026-05-26); CLAUDE.md's 3.4.8 was Dec 2025 snapshot. |
| RSpec 3.13.2 stable, NOT 4.0.0.beta1 | What NOT to Use | Pin `rspec "~> 3.13.2"`. |
| SimpleCov 0.22.0 | Recommended Stack | Pin `simplecov "~> 0.22.0"`. |
| mutant 0.16.3 + mutant-rspec 0.16.3 (same version) | Version Compatibility | Pin both `~> 0.16.3`. |
| `bundle exec` prefix for all commands | Development Tools | README quickstart must use `bundle exec` for any future-phase commands shown. |
| `.ruby-version` for rbenv/asdf | Development Tools | Phase 1 creates this file. |
| `.tool-versions` (optional, asdf-compat) | Development Tools | Not required by CONTEXT.md; planner discretion. Recommendation: skip — `.ruby-version` is sufficient and asdf reads it. |
| Do NOT use `mutest` gem | What NOT to Use | Already complied — Gemfile uses `mutant`. |
| Do NOT use `alexrudall/ruby-anthropic` or `claude-ruby` | What NOT to Use | Already complied — Phase 1 declares no `anthropic` gem at all (per CONTEXT.md and CLAUDE.md). |
| Do NOT use RSpec 4.0.0.beta1 | What NOT to Use | Already complied — pin is `~> 3.13.2`. |
| Do NOT use Mutahunter or pynguin | What NOT to Use | Out of scope for Phase 1 anyway. |
| Do NOT use SimpleCov pass/fail as CI gate | What NOT to Use | Phase 1 CI doesn't run SimpleCov; complied trivially. |
| Bundler is bundled with Ruby | Recommended Stack | Phase 1 does not declare a Bundler version in Gemfile (left implicit, picked up from Gemfile.lock's `BUNDLED WITH`). |
| Optional RuboCop | Development Tools | NOT required by CONTEXT.md or REPO-01..05. Recommendation: do NOT add in Phase 1 — out of scope for the four-gem locked list. Can be added in a later phase if needed. |

**GSD Workflow Enforcement (CLAUDE.md tail):** All Phase 1 file edits MUST go through a GSD command (`/gsd-execute-phase`). The plan should not include manual file edits outside the GSD flow.

## Sources

### Primary (HIGH confidence)
- [github.com/ruby/setup-ruby](https://github.com/ruby/setup-ruby) — README + action.yml fetched live 2026-05-26; verified `ruby-version: .ruby-version`, `bundler-cache: true`, `actions/checkout@v6` example, deployment-mode behavior with Gemfile.lock
- [rubygems.org/api/v1/gems/rspec.json](https://rubygems.org/api/v1/gems/rspec.json) — version 3.13.2 confirmed (released 2025-10-21), MIT, 981M+ downloads
- [rubygems.org/api/v1/gems/simplecov.json](https://rubygems.org/api/v1/gems/simplecov.json) — version 0.22.0 confirmed (released 2022-12-23), MIT, 469M+ downloads
- [rubygems.org/api/v1/gems/mutant.json](https://rubygems.org/api/v1/gems/mutant.json) — version 0.16.3 confirmed (released 2026-04-30), 1.78M+ downloads, source at github.com/mbj/mutant
- [rubygems.org/api/v1/gems/mutant-rspec.json](https://rubygems.org/api/v1/gems/mutant-rspec.json) — version 0.16.3 confirmed (released 2026-04-30), same author as mutant, same release date
- [ruby-lang.org/en/downloads/releases/](https://www.ruby-lang.org/en/downloads/releases/) — Ruby 3.4.9 released 2026-03-11 confirmed as latest 3.4.x
- [raw.githubusercontent.com/github/gitignore/main/Ruby.gitignore](https://github.com/github/gitignore/blob/main/Ruby.gitignore) — canonical Ruby .gitignore template, fetched verbatim
- [github.com/mbj/mutant](https://github.com/mbj/mutant) — current README confirms `--usage opensource` is the OSS gate
- [cli.github.com/manual/gh_repo_create](https://cli.github.com/manual/gh_repo_create) — `gh repo create --public --source=. --remote=origin --push` syntax
- [opensource.org/licenses/MIT](https://opensource.org/licenses/MIT) — canonical MIT text

### Secondary (MEDIUM confidence)
- [github.com/mbj/mutant/issues/964](https://github.com/mbj/mutant/issues/964) — 2019 OSS license issue; informs the "DO NOT use mutant-license gem" anti-pattern
- [github.com/ruby/setup-ruby/issues/292](https://github.com/ruby/setup-ruby/issues/292) — confirms deployment-mode side effect of `bundler-cache: true` with Gemfile.lock
- Live `gh auth status` on dev machine — confirms `actowery` is the authenticated handle
- Live `git config user.name/user.email` — confirms `Adrian Towery` / `adrian.towery@perforce.com`

### Tertiary (LOW confidence)
- WebSearch result re: `.mutant.yml` accepting `usage:` as a key (paraphrased from a third-party blog) — counter-checked against the 2019 issue and current README, which both reference the same convention; treated as MEDIUM after cross-verification. The only fully-authoritative confirmation would be running mutant in Phase 3 and observing it accept the config.

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — every version verified live on rubygems.org and ruby-lang.org
- Architecture: HIGH — only standard, well-trodden patterns (Gemfile, GitHub Actions, gh repo create)
- Pitfalls: HIGH — six pitfalls all sourced from official docs / known issues
- mutant OSS licensing: MEDIUM-HIGH — current README is unambiguous, but live mutant run in Phase 3 is the ultimate proof
- Environment availability: HIGH — directly probed on the machine
- Security: HIGH — Phase 1 surface is small and well-characterized

**Research date:** 2026-05-26
**Valid until:** 2026-06-25 (30 days for the stable parts; mutant 0.16 / RSpec 3.13 / SimpleCov 0.22 are unlikely to move in that window. If a Ruby 3.4.10 patch ships before phase execution, planner should update `.ruby-version` accordingly.)
