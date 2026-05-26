---
phase: 1
slug: repo-foundation
status: draft
nyquist_compliant: false
wave_0_complete: false
created: 2026-05-26
---

# Phase 1 — Validation Strategy

> Per-phase validation contract for feedback sampling during execution.

---

## Test Infrastructure

| Property | Value |
|----------|-------|
| **Framework** | None in Phase 1 — RSpec is declared in Gemfile but no specs exist (Phase 2 creates the first spec). |
| **Config file** | none — Wave 0 installs |
| **Quick run command** | `bundle install --quiet && bundle check` |
| **Full suite command** | `bundle install` in clean working dir + CI workflow run on GitHub |
| **Estimated runtime** | ~30s local; ~60s CI |

---

## Sampling Rate

- **After every task commit:** Run task-specific smoke check (e.g., `grep -E '^usage:[[:space:]]+opensource$' .mutant.yml` after `.mutant.yml` creation).
- **After every plan wave:** Run `bundle install --quiet && bundle check` (no-op until Gemfile exists; mandatory after the wave that creates Gemfile/Gemfile.lock).
- **Before `/gsd-verify-work`:** All five REPO-* smoke commands green; `gh repo view actowery/coverage-is-a-lie` succeeds; CI workflow on default branch shows green.
- **Max feedback latency:** 60 seconds local; ~2 minutes for CI round-trip.

---

## Per-Task Verification Map

| Task ID | Plan | Wave | Requirement | Threat Ref | Secure Behavior | Test Type | Automated Command | File Exists | Status |
|---------|------|------|-------------|------------|-----------------|-----------|-------------------|-------------|--------|
| 1-01-01 | 01 | 0 | — | — | Ruby 3.4.9 installed locally (human-verify checkpoint) | manual | `ruby --version \| grep -E '^ruby 3\.4\.[0-9]+'` | N/A | ⬜ pending |
| 1-01-02 | 01 | 1 | REPO-01 (license file) | — | MIT LICENSE present at repo root | smoke | `test -f LICENSE && grep -q 'MIT License' LICENSE` | ❌ W0 | ⬜ pending |
| 1-01-03 | 01 | 1 | REPO-02 | — | `.ruby-version` pinned to 3.4.x | smoke | `grep -E '^3\.4\.[0-9]+$' .ruby-version` | ❌ W0 | ⬜ pending |
| 1-01-04 | 01 | 1 | REPO-03 (Gemfile pins) | T-1-01 (slopped gem) | Gemfile declares four pinned gems | smoke | `grep -E '"(rspec\|simplecov\|mutant\|mutant-rspec)"' Gemfile` | ❌ W0 | ⬜ pending |
| 1-01-05 | 01 | 1 | REPO-04 | — | `.mutant.yml` has `usage: opensource` | smoke | `grep -E '^usage:[[:space:]]+opensource$' .mutant.yml` | ❌ W0 | ⬜ pending |
| 1-01-06 | 01 | 1 | REPO-05 | — | README quickstart present | smoke | `grep -E 'git clone' README.md && grep -E 'bundle install' README.md` | ❌ W0 | ⬜ pending |
| 1-01-07 | 01 | 1 | — | T-1-04 (secrets) | `.gitignore` excludes secrets + Ruby build artifacts | smoke | `grep -E '^\.env' .gitignore && grep -E '^coverage/' .gitignore` | ❌ W0 | ⬜ pending |
| 1-01-08 | 01 | 1 | — | T-1-02, T-1-03 (CI scope, action pinning) | CI workflow uses pinned action major versions | smoke | `grep -E 'ruby/setup-ruby@v1\|actions/checkout@v[0-9]+' .github/workflows/ci.yml` | ❌ W0 | ⬜ pending |
| 1-01-09 | 01 | 2 | REPO-03 | — | `bundle install` clean; Gemfile.lock generated | smoke | `bundle install --quiet && bundle check` | ❌ W0 | ⬜ pending |
| 1-01-10 | 01 | 3 | REPO-01 | — | Public repo created on GitHub | smoke | `gh repo view actowery/coverage-is-a-lie --json visibility,licenseInfo \| jq -e '.visibility == "PUBLIC"'` | ❌ W0 | ⬜ pending |
| 1-01-11 | 01 | 3 | — | — | CI green on first push to default branch | smoke | `gh run list --repo actowery/coverage-is-a-lie --limit 1 --json conclusion \| jq -e '.[0].conclusion == "success"'` | ❌ W0 | ⬜ pending |

*Status: ⬜ pending · ✅ green · ❌ red · ⚠️ flaky*

---

## Wave 0 Requirements

- [ ] Human-verify checkpoint: Ruby 3.4.9 is installed and on PATH locally (RESEARCH §6 — no Ruby 3.4.x currently available on the machine; planner must include this as a `checkpoint:human-verify` task at the start of execution).
- [ ] No `spec/`, `Rakefile`, `.rspec`, or `spec_helper.rb` — Phase 2 creates them.

*This is a scaffolding phase. Test infrastructure proper begins in Phase 2.*

---

## Manual-Only Verifications

| Behavior | Requirement | Why Manual | Test Instructions |
|----------|-------------|------------|-------------------|
| Ruby 3.4.x installed and active on the developer machine | REPO-02 | Cannot be installed by the executor agent — requires user choice of version manager (rbenv / asdf / mise / chruby) and possibly a system password for `brew install`. | Run `ruby --version`; must show `ruby 3.4.x`. If not, install via your preferred Ruby version manager (e.g., `mise install ruby@3.4.9 && mise use ruby@3.4.9`). |
| GitHub remote created and repo is publicly visible | REPO-01 | Requires GitHub-account-scoped `gh` auth and creates a public-internet artifact. Worth a human confirmation before push. | Run `gh repo create coverage-is-a-lie --public --source=. --remote=origin --description "..."`. Then visit `https://github.com/actowery/coverage-is-a-lie` and confirm visibility. |

---

## Validation Sign-Off

- [ ] All tasks have `<automated>` verify or Wave 0 dependencies
- [ ] Sampling continuity: no 3 consecutive tasks without automated verify
- [ ] Wave 0 covers all MISSING references
- [ ] No watch-mode flags
- [ ] Feedback latency < 120s
- [ ] `nyquist_compliant: true` set in frontmatter (planner sets after all rows have automated commands)

**Approval:** pending
