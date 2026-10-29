#!/usr/bin/env bash
# Builds the fixture repo: a GitHub project with its own CLAUDE.md, where
# /setup-matt-pocock-skills never ran (no `## Agent skills`, no docs/agents/).
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/../_fixtures/lib.sh"

init_repo
cp "$here/fixtures/CLAUDE.md" CLAUDE.md
add_github_remote
commit_fixture
