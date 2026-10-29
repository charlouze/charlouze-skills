#!/usr/bin/env bash
# Builds the fixture repo: Matt's setup for a GitHub tracker is in place, but
# the repo has no remote yet.
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/../../_fixtures/lib.sh"

init_repo
add_matt_setup
commit_fixture
