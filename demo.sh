#!/usr/bin/env bash
# demo.sh — guided walkthrough of the mutation-testing demo.
# Narrative anchored on Meta's ACH paper (FSE 2025): rule-based mutation
# operators are "ill-suited to generating realistic faults" — LLM-driven
# mutation testing closes the gap that operator tools structurally can't see.
#
# Usage:
#   ./demo.sh                     # interactive, paused at each beat
#   AUTO=1 ./demo.sh              # auto-advance every 4s (for rehearsal / smoke test)
#   NO_CLEAR=1 ./demo.sh          # don't clear the terminal between beats (for recording)
#   START_BEAT=5 ./demo.sh        # jump in at beat 5 (skip earlier beats)
#
# Assumes:
#   - You're on `demo/weak-tests` (script will offer to switch)
#   - Ruby 3.4.x via mise (script activates the shims)
#   - baselines/mutant-report.txt and baselines/llm-mutation-report.md exist on demo branches
#
# Safe to ^C at any beat. Final beat returns you to your starting branch.

set -uo pipefail   # NB: not -e — some greps tolerate exit 1 (no match)

# ────────────────────────────────────────────────────────────────────
# Setup
# ────────────────────────────────────────────────────────────────────

export PATH="$HOME/.local/share/mise/shims:$PATH"

RED=$'\033[1;31m'
GREEN=$'\033[1;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[1;34m'
CYAN=$'\033[1;36m'
BOLD=$'\033[1m'
DIM=$'\033[2m'
RESET=$'\033[0m'

AUTO="${AUTO:-}"
NO_CLEAR="${NO_CLEAR:-}"
START_BEAT="${START_BEAT:-0}"

STARTING_BRANCH=$(git branch --show-current 2>/dev/null || echo "")

cleanup() {
  if [[ -n "$STARTING_BRANCH" && "$(git branch --show-current 2>/dev/null)" != "$STARTING_BRANCH" ]]; then
    echo ""
    echo "${DIM}Returning to ${STARTING_BRANCH}...${RESET}"
    git checkout -q "$STARTING_BRANCH" 2>/dev/null || true
  fi
}
trap cleanup EXIT

pause() {
  if [[ -n "$AUTO" ]]; then
    sleep 4
  else
    echo ""
    echo "${DIM}--- press ENTER to continue (or ^C to quit) ---${RESET}"
    read -r _ || exit 0
  fi
}

beat() {
  local num="$1" title="$2"
  if (( num < START_BEAT )); then return 1; fi
  [[ -z "$NO_CLEAR" ]] && clear
  echo ""
  echo "${BOLD}${BLUE}━━━ BEAT ${num}: ${title} ━━━${RESET}"
  echo ""
  return 0
}

say()        { echo "${CYAN}$*${RESET}"; }
highlight()  { echo "${GREEN}${BOLD}$*${RESET}"; }
warn()       { echo "${YELLOW}$*${RESET}"; }
quote()      { echo "${DIM}  \"$*\"${RESET}"; }

# Run a shown command. Prints the prompt first, then executes.
cmd() {
  echo "${YELLOW}\$ $*${RESET}"
  if [[ -z "$AUTO" ]]; then
    read -r _ || exit 0   # one ENTER to see the command, one to run it
  fi
  eval "$@"
  echo ""
}

# ────────────────────────────────────────────────────────────────────
# Preflight
# ────────────────────────────────────────────────────────────────────

if [[ ! -d .git ]]; then
  echo "${RED}ERROR: run this from the repo root.${RESET}"
  exit 1
fi

if [[ "$STARTING_BRANCH" != "demo/weak-tests" ]]; then
  warn "You're on '${STARTING_BRANCH}'. The demo expects 'demo/weak-tests'."
  if [[ -z "$AUTO" ]]; then
    read -p "Switch to demo/weak-tests now? [y/N] " ans
    if [[ "$ans" =~ ^[Yy]$ ]]; then
      git checkout -q demo/weak-tests || { echo "${RED}checkout failed${RESET}"; exit 1; }
    else
      warn "Continuing on ${STARTING_BRANCH} — beats may not work as expected."
    fi
  fi
fi

# ────────────────────────────────────────────────────────────────────
# Cold open
# ────────────────────────────────────────────────────────────────────

if beat 0 "Setup check"; then
  say "Quick sanity check before we open the curtain."
  echo ""
  echo "${DIM}Ruby:${RESET}       $(ruby --version 2>&1 | head -1)"
  echo "${DIM}Bundler:${RESET}    $(bundle --version 2>&1 | head -1)"
  echo "${DIM}Branch:${RESET}     $(git branch --show-current)"
  echo "${DIM}HEAD:${RESET}       $(git rev-parse --short HEAD)"
  pause
fi

# ────────────────────────────────────────────────────────────────────
# Act 1 — Coverage looks great. Mutant looks great. The story isn't done.
# ────────────────────────────────────────────────────────────────────

if beat 1 "The library — six pure-Ruby date utilities"; then
  say "Date math. The kind of utility code every codebase has."
  say "Leap years, business days, age in years, weekday lookups."
  cmd "head -40 lib/date_utils.rb"
  say "Looks ordinary. Branchy. The kind of code that needs tests."
  pause
fi

if beat 2 "The suite — 28 tests, real assertions"; then
  say "Now the spec file. Real expect/eq assertions, no straw-man tells."
  cmd "head -30 spec/date_utils_spec.rb"
  pause
fi

if beat 3 "Run the suite. 100% coverage. Feels great."; then
  say "rspec, then SimpleCov on top."
  cmd "bundle exec rake coverage 2>&1 | tail -25"
  echo ""
  highlight "Line: 100%. Branch: 100%. Zero failures."
  highlight "If this were your CI, you'd merge."
  pause
fi

if beat 4 "Mutant — the traditional operator-based tool"; then
  say "Mutation testing changes the code one operator at a time and re-runs the suite."
  say "If the suite still passes — the mutation 'survived.' The test had no opinion."
  say ""
  say "Running mutant live against all six functions. 14 parallel jobs."
  # Direct invocation, not 'rake mutant' — mutant exits 1 on alive mutations
  # (the whole point), and Rake treats non-zero as task failure.
  cmd "bundle exec mutant run --integration rspec DateUtils 2>&1 | tee /tmp/mutant-live.txt | tail -18 || true"
  echo ""
  highlight "259 mutations. 250 killed. 9 alive. Kill rate: 96.52%."
  say "By traditional mutation testing standards, these tests look strong."
  pause
fi

if beat 5 "But what about the 9 survivors?"; then
  say "Look at one of them — in days_between, mutant dropped the .to_i:"
  echo ""
  cmd "grep -B 2 -A 7 'days_between' baselines/mutant-report.txt | head -14"
  echo ""
  say "Why does this survive? Date subtraction returns a Rational."
  say "(Date.new(2024,1,8) - Date.new(2024,1,1)) is Rational(7,1)."
  say "And in Ruby, Rational(7,1) == 7 is true."
  echo ""
  warn "The mutation changed the return type. It did not change any observable result."
  warn "This is an 'equivalent mutant' — a mutation indistinguishable from"
  warn "the original under all possible inputs."
  echo ""
  say "Meta's ACH paper (FSE 2025), on why operator-based tools fall short:"
  quote "Rule-based mutation operators are ill-suited to the task of"
  quote "generating realistic faults. They produce large volumes of mutants"
  quote "indiscriminately, many semantically equivalent to the original code,"
  quote "overwhelming test infrastructure and developer workflows."
  echo ""
  highlight "96.52% kill rate is real. It's also not what matters."
  highlight "What matters: what kinds of bugs slip through ANY operator-based pass?"
  pause
fi

# ────────────────────────────────────────────────────────────────────
# Act 2 — LLM-driven mutations, Meta-style. The blind spot has a name.
# ────────────────────────────────────────────────────────────────────

if beat 6 "/llm-mutate — Meta's approach, as a Claude Code skill"; then
  say "Custom Claude Code skill at .claude/skills/llm-mutate/."
  say "Generates mutations the way a careless developer (or an AI assistant) writes code:"
  say "off-by-one boundaries, missing edge cases, plausible-but-wrong refactors."
  say ""
  say "This is the same approach Meta's ACH system takes:"
  quote "Fewer, more realistic, and highly specific mutants targeted"
  quote "at particular fault classes."
  say ""
  warn "During recording: type  /llm-mutate --replay  in the Claude Code prompt."
  warn "It writes tmp/llm-mutation-report.md (gitignored). The committed"
  warn "baseline for this branch lives at baselines/llm-mutation-report.md."
  echo ""
  cmd "head -15 baselines/llm-mutation-report.md"
  echo ""
  highlight "20 mutations. 0 killed. 0 equivalent. Score: 0/20 (0%)."
  highlight "96.52% on operator mutations. 0% on semantic ones."
  pause
fi

if beat 7 "The punchline: LM-LY-01 — a bug fix that survives"; then
  say "leap_year? has an intentional bug: missing the 400-year Gregorian exception."
  say "The LLM mutation ADDS the correct exception — i.e., it FIXES the bug."
  echo ""
  cmd "awk '/### LM-LY-01/,/^---$/' baselines/llm-mutation-report.md | head -22"
  echo ""
  say "The mutation is correct code. The original is buggy code. The test suite"
  say "doesn't notice the difference — because no test ever checks year 2000."
  echo ""
  highlight "Coverage was blind. Operator mutation was blind."
  highlight "Semantic LLM mutation surfaces the gap in plain English."
  pause
fi

if beat 8 "The report IS the test backlog"; then
  say "Each surviving mutation tells you in plain English what test is missing."
  say "Reading them is the action item — no triage, no equivalent-mutant filtering."
  echo ""
  cmd "grep -E '^\\| LM-[A-Z]+-[0-9]+' baselines/llm-mutation-report.md | head -10"
  echo ""
  say "Six 'anchor' mutations = six tests to write. That's the bridge to Act 3."
  pause
fi

# ────────────────────────────────────────────────────────────────────
# Act 3 — Six targeted tests later
# ────────────────────────────────────────────────────────────────────

if beat 9 "Switch to demo/fixed-tests"; then
  say "Same library — but with the six boundary tests added and four of five"
  say "intentional bugs fixed."
  cmd "git checkout -q demo/fixed-tests && git branch --show-current"
  echo ""
  say "Six new boundary tests:"
  cmd "git diff demo/weak-tests..demo/fixed-tests -- spec/date_utils_spec.rb | grep -E '^\\+.*it \"' | head"
  pause
fi

if beat 10 "Same suite, same skill. Watch what closes."; then
  say "rspec — 34 examples now (28 original + 6 targeted boundary tests)."
  cmd "bundle exec rspec 2>&1 | tail -5"
  echo ""
  say "Mutant kill rate on the fixed branch:"
  cmd "grep -E '^(Mutations|Kills|Alive|Coverage):' baselines/mutant-report.txt | tail -8"
  echo ""
  say "94.42% — basically unchanged from 96.52% on the weak branch."
  say "Operator mutations were already mostly caught. Adding boundary tests"
  say "barely moves that needle. That's the wrong needle."
  echo ""
  say "The right needle — semantic mutations the boundary tests target:"
  cmd "head -15 baselines/llm-mutation-report.md"
  echo ""
  highlight "13 LLM-style semantic mutations on this branch. 13 killed. 100%."
  highlight "Six tests, targeted at the right gaps, closed the right holes."
  pause
fi

# ────────────────────────────────────────────────────────────────────
# Close
# ────────────────────────────────────────────────────────────────────

if beat 11 "Close — what Meta already shipped"; then
  echo ""
  highlight "100% coverage is a lie."
  highlight "96.52% operator-mutation kill rate is a different lie."
  echo ""
  say "Meta has already shipped this story at industrial scale."
  say "ACH (Automated Compliance Hardening), Engineering at Meta, Sep 2025:"
  quote "Applied to 10,795 Android Kotlin classes across 7 platforms."
  quote "Generated 9,095 LLM-driven mutants and 571 hardening tests."
  quote "73% of generated tests accepted by engineers, 36% privacy-relevant."
  echo ""
  highlight "Operator mutation belongs to the 1990s — large volumes, generic faults,"
  highlight "10-15% equivalent. LLM mutation is the AI-era assurance layer:"
  highlight "fewer, realistic, targetable, and reviewable in plain English."
  echo ""
  echo "${BOLD}Repo:${RESET}      ${CYAN}github.com/actowery/coverage-is-a-lie${RESET}"
  echo "${BOLD}ACH paper:${RESET} arXiv 2501.12862 (FSE 2025)"
  echo "${BOLD}Meta blog:${RESET} engineering.fb.com/2025/09/30/security/llms-are-the-key-to-mutation-testing"
  echo ""
  pause
fi

echo ""
echo "${BOLD}${GREEN}━━━ DEMO COMPLETE ━━━${RESET}"
echo ""
