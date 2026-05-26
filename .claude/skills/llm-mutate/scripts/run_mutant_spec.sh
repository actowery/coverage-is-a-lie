#!/usr/bin/env bash
set -euo pipefail

# Ensure mise-managed Ruby/Bundler is available when script is called from a
# shell that does not yet have the mise shims on PATH.
if [[ -d "$HOME/.local/share/mise/shims" ]]; then
  export PATH="$HOME/.local/share/mise/shims:$PATH"
fi

MUTANT_FILE="${1:-}"
ORIG_BACKUP=".claude/skills/llm-mutate/tmp/date_utils.orig.rb"

if [[ -z "$MUTANT_FILE" ]]; then
  echo "Usage: run_mutant_spec.sh <mutant_file>" >&2
  exit 2
fi

if [[ ! -f "$MUTANT_FILE" ]]; then
  echo "Error: mutant file not found: $MUTANT_FILE" >&2
  exit 2
fi

mkdir -p .claude/skills/llm-mutate/tmp

cp lib/date_utils.rb "$ORIG_BACKUP"
trap 'cp "$ORIG_BACKUP" lib/date_utils.rb' EXIT

cp "$MUTANT_FILE" lib/date_utils.rb

set +e
bundle exec rspec spec/date_utils_spec.rb --no-color --format progress > /dev/null 2>&1
RSPEC_EXIT=$?
set -e

# Exit codes: 0 = all passing (mutation survived), 1 = test failure (mutation killed).
# Exit code >= 2 means a load error, Bundler failure, or interpreter crash — surface it so
# the caller does not silently classify the error as a killed mutation.
if [[ $RSPEC_EXIT -ge 2 ]]; then
  echo "ERROR: run_mutant_spec.sh: rspec exited with code $RSPEC_EXIT (not a test failure — possible load error or Bundler crash)" >&2
fi

exit $RSPEC_EXIT
