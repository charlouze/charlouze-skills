#!/usr/bin/env bash
# Builds the fixture repo: a project already set up for both plugins, with one
# validated brief and no functional spec yet.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

git init -q -b main
git config user.name fixture
git config user.email fixture@example.invalid

mkdir -p docs/source
cp "$here/fixtures/loans-brief.md" docs/source/loans-brief.md
printf '# Tool library\n\n## Agent skills\n\n## charlouze-skills\n\nDocuments produits : English\n' > CLAUDE.md

git add -A
git commit -qm fixture
