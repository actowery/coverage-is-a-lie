#!/usr/bin/env bash
set -euo pipefail

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

bundle exec rspec spec/date_utils_spec.rb --no-color --format progress > /dev/null 2>&1
RSPEC_EXIT=$?

exit $RSPEC_EXIT
