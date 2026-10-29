#!/usr/bin/env bash
# Builds the fixture repo: a GitHub project already prepared by Matt's setup
# and by this one, its settings since rewritten by `claude plugin install`.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/../../_fixtures/lib.sh"

init_repo
add_matt_setup
add_charlouze_setup
add_github_remote
commit_fixture
