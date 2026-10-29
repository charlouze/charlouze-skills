#!/usr/bin/env bash
# Builds the fixture repo: a GitHub project already prepared by Matt's setup
# and by this one, where the human then changed two values by hand: the
# documents language, and the marketplace's autoUpdate.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/../_fixtures/lib.sh"

init_repo
add_matt_setup
add_charlouze_setup
sed -i 's/^Documents produits : English$/Documents produits : Français/' CLAUDE.md
sed -i 's/"autoUpdate": true/"autoUpdate": false/' .claude/settings.json
grep -q '^Documents produits : Français$' CLAUDE.md
grep -q '"autoUpdate": false' .claude/settings.json
add_github_remote
commit_fixture
