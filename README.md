# coverage-is-a-lie

A runnable demo showing why 100% code coverage is not the assurance signal it appears to be — and why mutation testing, especially LLM-driven, is the missing layer for AI-era development.

## Quickstart

```bash
git clone https://github.com/actowery/coverage-is-a-lie.git
cd coverage-is-a-lie
bundle install
```

The full two-act demo (run RSpec → run mutant → run /llm-mutate) lands in later phases. See `.planning/ROADMAP.md` for phase order. Placeholder commands:

```bash
# Phase 2+: bundle exec rspec
# Phase 3+: bundle exec mutant run --use rspec --usage opensource
# Phase 4+: /llm-mutate --replay      # Claude Code skill, run inside a Claude Code session
```

## License

MIT — see [LICENSE](./LICENSE).
