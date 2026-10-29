#!/usr/bin/env bash
# Builds the fixture repo: a GitHub project prepared by Matt's setup and by
# this one, where /setup-matt-pocock-skills then ran again: its templates of
# docs/agents/ and its single-context layout line are back.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/../_fixtures/lib.sh"

init_repo
add_matt_setup
add_charlouze_setup
rerun_matt_setup
grep -q '^Single-context:' CLAUDE.md
grep -q '^## charlouze-skills$' CLAUDE.md
cmp -s docs/agents/domain.md "$fixtures/matt-setup/docs/agents/domain.md"
add_github_remote
commit_fixture
