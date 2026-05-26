# coverage-is-a-lie

A runnable demo showing why 100% code coverage is not the assurance signal it appears to be — and why mutation testing, especially LLM-driven, is the missing layer for AI-era development.

## Quickstart

```bash
git clone https://github.com/actowery/coverage-is-a-lie.git
cd coverage-is-a-lie
bundle install
```

The full two-act demo (run RSpec → run mutant → run /llm-mutate) lands in later phases. See `.planning/ROADMAP.md` for phase order.

```bash
# Run the test suite with coverage
COVERAGE=1 bundle exec rspec

# Run traditional mutation testing (Act 1)
bundle exec rake mutant

# Run LLM-driven mutation testing (Act 2 — Phase 4+)
# /llm-mutate      ← Claude Code skill, run inside a Claude Code session
```

## Act 1: Traditional Mutation Testing (mutant)

Even with 100% line and branch coverage, traditional operator-based mutation testing reveals that the test suite cannot catch several boundary bugs.

Run mutant and capture the full output to a file:

```bash
bundle exec mutant run --integration rspec DateUtils 2>&1 | tee tmp/mutant-report.txt
```

Or use the convenience Rake task:

```bash
bundle exec rake mutant
```

Results are written to `tmp/mutant-report.txt` (gitignored — run locally to reproduce).

**License note:** This repo is open-source. The `.mutant.yml` includes `usage: opensource` which satisfies the license requirement.

**Expected output shape:**

- Kill rate percentage (e.g. `73/120 = 60.83%`)
- Count of alive (surviving) mutations
- Diffs of each surviving mutant showing exactly what change the test suite failed to catch

The surviving mutants are the demo's payoff — they show that green coverage cannot distinguish a correct implementation from a subtly wrong one.

## License

MIT — see [LICENSE](./LICENSE).
