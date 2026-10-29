#!/usr/bin/env bash
# Builds the fixture repo: a project already set up for both plugins, with one
# validated brief and no functional spec yet.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/../../_fixtures/lib.sh"

init_repo
mkdir -p docs/source
cp "$here/fixtures/loans-brief.md" docs/source/loans-brief.md
printf '# Tool library\n\n## Agent skills\n\n## charlouze-skills\n\nLanguage of produced documents: English\n' > CLAUDE.md
commit_fixture
