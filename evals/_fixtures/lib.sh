# Shared by the fixture.sh of every eval case: sourced, not run.
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
# count. Its docs/agents/ files are Matt's with the sections and the layout of
# skills/setup-charlouze-skills/matt-files.md applied.
add_charlouze_setup() {
  cp -R "$fixtures/charlouze-setup/." .
}

# What a later rerun of /setup-matt-pocock-skills leaves: its templates of
# docs/agents/ written again, and its single-context `### Domain docs` line
# back in the `## Agent skills` block it updates in place. The rest of
# CLAUDE.md, the `## charlouze-skills` block included, holds.
rerun_matt_setup() {
  cp -R "$fixtures/matt-setup/docs/." docs/
  local line
  line="$(sed -n '/^### Domain docs$/{n;n;p;}' "$fixtures/matt-setup/CLAUDE.md")"
  sed -i "/^### Domain docs\$/{n;n;s|.*|$line|;}" CLAUDE.md
}

add_github_remote() {
  git remote add origin https://github.com/charlouze/tool-library.git
}

commit_fixture() {
  git add -A
  git commit -qm fixture
}
