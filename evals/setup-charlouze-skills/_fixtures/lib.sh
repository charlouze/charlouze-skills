# Shared by the fixture.sh of every setup-charlouze-skills case: sourced, not run.
# Each function builds one layer of the fixture repo in the current directory.

fixtures="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

init_repo() {
  git init -q -b main
  git config user.name fixture
  git config user.email fixture@example.invalid
}

# What /setup-matt-pocock-skills leaves: the `## Agent skills` block in
# CLAUDE.md and the three files of docs/agents/, for a GitHub tracker.
add_matt_setup() {
  cp -R "$fixtures/matt-setup/." .
}

# What setup-charlouze-skills leaves on top of Matt's setup, with
# .claude/settings.json formatted the way `claude plugin install --scope
# project` rewrites it (other indentation, other key order): only the values
# count.
add_charlouze_setup() {
  cp -R "$fixtures/charlouze-setup/." .
}

add_github_remote() {
  git remote add origin https://github.com/charlouze/tool-library.git
}

commit_fixture() {
  git add -A
  git commit -qm fixture
}
