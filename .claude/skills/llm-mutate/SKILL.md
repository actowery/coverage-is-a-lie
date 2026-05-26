---
name: llm-mutate
description: >
  LLM-driven mutation testing skill for Ruby codebases. Generates semantically
  meaningful mutations in the style of Meta's ACH research ("what a careless developer
  would write"), validates each mutation with ruby -c, runs the RSpec suite to classify
  killed vs survived mutations, and writes tmp/llm-mutation-report.md. Invoke as
  /llm-mutate --replay (deterministic demo mode using committed fixture) or
  /llm-mutate --generate (live generation with MAX_MUTATIONS cap).
disable-model-invocation: false
---

## Overview

LLM-driven mutation testing skill that generates semantically meaningful mutations for `lib/date_utils.rb`, validates each with `ruby -c`, classifies killed vs survived using RSpec, and produces a mutation score report at `tmp/llm-mutation-report.md`. Intended for Ruby developers and tech leadership audiences who want to understand why 100% code coverage is an insufficient quality signal.

## Modes

### `--replay` Mode

See Plan 04-02 — filled in by replay implementation.

### `--generate` Mode

See Plan 04-03 — filled in by generate implementation.

## Pipeline Steps

(Placeholder for shared pipeline logic — filled in by Plans 04-02 and 04-03.)

## Output Format

(Placeholder for report format — filled in by Plans 04-02 and 04-03.)
