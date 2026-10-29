#!/usr/bin/env bash
# Builds the fixture repo: a GitHub project where /setup-matt-pocock-skills
# ran, and the charlouze-skills setup never did (no block, no settings file).
set -euo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$here/../_fixtures/lib.sh"

init_repo
add_matt_setup
add_github_remote
commit_fixture
