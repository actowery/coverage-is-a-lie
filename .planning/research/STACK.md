# Stack Research

**Domain:** Ruby mutation-testing demo library with LLM-driven mutator as a Claude Code skill
**Researched:** 2026-05-26
**Confidence:** HIGH (all core choices verified against rubygems.org, official Anthropic docs, and official mutant repo; LLM skill conventions verified against code.claude.com)

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| Ruby | 3.4.x (latest patch) | Runtime for the demo library, test suite, and mutator script | Ruby 3.4 is the current stable branch (3.4.8 as of Dec 2025, 3.4.9 expected Feb 2026). The mutant gem switched to the Prism parser on 3.4, which measurably speeds up mutant boot on larger codebases. `mutant` requires >= 3.3; 3.4 is the safe forward-looking pin. |
| RSpec | 3.13.2 | Test framework for the demo library | Stable release (Oct 2025). RSpec 4.0.0.beta1 dropped Feb 2026 but is a beta — do not use for a demo that must run cleanly from `git clone`. `mutant-rspec` 0.16.3 depends on `rspec-core >= 3.8.0, < 5.0.0`, so 3.13.x is the sweet spot. RSpec's `expect` / `be_within` / `eq` matchers surface weak assertions most visibly in a demo context. |
| SimpleCov | 0.22.0 | Line/branch coverage reporting | Last release Dec 2022 but still the uncontested standard; no newer alternative has emerged. Supports branch coverage via `SimpleCov.start { enable_coverage :branch }`. The demo's "100% line coverage but weak tests" narrative depends on SimpleCov producing a green badge while mutations survive. |
| mutant | 0.16.3 | Traditional operator-based mutation testing (baseline) | Latest release Apr 2026. Actively maintained (4,272 commits, regular releases through 2025-2026). The only production-grade mutation framework for Ruby. Used in IEEE-published research and included in Trail of Bits Ruby Security Field Guide. Commercial license required for non-OSS — use `--usage opensource` for the demo repo if kept public, or purchase a per-developer license. |
| mutant-rspec | 0.16.3 | RSpec integration for mutant | Always released in lockstep with `mutant`. Provides `--integration rspec` / `--use rspec` flag. Requires `mutant = 0.16.3` and `rspec-core >= 3.8.0, < 5.0.0`. |
| anthropic (gem) | ~> 1.43.0 | Official Anthropic Ruby SDK for the LLM mutator script | v1.43.0 released May 2026. Officially maintained by Anthropic at `anthropics/anthropic-sdk-ruby`. Requires Ruby >= 3.2.0. Provides `Anthropic::Client`, streaming helpers, typed request/response objects, automatic retries, and `cache_control` support for prompt caching. Supersedes community gems (`alexrudall/ruby-anthropic`, `obie/anthropic`) — do not use those. |
| Bundler | Bundled with Ruby 3.4 | Dependency management and gemspec packaging | Standard Ruby dependency manager, bundled since Ruby 2.6. The demo uses a `.gemspec` for the library and a `Gemfile` that calls `gemspec` to pull in runtime deps, with `group :development, :test` for tooling. |

### Supporting Libraries

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| rspec-expectations | 3.13.x (pulled transitively) | Rich assertion DSL | Always — included with rspec gem. Use `expect(x).to eq(y)`, `be_within(n).of(v)`, `be_truthy`, etc. to demonstrate how a weak test can pass without actually asserting the right thing. |
| rspec-mocks | 3.13.x (pulled transitively) | Test doubles and stubs | Needed if the date utility calls external time sources (e.g. `Time.now`) — use `allow(Time).to receive(:now).and_return(...)` to pin time in specs. |
| simplecov-html | Pulled transitively | HTML coverage report | Provides the green dashboard screenshot for the demo narrative. No separate pin needed. |
| rake | Bundled with Ruby | Task runner | For `rake spec`, `rake mutant`, `rake demo` convenience targets. Useful in the recording-ready script so one-liner commands are memorable. No explicit pin needed — use whatever ships with Ruby 3.4. |

### Development Tools

| Tool | Purpose | Notes |
|------|---------|-------|
| `.ruby-version` | Pin Ruby version for rbenv/rvm | File containing `3.4.x` (e.g. `3.4.8`). Ensures `git clone` reproducibility. |
| `.tool-versions` (optional) | asdf version pin | If the team uses asdf: `ruby 3.4.8`. Include alongside `.ruby-version` for dual compatibility. |
| RuboCop | Style linting | Optional but recommended for a demo repo — keeps the library code readable for a video walkthrough. Pin as a dev dependency; do not gate `mutant` on it. |
| `bundle exec` prefix | Isolation | All commands (`rspec`, `mutant`, custom mutator) should be run via `bundle exec` to prevent gem version conflicts. |

---

## Installation

```ruby
# [library_name].gemspec
Gem::Specification.new do |spec|
  spec.name          = "date_utils"
  spec.version       = "0.1.0"
  spec.required_ruby_version = ">= 3.3"
  spec.summary       = "Date/time utility library for mutation testing demo"
  spec.files         = Dir["lib/**/*.rb"]
  spec.require_paths = ["lib"]
end
```

```ruby
# Gemfile
source "https://rubygems.org"

gemspec

group :development, :test do
  gem "rspec",        "~> 3.13"
  gem "simplecov",    "~> 0.22"
  gem "mutant",       "~> 0.16"
  gem "mutant-rspec", "~> 0.16"
  gem "anthropic",    "~> 1.43"
end
```

```bash
bundle install

# Run the test suite
bundle exec rspec

# Run traditional mutation testing (requires license flag for public/OSS use)
bundle exec mutant run --use rspec --usage opensource -- 'DateUtils*'

# Run LLM-driven mutator skill (from within Claude Code)
# /llm-mutate                        ← skill invocation
```

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| Ruby 3.4 | Ruby 3.3 | If the host environment cannot be updated — 3.3 is still supported until March 2027 and mutant >= 0.16 supports it. Minor tradeoff: slightly slower mutant boot (uses whitequark parser instead of Prism). |
| RSpec 3.13 | Minitest | Never for this demo — the narrative depends on RSpec's expressive `expect` DSL to make weak assertions look plausible at a glance. `mutant-minitest` exists but the story is weaker. |
| mutant 0.16 | rubycritic, mutation_testing (other gems) | Never — `mutant` is the only production-grade Ruby mutation tool. `rubycritic` is a static analyzer, not a mutation tester. |
| `anthropic` gem (official) | `alexrudall/ruby-anthropic` | Only if targeting a locked-down environment where the official gem is unavailable. The community gem has different API surface and Anthropic recommends migrating away from it. |
| Claude Sonnet 4.6 (`claude-sonnet-4-6`) | Claude Haiku 4.5 | If cost is a hard constraint — Haiku is $1/MTok input vs $3/MTok. Mutation quality will be lower; semantically meaningful mutations are harder with a smaller model. |
| Claude Sonnet 4.6 | Claude Opus 4.7 | If demo showcases the highest-quality mutations and cost is secondary — Opus 4.7 is $5/MTok input. Not the default for a demo environment. |
| Claude Code skill (`.claude/skills/`) | Standalone Ruby CLI script | If the team does not use Claude Code — the mutation logic is a Ruby script that can be invoked directly. Packaging as a skill gives the "reusable across repos" leverage the project explicitly wants. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| `mutest` gem | Not a real gem name — do not confuse with `mutant`. Does not exist as a standalone mutation tool. | `mutant` |
| `alexrudall/ruby-anthropic` (community gem `anthropic`) | Deprecated for direct API use; Anthropic's official SDK supersedes it and has a different, typed API surface. The community gem is not maintained at the same cadence. | Official `anthropic` gem (`anthropics/anthropic-sdk-ruby`) |
| `claude-ruby` (webventures/claude-ruby) | Explicitly deprecated by the maintainer; Anthropic recommends migrating to the official SDK. | Official `anthropic` gem |
| RSpec 4.0.0.beta1 | Beta release as of Feb 2026 — API surface may change; `mutant-rspec` 0.16.3 pins `rspec-core < 5.0.0` which admits it, but the beta status makes demo breakage a real risk. | RSpec 3.13.2 (stable) |
| Mutahunter | Python tool (requires Python 3.11+), not a Ruby gem. Adding a Python dependency to a Ruby demo muddies the setup story. Language-agnostic via coverage report piping, but the integration overhead is not worth it for a single-language demo. Also: project last meaningfully updated April 2025, smaller community than `mutant`. | Custom Claude Code skill (same LLM-driven approach, pure Ruby/skill invocation, no Python dep) |
| pynguin | Python-only test generator (not a mutation tool). Wrong language, wrong problem domain. | The custom skill for generation; `mutant` for mutation. |
| SimpleCov coverage as the quality signal | The entire demo exists to argue SimpleCov is an insufficient signal. Never use SimpleCov pass/fail as a CI gate in the demo artifacts — that would undermine the thesis. | Use SimpleCov only to show the green dashboard, then show mutations surviving despite it. |

---

## Skill Packaging Conventions

The LLM-driven mutator is packaged as a Claude Code skill. This is the current canonical extension mechanism since `.claude/commands/*.md` and `.claude/skills/*/SKILL.md` were merged — both create the same `/slash-command` interface.

### File Layout

```
.claude/
  skills/
    llm-mutate/
      SKILL.md          ← entry point: frontmatter + instructions
      mutator.rb        ← Ruby script: loads library file, calls Anthropic API, writes mutant, runs rspec
      prompts/
        system.md       ← static system prompt (cache this)
        mutation.md.erb ← per-mutation prompt template
      output/           ← generated mutant files dropped here (gitignored)
```

### SKILL.md Frontmatter Fields

```yaml
---
name: llm-mutate
description: >
  Run LLM-driven mutation testing on the date_utils library using Claude Sonnet 4.6.
  Generates semantically meaningful mutations inspired by Meta's ACH research,
  runs the RSpec suite against each mutant, and reports survivors.
disable-model-invocation: false
---
```

- `name`: lowercase, hyphens only, max 64 chars. Becomes the `/llm-mutate` invocation.
- `description`: The LLM reads this to decide when to invoke the skill automatically. Keep it precise about what this skill does and when it applies.
- `disable-model-invocation: false` (default): Claude can invoke the skill autonomously when context suggests mutation testing. Set to `true` for side-effectful workflows where you always want explicit `/` invocation.

### Invocation Surface

- Explicit: `/llm-mutate` typed in the Claude Code chat
- Automatic: Claude loads the skill when the conversation context mentions mutation testing for this codebase
- The skill body instructs Claude to run `bundle exec ruby .claude/skills/llm-mutate/mutator.rb` with appropriate arguments

### Model Choice in the Script

```ruby
# .claude/skills/llm-mutate/mutator.rb
require "anthropic"

MODEL = ENV.fetch("MUTANT_LLM_MODEL", "claude-sonnet-4-6")
MAX_TOKENS = 4096

client = Anthropic::Client.new  # reads ANTHROPIC_API_KEY from env

# Prompt caching: system prompt is static across all mutation calls
# → mark it with cache_control to hit the 1-hour TTL for agentic runs
response = client.messages.create(
  model: MODEL,
  max_tokens: MAX_TOKENS,
  system: [
    {
      type: "text",
      text: File.read(File.join(__dir__, "prompts/system.md")),
      cache_control: { type: "ephemeral", ttl: "1h" }
    }
  ],
  messages: [{ role: "user", content: mutation_prompt }]
)
```

**Why 1-hour cache TTL:** The skill runs N mutations in one session; each call has the same large system prompt. The 5-minute default TTL would expire between mutations if the session takes longer than 5 minutes on a larger library. The 1-hour TTL trades a 2x cache-write cost for reliable cache hits across all mutations in one run. With the system prompt well over 1,024 tokens (Sonnet's minimum for caching), cache reads cost 0.1x of base input — a significant saving at scale.

**Model string:** `"claude-sonnet-4-6"` — dateless format, confirmed pinned snapshot per Anthropic's versioning docs. Price: $3/MTok input, $15/MTok output. Extended thinking available. 1M token context window.

---

## LLM Mutation Prior Art Survey

### Meta's ACH (Automated Compliance Hardening)

**Paper:** "Mutation-Guided LLM-based Test Generation at Meta" (arXiv 2501.12862, FSE 2025 Industry Track)
**Blog:** engineering.fb.com/2025/09/30/security/llms-are-the-key-to-mutation-testing-and-better-compliance/ (Sep 2025)

Key design decisions relevant to our skill:
- Meta generates *fewer, targeted* mutants rather than exhaustive operator-based ones. Their trial produced 9,095 mutants from 10,795 Kotlin classes — roughly 1 mutant per class.
- Mutants are generated to simulate domain-specific faults (privacy violations in their case), not generic operator mutations. For the demo, the equivalent is date/time semantic faults: off-by-one on DST transition, wrong leap-year condition, incorrect sign for negative duration.
- LLM-based equivalent-mutant detection (precision 0.79, recall 0.47) is used to filter useless mutants before running tests. For the demo, we can skip this step — surviving mutants are the demo's payoff, not a signal to filter.
- 73% of generated tests were accepted by engineers; 36% judged privacy-relevant — strong argument for LLM-driven quality over volume.

**Implementation implication for the skill:** Prompt the model with the source file + a description of the semantic domain (date arithmetic edge cases) and ask for mutations that look like realistic developer mistakes, not syntactic perturbations. This mirrors what makes Meta's approach more powerful than `mutant`'s operator set.

### Mutahunter

**Repo:** github.com/codeintegrity-ai/mutahunter
**Status as of research date:** 286 stars, last updated April 2025. Python 3.11+ required. Language-agnostic via coverage report (Cobertura/LCOV).

**Why we don't use it:** Python dependency in a Ruby demo is a setup burden. The skill approach does the same thing (LLM-driven, context-aware mutations) without adding a cross-language dependency. Mutahunter is a good reference for prompt design but not a runtime dep.

### Other LLM Mutation Tools

No Ruby-native LLM mutation tool exists beyond the custom skill approach. The field is nascent; `mutant` + custom Claude skill is the de facto SOTA for Ruby as of May 2026.

---

## Version Compatibility

| Package | Requires | Notes |
|---------|----------|-------|
| `mutant` 0.16.3 | Ruby >= 3.3 | Uses Prism parser on Ruby 3.4 (faster), whitequark parser on 3.3 |
| `mutant-rspec` 0.16.3 | `mutant` = 0.16.3, `rspec-core` >= 3.8.0, < 5.0.0 | Must be exactly the same version as `mutant` |
| `anthropic` ~> 1.43.0 | Ruby >= 3.2.0 | Safe on 3.3 and 3.4 |
| `simplecov` 0.22.0 | Ruby >= 2.5 | Branch coverage requires CRuby >= 2.5; no issues on 3.4 |
| `rspec` 3.13.2 | Ruby >= 2.3 | No issues on 3.4; compatible with `mutant-rspec` 0.16.3 |
| Ruby 3.4 + RSpec 4.0.0.beta1 | N/A | Do NOT combine — beta RSpec with mutant-rspec 0.16.3 is untested |

---

## Sources

- [mutant on RubyGems.org](https://rubygems.org/gems/mutant) — version 0.16.3 confirmed, released Apr 2026
- [mbj/mutant GitHub](https://github.com/mbj/mutant) — Ruby 3.2-4.0 support matrix, Prism parser on 3.4, RSpec integration docs
- [mutant-rspec on RubyGems.org](https://rubygems.org/gems/mutant-rspec) — version 0.16.3, Ruby >= 3.3, rspec-core < 5.0.0
- [Ruby releases page](https://www.ruby-lang.org/en/downloads/releases/) — Ruby 3.4.8 as latest stable patch
- [rspec on RubyGems.org](https://rubygems.org/gems/rspec) — 3.13.2 latest stable (Oct 2025); 4.0.0.beta1 noted but not recommended
- [simplecov on RubyGems.org](https://rubygems.org/gems/simplecov) — 0.22.0 latest, Dec 2022, still the standard
- [anthropics/anthropic-sdk-ruby GitHub](https://github.com/anthropics/anthropic-sdk-ruby) — v1.43.0, May 2026; requires Ruby >= 3.2.0
- [Anthropic Ruby SDK docs](https://platform.claude.com/docs/en/api/sdks/ruby) — gem name `anthropic`, streaming, tool use, Sorbet types
- [Anthropic Models overview](https://platform.claude.com/docs/en/about-claude/models/overview) — `claude-sonnet-4-6` confirmed as current API ID, $3/$15 MTok, 1M context
- [Anthropic Prompt Caching docs](https://platform.claude.com/docs/en/build-with-claude/prompt-caching) — cache_control syntax, 1-hour TTL, minimum token thresholds, Ruby SDK examples
- [Claude Code Skills docs](https://code.claude.com/docs/en/skills) — SKILL.md frontmatter format, commands/skills merge, invocation patterns
- [Meta ACH paper arXiv 2501.12862](https://arxiv.org/abs/2501.12862) — Mutation-Guided LLM-based Test Generation at Meta
- [Meta Engineering blog Sep 2025](https://engineering.fb.com/2025/09/30/security/llms-are-the-key-to-mutation-testing-and-better-compliance/) — ACH trial results, 73% test acceptance rate
- [Mutahunter GitHub](https://github.com/codeintegrity-ai/mutahunter) — Python LLM mutation tool, 286 stars, last updated Apr 2025

---
*Stack research for: Ruby mutation-testing demo with LLM-driven mutator as Claude Code skill*
*Researched: 2026-05-26*
