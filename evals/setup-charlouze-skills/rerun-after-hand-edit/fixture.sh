#!/usr/bin/env bash
# Builds the fixture repo: a GitHub project already prepared by Matt's setup
# and by this one, where the human then changed three values by hand: the
# documents language, the marketplace's autoUpdate, and a sentence of the
# tagged `## Drift` section.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/../_fixtures/lib.sh"

init_repo
add_matt_setup
add_charlouze_setup
sed -i 's/^Documents produits : English$/Documents produits : Français/' CLAUDE.md
sed -i 's/"autoUpdate": true/"autoUpdate": false/' .claude/settings.json
sed -i 's/"Audit <part> against the functional spec"/"Audit <part> against its functional spec"/' docs/agents/triage-labels.md
grep -q '^Documents produits : Français$' CLAUDE.md
grep -q '"autoUpdate": false' .claude/settings.json
grep -q '"Audit <part> against its functional spec"' docs/agents/triage-labels.md
add_github_remote
commit_fixture
