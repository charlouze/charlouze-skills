#!/usr/bin/env bash
# Builds the fixture repo: a GitHub project that followed the superpowers flow
# through supercharlouze, where /setup-matt-pocock-skills then ran. Its
# CLAUDE.md still carries supercharlouze's block and a convention routed to
# superpowers; its settings still enable both flow plugins, one in the shared
# settings and one in the personal ones. `dot-claude/` holds them because a
# common global gitignore drops `.claude/settings.local.json`.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/../_fixtures/lib.sh"

init_repo
add_matt_setup
cp "$fixtures/competing-flow/CLAUDE.md" CLAUDE.md
mkdir -p .claude
cp "$fixtures/competing-flow/dot-claude/"*.json .claude/
add_github_remote
commit_fixture
